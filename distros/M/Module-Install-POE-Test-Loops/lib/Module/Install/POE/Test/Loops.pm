package Module::Install::POE::Test::Loops;
# vim: ts=3 sw=3 et

use 5.005;
use strict;
use warnings;
use Module::Install::Base;
use POE::Test::Loops;
use File::Spec;
use Carp ();

=head1 NAME

Module::Install::POE::Test::Loops - Install tests for L<POE::Loop>s

=cut

use vars qw{$VERSION @ISA};
$VERSION = '0.03';
@ISA     = qw{Module::Install::Base};


=head1 COMMANDS

This plugin adds the following Module::Install commands:

=head2 gen_loop_tests

  gen_loop_tests('t', qw(Glib));

Generates tests under the directory F<./t> for the Glib loop. Also adds
POE::Test::Loops to your configure_requires.

=cut

sub gen_loop_tests {
   my ($self, $dir, @args) = @_;

   _gen_loop_tests($self, $dir, \@args);

   if (defined $self->configure_requires) {
      my %c_r = @{$self->configure_requires};
      return if (defined $c_r{'POE::Test::Loops'});
   }
   $self->configure_requires('POE::Test::Loops', '1.002')
}

sub _gen_loop_tests {
   my ($self, $dir, $loops) = @_;

   my @tests = $self->tests ? (split / /, $self->tests) : 't/*.t';

   Carp::confess "no dirs given to gen_loop_tests"
      unless @$loops;

   POE::Test::Loops::generate($dir, $loops);
  
   $self->tests(
      join ' ', @tests,
         map   {
                  File::Spec->catfile("$dir/", lc($_), "*.t");
               } sort @$loops
   );
}

1;

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENSE gpl

This software is Copyright (c) 2008 by Martijn van Beers.

This is free software, licensed under the GNU General
Public License, Version 2 or higher. See the LICENSE file for details.
