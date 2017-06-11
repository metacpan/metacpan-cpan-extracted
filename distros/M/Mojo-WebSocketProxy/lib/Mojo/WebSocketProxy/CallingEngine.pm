package Mojo::WebSocketProxy::CallingEngine;

use strict;
use warnings;

use MojoX::JSON::RPC::Client;
use Guard;
use JSON;

our $VERSION = '0.06';    ## VERSION

sub make_call_params {
    my ($c, $req_storage) = @_;

    my $args         = $req_storage->{args};
    my $stash_params = $req_storage->{stash_params};

    my $call_params = $req_storage->{call_params};
    $call_params->{args} = $args;

    if (defined $stash_params) {
        $call_params->{$_} = $c->stash($_) for @$stash_params;
    }

    return $call_params;
}

sub get_rpc_response_cb {
    my ($c, $req_storage) = @_;

    my $success_handler = delete $req_storage->{success};
    my $error_handler   = delete $req_storage->{error};

    if (my $rpc_response_cb = delete $req_storage->{rpc_response_cb}) {
        return sub {
            my $rpc_response = shift;
            return $rpc_response_cb->($c, $rpc_response, $req_storage);
        };
    } else {
        return sub {
            my $rpc_response = shift;
            if (ref($rpc_response) eq 'HASH' and exists $rpc_response->{error}) {
                $error_handler->($c, $rpc_response, $req_storage) if defined $error_handler;
                return error_api_response($c, $rpc_response, $req_storage);
            } else {
                $success_handler->($c, $rpc_response, $req_storage) if defined $success_handler;
                store_response($c, $rpc_response);
                return success_api_response($c, $rpc_response, $req_storage);
            }
            return;
        };
    }
    return;
}

sub store_response {
    my ($c, $rpc_response) = @_;

    if (ref($rpc_response) eq 'HASH' && $rpc_response->{stash}) {
        $c->stash(%{delete $rpc_response->{stash}});
    }
    return;
}

sub success_api_response {
    my ($c, $rpc_response, $req_storage) = @_;

    my $msg_type             = $req_storage->{msg_type};
    my $rpc_response_handler = $req_storage->{response};

    my $api_response = {
        msg_type  => $msg_type,
        $msg_type => $rpc_response,
    };

    if (ref($rpc_response) eq 'HASH' and keys %$rpc_response == 1 and exists $rpc_response->{status}) {
        $api_response->{$msg_type} = $rpc_response->{status};
    }

    if ($rpc_response_handler) {
        return $rpc_response_handler->($rpc_response, $api_response, $req_storage);
    }

    return $api_response;
}

sub error_api_response {
    my ($c, $rpc_response, $req_storage) = @_;

    my $msg_type             = $req_storage->{msg_type};
    my $rpc_response_handler = $req_storage->{response};
    my $api_response =
        $c->wsp_error($msg_type, $rpc_response->{error}->{code}, $rpc_response->{error}->{message_to_client}, $rpc_response->{error}->{details});

    if ($rpc_response_handler) {
        return $rpc_response_handler->($rpc_response, $api_response, $req_storage);
    }

    return $api_response;
}

my $request_number = 0;

sub call_rpc {
    my $c           = shift;
    my $req_storage = shift;

    my $method   = $req_storage->{method};
    my $msg_type = $req_storage->{msg_type} ||= $req_storage->{method};
    my $url      = ($req_storage->{url} . $req_storage->{method});

    $req_storage->{call_params} ||= {};

    my $rpc_response_cb = get_rpc_response_cb($c, $req_storage);

    my $before_get_rpc_response_hook = delete($req_storage->{before_get_rpc_response}) || [];
    my $after_got_rpc_response_hook  = delete($req_storage->{after_got_rpc_response})  || [];
    my $before_call_hook             = delete($req_storage->{before_call})             || [];

    my $client  = MojoX::JSON::RPC::Client->new;
    my $callobj = {
        # enough for short-term uniqueness
        id => join('_', $$, $request_number++, time, (0 + [])),
        method => $method,
        params => make_call_params($c, $req_storage),
    };

    $_->($c, $req_storage) for @$before_call_hook;

    $client->call(
        $url, $callobj,
        sub {
            my $res = pop;

            $_->($c, $req_storage) for @$before_get_rpc_response_hook;

            # unconditionally stop any further processing if client is already disconnected
            return unless $c->tx;

            my $mem_guard = guard {
                undef $client;
                undef $req_storage;
            };

            my $api_response;
            if (!$res) {
                warn "WrongResponse [$msg_type]";
                $api_response = $c->wsp_error($msg_type, 'WrongResponse', 'Sorry, an error occurred while processing your request.');
                $c->send({json => $api_response}, $req_storage);
                return;
            }

            $_->($c, $req_storage, $res) for @$after_got_rpc_response_hook;

            if ($res->is_error) {
                warn $res->error_message;
                $api_response = $c->wsp_error($msg_type, 'CallError', 'Sorry, an error occurred while processing your request.');
                $c->send({json => $api_response}, $req_storage);
                return;
            }

            $api_response = &$rpc_response_cb($res->result);

            return unless $api_response;

            $c->send({json => $api_response}, $req_storage);

            return;
        });
    return;
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::CallingEngine

=head1 DESCRIPTION

The calling engine which does the actual RPC call.

=head1 METHODS

=head2 forward

Forward the call to RPC service and return response to websocket connection.

Call params is made in make_call_params method.
Response is made in success_api_response method.
These methods would be override or extend custom functionality.

=head2 make_call_params

Make RPC call params.

Method params:
    stash_params - it contains params to forward from server storage.

=head2 rpc_response_cb

Callback for RPC service response.
Can use custom handlers error and success.

=head2 store_response

Save RPC response to storage.

=head2 success_api_response

Make wsapi proxy server response from RPC response.

=head2 error_api_response

Make wsapi proxy server response from RPC response.

=head2 call_rpc

Make RPC call.

=head2 get_rpc_response_cb

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::CallingEngine>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
