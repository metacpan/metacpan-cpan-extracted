=head1 Name

Starlink::ATL::Region - Tools for AST regions.

=head1 SYNOPSIS

  use Starlink::ATL::Region qw/merge_regions/;

  my $cmp = merge_regions(\@regions);

=head1 DESCRIPTION

This module contains a utility subroutine for working
with AST regions.

=cut

package Starlink::ATL::Region;

use strict;

use Exporter;
use Starlink::AST;

our $VERSION = 0.04;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/merge_regions/;

=head1 SUBROUTINES

=over 4

=item B<merge_regions>

Takes a reference to an array of AST regions and returns a single
CmpRegion object.  The CmpRegion is built in a tree manner rather
than linearly to minimize the depth of the structure.

=cut

sub merge_regions {
  my $ref = shift;
  my @regions = @$ref;

  return unless @regions;

  # While we have more than one region in our list, keep
  # merging them.
  while (1 < scalar @regions) {
    my @tmp = ();

    # Step over the list, 2 spots at a time, taking the two
    # regions and making them into a CmpRegion.
    for (my $i = 0; $i <= $#regions; $i += 2) {
      # Odd number of regions? Allow the last through unmerged.
      if ($i == $#regions) {
        push @tmp, $regions[$i];
      }
      else {
        push @tmp, $regions[$i]->CmpRegion($regions[$i + 1],
                 Starlink::AST::Region::AST__OR(), '');
      }
    }

    @regions = @tmp;
  }

  return $regions[0];
}

1;

__END__

=back

=head1 AUTHOR

Graham Bell <g.bell@jach.hawaii.edu>

=head1 COPYRIGHT

Copyright (C) 2012 Science and Technology Facilities Council.

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
