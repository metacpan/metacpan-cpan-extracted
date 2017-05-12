#############
# Created By: setitesuk
# Created On: 2010-04-20

package Test::Structures::Data;
use strict;
use warnings;
use Carp;
use English qw{-no_match_vars};
use Readonly; Readonly::Scalar our $VERSION => 0.025;

use base qw{Exporter};
our @EXPORT = qw{is_value_found_in_hash_values}; ## no critic (Modules::ProhibitAutomaticExportation)

use Test::Builder;

my $test = Test::Builder->new();

=head1 NAME

Test::Structures::Data

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  use Test::More tests => 21;
  use Test::Structures::Data;

  is_value_found_in_hash_values( $value, $href, $optional_description );

=head1 DESCRIPTION

This module gives additional tests created by Test::Builder which will test data structures. Currently only one is available,
however more are planned.

=head1 SUBROUTINES/METHODS

=head2 is_value_found_in_hash_values

exported by default. This test checks to see if the value you provide is within the values of the hashref also provided as the second arguement.

  is_value_found_in_hash_values( $value, $href, $optional_description );

=cut

sub is_value_found_in_hash_values {
  my ( $value, $hash, $desc ) = @_;

  my $result;

  foreach my $key ( keys %{ $hash } ) {
    if ( $value eq $hash->{$key} ) {
      $result = 1;
      last;
    }
  }

  return $test->ok( $result, $desc ) || $test->diag( "$value not found in hash $hash" );
}

1;
__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item English -no_match_vars

=item Test::Builder

=item Readonly

=item base

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Most code has bugs and/or limitations, and this code is likely no exception. Please contact me via RT if available, email if not if you have any problems, concerns, patches or updates.

=head1 AUTHOR

$Author$

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 Andy Brown (setitesuk@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
