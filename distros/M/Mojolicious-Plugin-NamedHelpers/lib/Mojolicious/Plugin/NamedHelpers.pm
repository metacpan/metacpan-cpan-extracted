package Mojolicious::Plugin::NamedHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use Sub::Util qw(set_subname);

our $VERSION = '0.03';

sub register {
  my ($self, $app, $arg) = @_;
  $arg->{namespace} //= ref($app);
  $app->helper(
    named_helper => sub {
      my ($c, $name, $sub) = @_;
      $c->app->helper($name => set_subname "$arg->{namespace}::$name", $sub);
    }
  );
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::NamedHelpers - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('NamedHelpers');
  $self->named_helper( my_little_helper => sub { ... } );

  # Mojolicious::Lite
  plugin 'NamedHelpers';

  # Mojolicious::Lite - with custom namespace
  plugin 'NamedHelpers' => { namespace => 'My::App::Helpers' };


=head1 DESCRIPTION

L<Mojolicious::Plugin::NamedHelpers> is a L<Mojolicious> plugin that sets a fully qualified name to anonymous helper subs using a tiny wrapper upon helper creation.
Without this plugin those subs will be named __ANON__, but now they will be named after the helper.

By default the namespace will be the same as the app, but this can be overridden if desired.

The author's use-case is for providing more context in JSON-based application logs, where all helpers would identify themselves as __ANON__.

=head1 HELPERS

=head2 named_helper

This plugin provides a new helper called "named_helper".

By registering your helpers with "named_helper" the name of the sub will be set equal to the name of the helper.

=head1 AUTHOR

Vidar Tyldum <vidar@tyldum.com>

=head1 CREDITS

This module is written by Vidar Tyldum, but with crucial help from the #mojo IRC channel on irc.perl.org.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Vidar Tyldum.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Sub::Util>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
