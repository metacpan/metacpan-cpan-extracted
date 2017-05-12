package Tree::Limb::Healthy;
#                                doom@kzsu.stanford.edu
#                                15 May 2007


=head1 NAME

Tree::Limb::Healthy  - a set of dummy plugins

=head1 SYNOPSIS

   use Module::List::Pluggable qw(:all);
   my $plugin_root = 'Tree::Limb::Healthy';
   import_modules( $plugin_root );

=head1 DESCRIPTION

Stub for testing Module::List::Pluggable.

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
                  nothing_much
                  back_atcha
                  maximal_nihilility
               );
our $VERSION = '0.01';

sub nothing_much {
  my $self = shift;  # right?
  return "Nothing much. What's with you?";
}

sub back_atcha {
  my $self = shift;  # right?
  my $string = shift;
  return "Do you say: $string";
}

sub maximal_nihilility {
  my $self = shift;  # right?
  return "Zippy!";
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
