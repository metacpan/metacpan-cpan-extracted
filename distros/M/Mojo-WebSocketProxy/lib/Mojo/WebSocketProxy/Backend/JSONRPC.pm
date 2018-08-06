package Mojo::WebSocketProxy::Backend::JSONRPC;

use strict;
use warnings;

use parent qw(Mojo::WebSocketProxy::Backend);

use feature qw(state);

no indirect;

use curry;

use MojoX::JSON::RPC::Client;

our $VERSION = '0.09';    ## VERSION

__PACKAGE__->register_type('jsonrpc');

sub url { return shift->{url} }

my $request_number = 0;

sub call_rpc {
    my ($self, $c, $req_storage) = @_;
    state $client = MojoX::JSON::RPC::Client->new;

    my $url = $req_storage->{url} // $self->url;
    die 'No url found' unless $url;

    $url .= $req_storage->{method};

    my $method = $req_storage->{method};
    my $msg_type = $req_storage->{msg_type} ||= $req_storage->{method};

    $req_storage->{call_params} ||= {};

    my $rpc_response_cb = $self->get_rpc_response_cb($c, $req_storage);

    my $before_get_rpc_response_hook = delete($req_storage->{before_get_rpc_response}) || [];
    my $after_got_rpc_response_hook  = delete($req_storage->{after_got_rpc_response})  || [];
    my $before_call_hook             = delete($req_storage->{before_call})             || [];

    my $callobj = {
        # enough for short-term uniqueness
        id => join('_', $$, $request_number++, time, (0 + [])),
        method => $method,
        params => $self->make_call_params($c, $req_storage),
    };

    $_->($c, $req_storage) for @$before_call_hook;

    $client->call(
        $url, $callobj,
        $client->$curry::weak(
            sub {
                my $client = shift;
                my $res    = pop;

                $_->($c, $req_storage) for @$before_get_rpc_response_hook;

                # unconditionally stop any further processing if client is already disconnected
                return unless $c->tx;

                my $api_response;
                if (!$res) {
                    my $tx      = $client->tx;
                    my $details = 'URL: ' . $tx->req->url;
                    if (my $err = $tx->error) {
                        $details .= ', code: ' . ($err->{code} // 'n/a') . ', response: ' . $err->{message};
                    }
                    warn "WrongResponse [$msg_type], details: $details";
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

                $api_response = $rpc_response_cb->($res->result);

                return unless $api_response;

                $c->send({json => $api_response}, $req_storage);

                return;
            }));
    return;
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::Backend

=head1 DESCRIPTION

A subclass of L<Mojo::WebSocketProxy::Backend> which dispatched RPC requests
over JSON-RPC over HTTP/HTTPS.

=head1 METHODS

=head2 url

    $url = $backend->url

Returns the configured default dispatch URL.

=head2 call_rpc

Implements the L<Mojo::WebSocketProxy::Backend/call_rpc> interface.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
