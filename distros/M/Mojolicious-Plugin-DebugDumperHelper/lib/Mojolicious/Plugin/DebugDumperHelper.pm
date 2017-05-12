# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Mojolicious::Plugin::DebugDumperHelper;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

sub register {
    my ($self, $app) = @_;
    $app->helper(
        debug => sub {
            my ($c, @struct) = @_;
            $c->app->log->debug("VAR DUMP\n".$c->dumper(\@struct));
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DebugDumperHelper - Mojolicious Plugin

=head1 DESCRIPTION

L<Mojolicious::Plugin::DebugDumperHelper> is a L<Mojolicious> plugin which provides a helper which dumps its arguments to the debug log level (no effect in production mode).

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('DebugDumperHelper');

  # Mojolicious::Lite
  plugin 'DebugDumperHelper';

  # Use in controller
  $c->debug(qw<Bite my shiny ass!>);
  # In your development.log
  [Wed Jun 10 19:32:01 2015] [debug] VAR DUMP
  [
    "Bite",
    "my",
    "shiny",
    "ass!"
  ]

=head1 METHODS

L<Mojolicious::Plugin::DebugDumperHelper> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/luc/mojolicious-plugin-debugdumperhelper
  git clone https://framagit.org/luc/mojolicious-plugin-debugdumperhelper.git

Bugs and feature requests will be tracked at:

  https://framagit.org/luc/mojolicious-plugin-debugdumperhelper/issues

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

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
