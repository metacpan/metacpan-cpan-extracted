package Clash::Stub::Plugins::Epsilon;
#                                doom@kzsu.stanford.edu
#                                14 May 2007


=head1 NAME

Clash::Stub::Plugins::Epsilon - stub module defines methods to be exported

=head1 SYNOPSIS

   use Module::List::Pluggable qw(:all);
   my $plugin_root = 'Clash::Stub::Plugins';
   import_modules( $plugin_root );

=head1 DESCRIPTION

Stub for testing Module::List::Pluggable.

=head2 EXPORT

All subs: maximal_nihilility

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
                  maximal_nihilility
               );
our $VERSION = '0.01';

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
