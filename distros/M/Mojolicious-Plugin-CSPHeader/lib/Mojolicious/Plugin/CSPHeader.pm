package Mojolicious::Plugin::CSPHeader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
    my ($self, $app, $conf) = @_;

    $app->hook(before_dispatch => sub {
        my $c = shift;

        $c->res->headers->content_security_policy($conf->{csp});
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CSPHeader - Mojolicious Plugin to add Content-Security-Policy header to every HTTP response.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'");

  # Mojolicious::Lite
  plugin 'CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'";

=head1 DESCRIPTION

L<Mojolicious::Plugin::CSPHeader> is a L<Mojolicious> plugin which adds Content-Security-Policy header to every HTTP response.

To know what should be the CSP header to add to your site, you can use this Firefox addon: L<https://addons.mozilla.org/fr/firefox/addon/laboratory-by-mozilla/>.

L<https://content-security-policy.com/> provides a good documentation about CSP.

L<https://report-uri.com/home/generate> provides a tool to generate a CSP header.

=head1 METHODS

L<Mojolicious::Plugin::CSPHeader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/luc/mojolicious-plugin-cspheader
  git clone https://framagit.org/luc/mojolicious-plugin-cspheader.git

Bugs and feature requests will be tracked at:

  https://framagit.org/luc/mojolicious-plugin-cspheader/issues

=head1 AUTHOR

  Luc DIDRY
  CPAN ID: LDIDRY
  ldidry@cpan.org
  https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<https://www.w3.org/TR/CSP/>

=cut
