package Tree::Limb::Broken;
#                                doom@kzsu.stanford.edu
#                                15 May 2007


=head1 NAME

Tree::Limb::Broken  - a set of dummy plugins

=head1 SYNOPSIS

   use Module::List::Pluggable qw(:all);
   my $plugin_root = 'Tree::Limb::Broken';
   import_modules( $plugin_root );

=head1 DESCRIPTION

Stub for testing Module::List::Pluggable.

The sub totally_flat_busted contains a syntax error that
will prevent this code from compiling correctly.

=head2 EXPORT

All subs.

=cut

use 5.006;
use strict;
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                  oops
                  minimum_fuss
                  totally_flat_busted
               );

our $VERSION = '0.01';

sub oops {
  my $self = shift;  # right?
  return "Splat!";
}

sub minimum_fuss {
  my $self = shift;  # right?
  return "";
}

sub totally_flat_busted {
  my $self = shift;  # right?
  my $string = shiftless;
  return "No kind of worker: $string";
}




1;

=head1 SEE ALSO

L<Module::List::Pluggable>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
