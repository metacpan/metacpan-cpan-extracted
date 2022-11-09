package Mojolicious::Plugin::WebSocketProxy;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::WebSocketProxy::Backend;
use Mojo::WebSocketProxy::Config;
use Mojo::WebSocketProxy::Dispatcher;

use Log::Any qw($log);

# Other backend types may be available; we default to 'jsonrpc' in the code below
use Mojo::WebSocketProxy::Backend::JSONRPC;

our $VERSION = '0.14';    ## VERSION

sub register {
    my ($self, $app, $config) = @_;

    die 'No base path found!' unless $config->{base_path};

    my $url_setter;
    $url_setter = delete $config->{url} if $config->{url} and ref($config->{url}) eq 'CODE';
    $app->helper(
        call_rpc => sub {
            my ($c, $req_storage) = @_;
            $url_setter->($c, $req_storage) if $url_setter && !$req_storage->{url};
            return $c->forward($req_storage);
        });
    $app->helper(
        wsp_error => sub {
            shift;    # $c
            my ($msg_type, $code, $message, $details) = @_;

            my $error = {
                code    => $code,
                message => $message
            };
            $error->{details} = $details if ref($details) eq 'HASH' && keys %$details;

            if ($details && ref($details) ne 'HASH') {
                $log->debugf("Details in a websocket error must be a hash reference instead of a %s", ref($details));
            }

            return {
                msg_type => $msg_type,
                error    => $error,
            };
        });

    my $r = $app->routes;
    for ($r->under($config->{base_path})) {
        $_->to('Dispatcher#ok', namespace => 'Mojo::WebSocketProxy');
        $_->websocket('/')->to('Dispatcher#open_connection', namespace => 'Mojo::WebSocketProxy');
    }

    my $actions           = delete $config->{actions};
    my $dispatcher_config = Mojo::WebSocketProxy::Config->new;
    $dispatcher_config->init($config);

    if (ref $actions eq 'ARRAY') {
        for (my $i = 0; $i < @$actions; $i++) {
            $dispatcher_config->add_action($actions->[$i], $i);
        }
    } else {
        die 'No actions found!';
    }

    my $default_backend = delete $config->{default_backend} // '';
    if (my $backend_configs = delete $config->{backends}) {
        foreach my $name (keys %$backend_configs) {
            my %args = %{$backend_configs->{$name}};
            my $type = delete($args{type}) // 'jsonrpc';
            my $key  = $default_backend eq $name ? 'default' : $name;
            $dispatcher_config->add_backend($key => Mojo::WebSocketProxy::Backend->backend_instance($type => %args));
        }
    }

    # For backwards compatibility, we always want to add a plain JSON::RPC backend
    my $jsonrpc_backend_key = exists $dispatcher_config->{backends}->{default} ? 'http' : 'default';
    $dispatcher_config->add_backend(
        $jsonrpc_backend_key => Mojo::WebSocketProxy::Backend->backend_instance(
            jsonrpc => url => delete $config->{url},
        ));

    $app->helper(
        wsp_config => sub {
            my $c = shift;
            return $dispatcher_config;
        });

    # Subscribe on notification about termination of worker.
    Mojo::IOLoop->singleton->once(finish => $config->{before_shutdown}) if $config->{before_shutdown};

    return;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::WebSocketProxy

=head1 SYNOPSYS

    # lib/your-application.pm

    use base 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [
                    ['json_key', {some_param => 'some_value'}]
                ],
                base_path => '/api',
                url => 'http://rpc-host.com:8080/',
            }
        );
   }

Or to manually call RPC server:

    # lib/your-application.pm

    use base 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [
                    [
                        'json_key',
                        {
                            instead_of_forward => sub {
                                shift->call_rpc({
                                    args => $args,
                                    method => $rpc_method, # it'll call 'http://rpc-host.com:8080/rpc_method'
                                    rpc_response_cb => sub {...}
                                });
                            }
                        }
                    ]
                ],
                base_path => '/api',
                url => 'http://rpc-host.com:8080/',
            }
        );
   }

=head1 DESCRIPTION

Using this module you can forward websocket JSON-RPC 2.0 requests to RPC server.
See L<Mojo::WebSocketProxy> for details on how to use hooks and parameters.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::Backend>,
L<Mojo::WebSocketProxy::Dispatcher>
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
