package Mojolicious::Plugin::GzipStatic;
use Mojo::Base 'Mojolicious::Plugin';
use IO::Compress::Gzip 'gzip';

our $VERSION = '0.04';

sub register {
    my ($self, $app) = @_;

    $app->hook(after_static => sub {
        my $c = shift;

        my $type = $c->res->headers->content_type;
        if (defined($type)
            && $type =~ /text|xml|javascript|json/
            && ($c->req->headers->accept_encoding // '') =~ /gzip/i) {
            $c->res->headers->append(Vary => 'Accept-Encoding');

            $c->res->headers->content_encoding('gzip');

            my $asset = $c->res->content->asset;

            gzip \$asset->slurp, \my $compressed;

            $asset = Mojo::Asset::Memory->new;
            $asset->add_chunk($compressed);

            $c->res->content->asset($asset);
        }
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::GzipStatic - Mojolicious Plugin to compress the static files before serving them.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('GzipStatic');

  # Mojolicious::Lite
  plugin 'GzipStatic';

=head1 DESCRIPTION

L<Mojolicious::Plugin::GzipStatic> is a L<Mojolicious> plugin to compress the static files before serving them.

See L<https://en.wikipedia.org/wiki/HTTP_compression> and
L<http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Post-processing-dynamic-content>.

=head1 METHODS

L<Mojolicious::Plugin::GzipStatic> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<Mojolicious::Static>, L<IO::Compress::Gzip>.

=cut
