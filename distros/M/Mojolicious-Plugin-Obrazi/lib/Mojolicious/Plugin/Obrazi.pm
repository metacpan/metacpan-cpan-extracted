package Mojolicious::Plugin::Obrazi;
use feature ':5.26';
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.12';

sub register {
  my ($self, $app) = @_;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Obrazi - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Obrazi');

  # Mojolicious::Lite
  plugin 'Obrazi';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Obrazi> is a L<Mojolicious> plugin. It consists of a
command that generates html for an images gallery and a not yet wirtten helper
which produces HTML from a CSV file found in a directory containing images.
While the command is functional already the plugin is empty. This is a yet
early release. Todo: write the helper; prepare a demo page.

=head1 METHODS

L<Mojolicious::Plugin::Obrazi> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 NOTES

This plugin requires Perl 5.26+ and Mojolicious 9.17+.

=head1 COPYRIGHT

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious::Command::Author::generate::obrazi>,
L<Mojolicious>, L<Mojolicious::Guides>, L<Slovo>,
L<https://mojolicious.org>.

=cut
