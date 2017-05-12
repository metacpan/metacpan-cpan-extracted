package Mojolicious::Plugin::JsonRpcDispatcher;

use Mojo::Base 'Mojolicious::Plugin';
use MojoX::JSON::RPC::Dispatcher;

sub register {
    my ( $self, $app, $conf ) = @_;

    my $r = $app->routes;
    if ( exists $conf->{services} && ref $conf->{services} eq 'HASH' ) {
    SVC:
        while ( my ( $path, $svc ) = each %{ $conf->{services} } ) {
            $r->route($path)->to(
                'Dispatcher#call',
                service   => $svc,
                namespace => 'MojoX::JSON::RPC',
                exists $conf->{exception_handler}
                ? ( exception_handler => $conf->{exception_handler} )
                : ()
            );
        }
    }
    else {
        Carp::confess 'No services found!';
    }
    return;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::JsonRpcDispatcher - Plugin to allow Mojolicious to act as a JSON-RPC server.

=head1 SYNOPSIS

    # lib/your-application.pm

    use base 'Mojolicious';
    use MojoX::JSON::RPC::Service;

    sub startup {
        my $self = shift;
        my $svc = MojoX::JSON::RPC::Service->new;

        $svc->register(
            'sum',
            sub {
                my @params = @_;
                my $sum = 0;
                $sum += $_ for @params;
                return $sum;
            }
        );

        $self->plugin(
            'json_rpc_dispatcher',
            services => {
               '/jsonrpc' => $svc
            }
        );
   }

Or in lite-app:

    use Mojolicious::Lite;
    use MojoX::JSON::RPC::Service;

    plugin 'json_rpc_dispatcher' => {
        services => {
            '/jsonrpc' => MojoX::JSON::RPC::Service->new->register(
                'sum',
                sub {
                    my @params = @_;
                    my $sum    = 0;
                    $sum += $_ for @params;
                    return $sum;
                }
            )
        }
    };

=head1 DESCRIPTION

This plugin turns your Mojolicious or Mojolicious::Lite application
into a JSON-RPC 2.0 server.

The plugin understands the following parameters.

=over

=item B<services> (mandatory)

A pointer to a hash of service instances. See L<MojoX::JSON::RPC::Service> for details on how
to write a service.

    $self->plugin(
        'json_rpc_dispatcher',
         services => {
           '/jsonrpc'  => $svc,
           '/jsonrpc2' => $svc2,
           '/jsonrpc3' => $svc3,
           '/jsonrpc4' => $svc4
         }
    );

=item B<exception_handler> (optional)

Reference to a method that is called when an uncatched exception occurs within a rpc call.
If exception_handler is not specified then internal error is returned as result of the rpc call.

    $self->plugin(
        'json_rpc_dispatcher',
         services => {
             '/jsonrpc'  => $svc,
         },
         exception_handler => sub {
             my ( $dispatcher, $err, $m ) = @_;

             # $dispatcher is the dispatcher Mojolicious::Controller object
             # $err is $@ received from the exception
             # $m is the MojoX::JSON::RPC::Dispatcher::Method object to be returned.

             $dispatcher->app->log->error(qq{Internal error: $err});

             # Fake invalid request
             $m->invalid_request('Faking invalid request');
             return;
        }
    );

=back

=head1 SEE ALSO

L<MojoX::JSON::RPC>

=cut
