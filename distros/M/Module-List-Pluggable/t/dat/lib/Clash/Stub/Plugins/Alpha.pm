package Clash::Stub::Plugins::Alpha;
#                                doom@kzsu.stanford.edu
#                                14 May 2007


=head1 NAME

Clash::Stub::Plugins::Alpha - stub module defines methods to be exported

=head1 SYNOPSIS

   use Module::List::Pluggable qw(:all);
   my $plugin_root = 'Clash::Stub::Plugins';
   import_modules( $plugin_root );


=head1 DESCRIPTION

Stub for testing Module::List::Pluggable.

=head2 EXPORT

All subs:
                  nothing_much
                  back_atcha
                  parrot_but_not_that_parrot


=cut

use 5.006;
use strict;
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
                  nothing_much
                  back_atcha
                  parrot_but_not_that_parrot
               );

our $VERSION = '0.01';

# Preloaded methods go here.

sub nothing_much {
  my $self = shift;  # right?
  return "Nothing much. What's with you?";
}

sub back_atcha {
  my $self = shift;  # right?
  my $string = shift;
  return "Do you say: $string";
}


sub parrot_but_not_that_parrot {
  my $self = shift;  # right?
  my $string = shift;
  return "Squawk: $string";
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
