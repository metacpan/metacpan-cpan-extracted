package Module::New;

use strict;
use warnings;
use Carp;
use Module::New::Loader;

our $VERSION = '0.15';

my $CONTEXT;

sub options {qw( help|h|? author=s email=s force|f grace subdir|in=s )}
sub default { 'help' }

sub setup {
  my ($class, @bases) = @_;

  my $loader = Module::New::Loader->new( @bases );

  $CONTEXT = $loader->load( 'Context', undef, @bases );
  $CONTEXT->config->get_options( $class->options );
  $CONTEXT;
}

sub context { $CONTEXT ? $CONTEXT : shift->setup }

sub dispatch {
  my ($class, @bases) = @_;

  $class->setup(@bases);

  my $name = shift @ARGV || $class->default;

  unshift @ARGV, $name if $CONTEXT->config('help');

  my $recipe = $CONTEXT->loader->load_class( Recipe => $name );

  $CONTEXT->config->get_options( $recipe->options );

  croak "author is required" unless $CONTEXT->config('author');
  croak "email is required"  unless $CONTEXT->config('email');

  $recipe->run( @ARGV );
}

1;

__END__

=head1 NAME

Module::New - creates module/distribution skeleton and more

  From a command line

  > module_new dist Dist-Name
  > cd Dist-Name/trunk
  > module_new file Dist::Name::Plugin
  > module_new file t/dist_test.t --edit
  > module_new manifest --force

=head1 DESCRIPTION

This is yet another module starter. You can use this not only when you create a new distribution but also when you add a new module or test or plain text to the distribution. You may want to edit a new file after creation. You may want to update MANIFEST. This'll do.

Generally, 'module_new' command takes one recipe (sub-command) name, arguments for the recipe and global or local options if any. See appropriate PODs for details.

=head1 METHODS

=head2 options

specifies global command line options, which all the recipes (sub-commands) should have.

=head2 default

specifies a default recipe which would be executed when you don't give any recipe ('help' by default). 

=head2 dispatch

parses command line options and dispatches to the requested recipe.

=head2 setup

sets up a context object.

=head2 context

sets up a context object if necessary, and returns the object.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
