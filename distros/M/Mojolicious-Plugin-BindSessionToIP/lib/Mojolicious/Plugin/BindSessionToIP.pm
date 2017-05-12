package Mojolicious::Plugin::BindSessionToIP;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';
use v5.10;
use Data::Dumper;

sub register {
    my ( $self, $app, $conf ) = @_;

    # On error callback
    my $on_error;
    if ( $conf->{on_error} && ref($conf->{on_error}) eq 'CODE' ) {
        $on_error = $conf->{on_error};
    } else {
        $on_error = sub { shift->redirect_to('/'); };
    }

    $app->hook(
        before_routes => sub {
            my ($c) = @_;

            my $stored_ip = $c->session('bind_session_to_ip.ip') // '';
            my $req_ip    = $c->remote_addr;

            if ( $stored_ip ne $req_ip ) {
                if ($stored_ip) {
                    $c->app->log->debug("BindSessionToIP: IP changed from [$stored_ip] to [$req_ip]");

                    $self->_destroy_session($c);
                    $c->session('bind_session_to_ip.ip' => $req_ip);
                    return $on_error->($c);
                }

                $c->session('bind_session_to_ip.ip' => $req_ip);
            }

            return 1;
        },
    );
}


sub _destroy_session {
    my ( $self, $c ) = @_;
    my $session = $c->session;

    foreach my $key (keys %$session) {
        $session->{$key} = '';
    }
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::BindSessionToIP - Binds your Mojolicious session to IP-address for better security of your application

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('RemoteAddr'); # For getting remote ip address
  $self->plugin('BindSessionToIP');

  # Mojolicious::Lite
  plugin 'RemoteAddr';
  plugin 'BindSessionToIP';

=head1 DESCRIPTION

L<Mojolicious::Plugin::BindSessionToIP> binds your Mojolicious session to IP-address for better security of your application.
If client IP was changed then the plugin will clean client's sessions and will redirect to '/'.
It uses L<Mojolicious::Plugin::RemoteAddr>, so please check "order" option.

=head1 CONFIG

=head2 on_error

You can pass custom error handling callback. For example

  $self->plugin('BindSessionToIP', on_error => sub {
      my $c = shift;
      $c->render(template => 'wrong_session', status => 403 );
  });

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
