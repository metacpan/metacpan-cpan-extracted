# $Id$
package Prima::IPA::Geometry;

use strict;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(mirror shift_rotate rotate90 rotate180);
%EXPORT_TAGS = (one2one => [qw(mirror)]);

use constant vertical => 1;
use constant horizontal => 2;


1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Geometry - mapping pixels from one location to another

=head1 API

=over

=item mirror IMAGE [ type ]

Mirrors IMAGE vertically or horizontally, depending on integer C<type>,
which can be one of the following constants:

   Prima::IPA::Geometry::vertical
   Prima::IPA::Geometry::horizontal

Supported types: all

=item shift_rotate IMAGE [ where, size ]

Shifts image in direction C<where>, which is one of the following constants

   Prima::IPA::Geometry::vertical
   Prima::IPA::Geometry::horizontal

by the offset, specified by integer C<size>.

Supported types: all, except that the horizontal transformation does not
support 1- and 4- bit images.

=item rotate90 IMAGE [ clockwise = true ]

Rotates image on 90 degrees clockwise or counter-clockwise

=item rotate180 IMAGE

Rotates image on 180 degrees

=back

=cut
