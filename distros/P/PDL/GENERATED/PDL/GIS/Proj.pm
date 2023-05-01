#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GIS::Proj;

our @EXPORT_OK = qw( get_proj_info  fwd_transform inv_transform  load_projection_descriptions proj_version   load_projection_information  );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GIS::Proj ;







#line 19 "Proj.pd"

use strict;
use warnings;

=head1 NAME

PDL::GIS::Proj - PDL interface to the PROJ projection library.

=head1 DESCRIPTION

For more information on the PROJ library, see: L<http://www.proj.org/>
#line 38 "Proj.pm"

=head1 FUNCTIONS

=cut





#line 64 "Proj.pd"

=head2 get_proj_info($params_string)

Returns a string with information about what parameters proj will
actually use, this includes defaults, and +init=file stuff. It's 
the same as running 'proj -v'. It uses the proj command line, so
it might not work with all shells. I've tested it with bash.

=cut

sub get_proj_info
{
    my $params = shift;
    my @a = split(/\n/, `echo | proj -v $params`);
    pop(@a);
    return join("\n", @a);
} # End of get_proj_info()...
#line 66 "Proj.pm"

=head2 fwd_transform

=for sig

  Signature: (lonlat(n=2); [o] xy(n); char* params)

=for ref

PROJ forward transformation $params is a string of the projection
transformation parameters.

Returns a pdl with x, y values at positions 0, 1. The units are dependent
on PROJ behavior. They will be PDL->null if an error has occurred.

=for bad

Ignores bad elements of $lat and $lon, and sets the corresponding elements
of $x and $y to BAD

=for bad

fwd_transform processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*fwd_transform = \&PDL::fwd_transform;






=head2 inv_transform

=for sig

  Signature: (xy(n=2); [o] lonlat(n); char* params)

=for ref

PROJ inverse transformation $params is a string of the projection
transformation parameters.

Returns a pdl with lon, lat values at positions 0, 1. The units are
dependent on PROJ behavior. They will be PDL->null if an error has
occurred.

=for bad

Ignores bad elements of $lat and $lon, and sets the corresponding elements
of $x and $y to BAD

=for bad

inv_transform processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*inv_transform = \&PDL::inv_transform;





#line 213 "Proj.pd"

=head2 proj_version

Returns a 3-element list with PROJ major, minor, patch version-numbers.

=cut

my %SKIP = map +($_=>1), qw(
  and or Special for Madagascar
  fixed Earth For CH1903
);

sub load_projection_information
{
    my $descriptions = PDL::GIS::Proj::load_projection_descriptions();
    my $info = {};
    foreach my $projection ( sort keys %$descriptions )
    {
        my $description = $descriptions->{$projection};
        my $hash = {CODE => $projection};
        my @lines = split( /\n/, $description );
        chomp @lines;
        # Full name of this projection:
        ($hash->{NAME}, my $temp) = splice @lines, 0, 2;
        if ($temp) {
          # The second line is usually a list of projection types this one is:
          $temp =~ s/no inv\.*,*//;
          $temp =~ s/or//;
          my @temp_types = split(/[,&\s]/, $temp );
          my @types = grep( /.+/, @temp_types );
          $hash->{CATEGORIES} = \@types;
        }
        # If there's more than 2 lines, then it usually is a listing of parameters:
        # General parameters for all projections:
        $hash->{PARAMS}->{GENERAL} = 
            [ qw( x_0 y_0 lon_0 units init no_defs geoc over ) ];
        # Earth Figure Parameters:
        $hash->{PARAMS}->{EARTH} = 
            [ qw( ellps b f rf e es R R_A R_V R_a R_g R_h R_lat_g ) ];
        # Projection Specific Parameters:
        $hash->{PARAMS}{PROJ} = [
          grep !$SKIP{$_}, map {s/=//; s/[,\[\]]//sg; $_}
            grep length, map split(/\s+/), @lines
        ];
        # Can this projection do inverse?
        $hash->{INVERSE} = ( $description =~ /no inv/ ) ? 0 : 1;
        $info->{$projection} = $hash;
    }
    # A couple of overrides:
    #
    $info->{ob_tran}{PARAMS}{PROJ} =
        [ 'o_proj', 'o_lat_p', 'o_lon_p', 'o_alpha', 'o_lon_c', 
          'o_lat_c', 'o_lon_1', 'o_lat_1', 'o_lon_2', 'o_lat_2' ];
    $info->{nzmg}{CATEGORIES} = [ 'fixed Earth' ];
    return $info;
} # End of load_projection_information()...

#line 32 "Proj.pd"
=head1 AUTHOR

Judd Taylor, Orbital Systems, Ltd.
judd dot t at orbitalsystems dot com

=head1 COPYRIGHT NOTICE

Copyright 2003 Judd Taylor, USF Institute for Marine Remote Sensing (judd@marine.usf.edu).

GPL Now!

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
#line 215 "Proj.pm"

# Exit with OK status

1;
