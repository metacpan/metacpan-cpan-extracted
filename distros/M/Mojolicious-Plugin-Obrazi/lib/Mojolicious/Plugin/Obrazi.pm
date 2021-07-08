package Mojolicious::Plugin::Obrazi;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use feature ':5.26';

our $VERSION = '0.14';

my sub _obrazi {
  return 'Helper obrazi(…) is not implemented yet…';
}

sub register ($self, $app, $config) {
  $app->helper(obrazi => \&_obrazi);
  return $self;
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
command — L<Mojolicious::Command::Author::generate::obrazi>, that generates html
for an images gallery and a not yet wirtten L<helper|/obrazi> which produces
HTML from a CSV file found in a directory, containing images. While the command
is functional already the plugin is empty. This is a yet early release. Todo:
write the helper.

=head1 METHODS

L<Mojolicious::Plugin::Obrazi> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 HELPERS

=head2 obrazi

    <!-- in a template -->
    <%= obrazi(csv_file => 'path/to/obrazi.csv') %>

Renders a gallery section in the current page. Not implemented yet.

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
