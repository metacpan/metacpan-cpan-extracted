package Mojo::WebSocketProxy::Dispatcher;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::WebSocketProxy::Parser;
use Mojo::WebSocketProxy::Config;

use Class::Method::Modifiers;

use JSON::MaybeUTF8    qw(:v1);
use Unicode::Normalize ();
use Future::Mojo 0.004;    # ->new_timeout
use Future::Utils qw(fmap);
use Scalar::Util  qw(blessed);
use Encode;
use DataDog::DogStatsd::Helper qw(stats_inc);

use constant TIMEOUT => $ENV{MOJO_WEBSOCKETPROXY_TIMEOUT} || 15;
use Mojo::WebSocketProxy::RequestLogger;

our $VERSION = '0.15';     ## VERSION
around 'send' => sub {
    my ($orig, $c, $api_response, $req_storage) = @_;

    my $config = $c->wsp_config->{config};

    my $max_response_size = $config->{max_response_size};
    if ($max_response_size && length(encode_json_utf8($api_response)) > $max_response_size) {
        $api_response->{json} = $c->wsp_error('error', 'ResponseTooLarge', 'Response too large.');
    }

    my $before_send_api_response = $config->{before_send_api_response};
    $_->($c, $req_storage, $api_response->{json})
        for grep { $_ } (ref $before_send_api_response eq 'ARRAY' ? @{$before_send_api_response} : $before_send_api_response);

    my $ret = $orig->($c, $api_response);

    my $after_sent_api_response = $config->{after_sent_api_response};
    $_->($c, $req_storage) for grep { $_ } (ref $after_sent_api_response eq 'ARRAY' ? @{$after_sent_api_response} : $after_sent_api_response);

    return $ret;
};

sub ok {
    return 1;
}

sub open_connection {
    my ($c) = @_;

    my $log = $c->app->log;
    $log->debug("accepting a websocket connection from " . $c->tx->remote_address);
    # Enable permessage-deflate
    $c->tx->with_compression;

    my $config = $c->wsp_config->{config};

    Mojo::IOLoop->singleton->stream($c->tx->connection)->timeout($config->{stream_timeout}) if $config->{stream_timeout};
    Mojo::IOLoop->singleton->max_connections($config->{max_connections})                    if $config->{max_connections};

    $config->{opened_connection}->($c) if $config->{opened_connection};

    $c->on(
        text => sub {
            my ($c, $msg) = @_;

            my $original = "$msg";
            # Incoming data will be JSON-formatted text, as a Unicode string.
            # We normalize the entire string before decoding.

            my $decoded = eval { Encode::decode_utf8($msg, Encode::FB_CROAK) } or do {
                $c->tx->emit(
                    encoding_error => _get_error_details(
                        code    => 'INVALID_UTF8',
                        reason  => 'Malformed UTF-8 data',
                        message => $msg
                    ));
                return;
            };

            # The Unicode::Normalize::NFC check is added as a safety net. However, the error is not triggered so far.
            my $normalized_msg = eval { Unicode::Normalize::NFC($decoded) } or do {
                $c->tx->emit(
                    encoding_error => _get_error_details(
                        code    => 'INVALID_UNICODE',
                        reason  => 'Malformed Unicode data',
                        message => $msg
                    ));
                return;
            };

            my $args = eval { decode_json_text($normalized_msg); } or do {
                $c->tx->emit(
                    encoding_error => _get_error_details(
                        code    => 'INVALID_JSON',
                        reason  => 'Malformed JSON data',
                        message => $msg
                    ));
                return;
            };

            on_message($c, $args);
        });

    $c->on(
        binary => sub {
            my ($d, $bytes) = @_;
            $config->{binary_frame}(@_) if $bytes and exists($config->{binary_frame});
        });

    $c->on(finish => $config->{finish_connection}) if $config->{finish_connection};

    return;
}

sub on_message {
    my ($c, $args) = @_;

    my $config = $c->wsp_config->{config};

    my $req_storage = {};
    $req_storage->{args} = $args;

    $req_storage->{logger} = Mojo::WebSocketProxy::RequestLogger->new;
    # We still want to run any hooks even for invalid requests.
    if (my $err = Mojo::WebSocketProxy::Parser::parse_req($c, $req_storage)) {
        $c->send({json => $err}, $req_storage);
        return $c->_run_hooks($config->{after_dispatch} || [])->retain;
    }

    my $action = $c->dispatch($args) or do {
        my $err = $c->wsp_error('error', UnrecognisedRequest => 'Unrecognised request');
        $c->send({json => $err}, $req_storage);
        return $c->_run_hooks($config->{after_dispatch} || [])->retain;
    };

    @{$req_storage}{keys %$action} = (values %$action);
    $req_storage->{method} = $req_storage->{name};

    # main processing pipeline
    my $f = $c->before_forward($req_storage)->transform(
        done => sub {
            # Note that we completely ignore the return value of ->before_forward here.
            return $req_storage->{instead_of_forward}->($c, $req_storage) if $req_storage->{instead_of_forward};
            return $c->forward($req_storage);
        }
    )->then(
        sub {
            my $result = shift;
            return $c->after_forward($result, $req_storage)->transform(done => sub { $result });
        },
        sub {
            my $result = shift;
            Future->done($result);
        });

    return Future->wait_any(
        Future::Mojo->new_timeout(TIMEOUT)->else(
            sub {
                return Future->done($c->wsp_error('error', Timeout => 'Timeout'));
            }
        ),
        $f
    )->then(
        sub {
            my ($result) = @_;
            $c->send({json => $result}, $req_storage) if $result;
            return $c->_run_hooks($config->{after_dispatch} || []);
        }
    )->on_fail(
        sub {
            $c->app->log->error("An error occurred handling on_message. Error @_");
        })->retain;
}

sub before_forward {
    my ($c, $req_storage) = @_;

    my $config = $c->wsp_config->{config};

    my $before_forward_hooks = [];

    # Global hooks are always first
    for ($config, $req_storage) {
        push @$before_forward_hooks, ref($_->{before_forward}) eq 'ARRAY' ? @{$_->{before_forward}} : $_->{before_forward};
    }

    # We always want to clear these after every request.
    delete $req_storage->{before_forward};

    return $c->_run_hooks($before_forward_hooks, $req_storage);
}

sub after_forward {
    my ($c, $result, $req_storage) = @_;

    my $config = $c->wsp_config->{config};
    return $c->_run_hooks($config->{after_forward} || [], $result, $req_storage);
}

sub _run_hooks {
    my @hook_params = @_;
    my $c           = shift @hook_params;
    my $hooks       = shift @hook_params;

    my $result_f = fmap {
        my $hook   = shift;
        my $result = $hook->($c, @hook_params) or return Future->done;
        return $result if blessed($result) && $result->isa('Future');
        return Future->fail($result);
    }
    foreach        => [grep { defined } @$hooks],
        concurrent => 1;
    return $result_f;
}

sub dispatch {
    my ($c, $args) = @_;

    my $log = $c->app->log;
    $log->debug("websocket got json " . $c->dumper($args));

    my ($action) =
        sort { $a->{order} <=> $b->{order} }
        grep { defined }
        map  { $c->wsp_config->{actions}->{$_} } keys %$args;

    return $action;
}

sub forward {
    my ($c, $req_storage) = @_;

    my $config = $c->wsp_config->{config};

    for my $hook (qw/ before_call before_get_rpc_response after_got_rpc_response /) {
        $req_storage->{$hook} = [
            grep { $_ } (ref $config->{$hook} eq 'ARRAY'      ? @{$config->{$hook}}      : $config->{$hook}),
            grep { $_ } (ref $req_storage->{$hook} eq 'ARRAY' ? @{$req_storage->{$hook}} : $req_storage->{$hook}),
        ];
    }

    # default to config (generic) only if call specific is not defined
    $req_storage->{rpc_failure_cb} //= $config->{rpc_failure_cb};

    my $backend_name = $req_storage->{backend} // "default";
    my $backend      = $c->wsp_config->{backends}{$backend_name}
        or die "Cannot dispatch request - no backend named '$backend_name'";

    $backend->call_rpc($c, $req_storage);

    return;
}

sub _get_error_details {
    my (%args) = @_;

    return {
        error   => 'Error Processing Request',
        details => {
            error_code   => $args{code},
            reason       => $args{reason},
            request_body => $args{message},
        },
    };
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::Dispatcher

=head1 DESCRIPTION

Using this module you can forward websocket JSON-RPC 2.0 requests to RPC server.
See L<Mojo::WebSocketProxy> for details on how to use hooks and parameters.

=head1 METHODS

=head2 open_connection

Run while opening new wss connection.
Run hook when connection is opened.
Set finish connection callback.

=head2 on_message

Handle message - parse and dispatch request messages.
Dispatching action and forward to RPC server. Note that all
incoming JSON messages are first normalised using
L<NFC|https://www.w3.org/International/articles/unicode-migration/#normalization>.
 


=head2 before_forward

Run hooks.

=head2 after_forward

Run hooks.

=head2 dispatch

Dispatch request using message json key.

=head2 forward

Forward call to RPC server using global and action hooks.
Don't forward call to RPC if any before_forward hook returns response.
Or if there is instead_of_forward action.

=head2 _get_error_details

Generates and returns a hash for error reporting

=head2 ok

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>,
L<Mojo::WebSocketProxy::Backend>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
