# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Mojolicious::Plugin::ZipBomb;
use Mojo::Base 'Mojolicious::Plugin';
use File::Share ':all'; 

our $VERSION = '0.03';

sub register {
    my ($self, $app, $conf) = @_;

    my @methods = qw(any);
    @methods    = @{$conf->{methods}} if $conf->{methods};

    for my $route (@{$conf->{routes}}) {
        for my $method (@methods) {
            $app->routes->$method($route, \&_drop_bomb);
        }
    }
}

sub _drop_bomb {
    my $c = shift;

    my $bomb = dist_file('Mojolicious-Plugin-ZipBomb', '42.zip');

    $c->res->headers->content_encoding('gzip');

    $c->res->headers->content_type('text/html') if ($c->app->mode eq 'production');

    $c->reply->file($bomb);
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ZipBomb - Mojolicious Plugin to serve a zip bomb on configured routes.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('ZipBomb', { routes => ['/wp-admin.php'], methods => ['get'] });

  # Mojolicious::Lite
  plugin 'ZipBomb', { routes => ['/wp-admin.php'], methods => ['get'] } };

=head1 DESCRIPTION

L<Mojolicious::Plugin::ZipBomb> is a L<Mojolicious> plugin to serve a zip bomb on configured routes.

=head1 CONFIGURATION

When registering the plugin, C<routes> is required, but C<methods> is optional.
Per default, the routes leading to the zip bomb use any method.

=head1 METHODS

L<Mojolicious::Plugin::ZipBomb> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
