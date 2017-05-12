package Mojolicious::Plugin::VHost;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.04';

sub register {
    my ($plugin, $app) = @_;

    my %defaults = (
        routes => $app->routes->namespaces,
        static => $app->static->paths,
        templates => $app->renderer->paths,
    );

    $app->hook(
        before_dispatch => sub {
            my $c = shift;

            my $host = $c->tx->req->headers->host;

            my $hosts = $c->app->config('VHost') || {};
            my %conf = ( %defaults, %{$hosts->{$host} || {}} );

            my $app = $c->app;
            $app->routes->namespaces($conf{routes});
            $app->static->paths($conf{static});
            $app->renderer->paths($conf{templates});
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::VHost - Mojolicious Plugin that adds VirtualHosts

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('JSONConfig');
  $self->plugin('VHost');

=head1 DESCRIPTION

L<Mojolicious::Plugin::VHost> adds virtualhosts to L<Mojolicious>.

=head1 CONFIGURATION

One supported method of configuration is with the JSONConfig plugin.  Add vhosts with a config such as:

    {
        "VHost":
            {
                "host1":{"routes":["VHost::First::Controller"],"static":["public\/first"],"templates":["templates\/first"]},
                "host2":{"routes":["VHost::Another::Controller"],"static":["public\/another"],"templates":["templates\/another"]}
            }
    }

host1 and host2 are the Host: header field and must match exactly.  The following route format has been tested:

  $r->get('/')->to(controller => 'Index', action => 'slash');
  $r->get('/:name')->to(controller => 'Index', action => 'slash');

For host1, "/" would route to lib/VHost/First/Index.pm; static files would be in public/first; and templates
would be found in templates/first.

A full startup sub is:

    sub startup {
      my $self = shift;

      $self->plugin('JSONConfig');
      $self->plugin('VHost');

      # Router
      my $r = $self->routes;

      $r->get('/')->to(controller => 'Index', action => 'slash');
      $r->get('/:name')->to(controller => 'Index', action => 'slash');
    }

=head1 METHODS

L<Mojolicious::Plugin::VHost> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
