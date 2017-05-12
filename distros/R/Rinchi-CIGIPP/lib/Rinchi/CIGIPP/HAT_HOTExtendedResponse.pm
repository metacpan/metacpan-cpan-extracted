#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b1e14-200e-11de-bdc8-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::HAT_HOTExtendedResponse;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGI::AtmosphereControl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::HAT_HOTExtendedResponse - Perl extension for the Common Image 
Generator Interface - HAT/HOTExtended Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::HAT_HOTExtendedResponse;
  my $hgt_xresp = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new();

  $packet_type = $hgt_xresp->packet_type();
  $packet_size = $hgt_xresp->packet_size();
  $response_ident = $hgt_xresp->response_ident(56733);
  $host_frame_number_lsn = $hgt_xresp->host_frame_number_lsn(4);
  $valid = $hgt_xresp->valid(Rinchi::CIGIPP->Invalid);
  $height_above_terrain = $hgt_xresp->height_above_terrain(86.966);
  $height_of_terrain = $hgt_xresp->height_of_terrain(74.029);
  $material_code = $hgt_xresp->material_code(53788);
  $normal_vector_azimuth = $hgt_xresp->normal_vector_azimuth(3.08);
  $normal_vector_elevation = $hgt_xresp->normal_vector_elevation(82.952);

=head1 DESCRIPTION

The HAT/HOT Extended Response packet is sent by the IG in response to a HAT/HOT 
Request packet whose Request Type attribute was set to Extended (2). This 
packet provides the Height Above Terrain (HAT) and Height Of Terrain (HOT) for 
the test point. This packet also contains the material code and surface-normal 
unit vector of the terrain.

If the Update Period attribute of the originating HAT/HOT Request packet was 
set to a value greater than zero, then the Host Frame Number LSN attribute of 
each corresponding HAT/HOT Response packet must contain the least significant 
nybble of the Host Frame Number value last received by the IG before the HAT or 
HOT value is calculated. The Host may correlate this LSN to an eyepoint 
position or may use the value to determine latency.

The IG can only return the HAT and HOT for a point that is within the bounds of 
the current database. Likewise, the material code and normal vector can only be 
calculated within the database bounds. If these data cannot be returned, the 
Valid attribute will be set to zero (0).

=head2 EXPORT

None by default.

#==============================================================================

=item new $hgt_xresp = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new()

Constructor for Rinchi::HAT_HOTExtendedResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b1e14-200e-11de-bdc8-001c25551abc',
    '_Pack'                                => 'CCSCCSddIffI',
    '_Swap1'                               => 'CCvCCvVVVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNNNN',
    'packetType'                           => 103,
    'packetSize'                           => 40,
    'responseIdent'                        => 0,
    '_bitfields1'                          => 0, # Includes bitfields hostFrameNumberLSN, unused69, and valid.
    'hostFrameNumberLSN'                   => 0,
    'valid'                                => 0,
    '_unused70'                            => 0,
    '_unused71'                            => 0,
    'heightAboveTerrain'                   => 0,
    'heightOfTerrain'                      => 0,
    'materialCode'                         => 0,
    'normalVectorAzimuth'                  => 0,
    'normalVectorElevation'                => 0,
    '_unused72'                            => 0,
  };

  if (@_) {
    if (ref($_[0]) eq 'ARRAY') {
      $self->{'_Buffer'} = $_[0][0];
    } elsif (ref($_[0]) eq 'HASH') {
      foreach my $attr (keys %{$_[0]}) {
        $self->{"_$attr"} = $_[0]->{$attr} unless ($attr =~ /^_/);
      }
    }        
  }

  bless($self,$class);
  return $self;
}

#==============================================================================

=item sub packet_type()

 $value = $hgt_xresp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the HAT/HOT Extended Response 
packet. The value of this attribute must be 103.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $hgt_xresp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 40.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub response_ident([$newValue])

 $value = $hgt_xresp->response_ident($newValue);

HAT/HOT ID.

This attribute identifies the HAT/HOT response. This value corresponds to the 
value of the HAT/HOT ID attribute in the associated HAT/HOT Request packet.

=cut

sub response_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'responseIdent'} = $nv;
  }
  return $self->{'responseIdent'};
}

#==============================================================================

=item sub host_frame_number_lsn([$newValue])

 $value = $hgt_xresp->host_frame_number_lsn($newValue);

Host Frame Number LSN.

This attribute contains the least significant nybble of the Host Frame Number 
attribute of the last IG Control packet received before the HAT or HOT is 
calculated.                                                

This attribute is ignored if the Update Period attribute of the corresponding 
HAT/HOT Request packet was set to zero (0).

=cut

sub host_frame_number_lsn() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'hostFrameNumberLSN'} = $nv;
    $self->{'_bitfields1'} |= ($nv << 4) &0xF0;
  }
  return (($self->{'_bitfields1'} & 0xF0) >> 4);
}

#==============================================================================

=item sub valid([$newValue])

 $value = $hgt_xresp->valid($newValue);

Valid.

This attribute indicates whether the remaining attributes in this packet 
contain valid numbers. A value of zero (0) indicates that the test point was 
beyond the database bounds.

    Invalid   0
    Valid     1

=cut

sub valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'valid'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub height_above_terrain([$newValue])

 $value = $hgt_xresp->height_above_terrain($newValue);

Height Above Terrain (HAT).

This attribute indicates the height of the test point above the terrain. A 
negative value indicates that the test point is below the terrain.

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub height_above_terrain() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'heightAboveTerrain'} = $nv;
  }
  return $self->{'heightAboveTerrain'};
}

#==============================================================================

=item sub height_of_terrain([$newValue])

 $value = $hgt_xresp->height_of_terrain($newValue);

Height Of Terrain (HOT).

This attribute indicates the height of terrain above or below the test point. 
This value is relative to the ellipsoid height, or Mean Sea Level. 

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub height_of_terrain() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'heightOfTerrain'} = $nv;
  }
  return $self->{'heightOfTerrain'};
}

#==============================================================================

=item sub material_code([$newValue])

 $value = $hgt_xresp->material_code($newValue);

Material Code.

This attribute indicates the material code of the terrain surface at the point 
of intersection with the HAT/HOT test vector.

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub material_code() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'materialCode'} = $nv;
  }
  return $self->{'materialCode'};
}

#==============================================================================

=item sub normal_vector_azimuth([$newValue])

 $value = $hgt_xresp->normal_vector_azimuth($newValue);

Normal Vector Azimuth.

This attribute indicates the azimuth of the normal unit vector of the surface 
intersected by the HAT/HOT test vector. This value is the horizontal angle from 
True North to the vector.

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub normal_vector_azimuth() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'normalVectorAzimuth'} = $nv;
  }
  return $self->{'normalVectorAzimuth'};
}

#==============================================================================

=item sub normal_vector_elevation([$newValue])

 $value = $hgt_xresp->normal_vector_elevation($newValue);

Normal Vector Elevation.

This attribute indicates the elevation of the normal unit vector of the surface 
intersected by the HAT/HOT test vector. This value is the vertical angle from 
the geodetic reference plane to the vector.

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub normal_vector_elevation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'normalVectorElevation'} = $nv;
  }
  return $self->{'normalVectorElevation'};
}

#==========================================================================

=item sub pack()

 $value = $hgt_xresp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'responseIdent'},
        $self->{'_bitfields1'},    # Includes bitfields hostFrameNumberLSN, unused69, and valid.
        $self->{'_unused70'},
        $self->{'_unused71'},
        $self->{'heightAboveTerrain'},
        $self->{'heightOfTerrain'},
        $self->{'materialCode'},
        $self->{'normalVectorAzimuth'},
        $self->{'normalVectorElevation'},
        $self->{'_unused72'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $hgt_xresp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'responseIdent'}                       = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields hostFrameNumberLSN, unused69, and valid.
  $self->{'_unused70'}                           = $e;
  $self->{'_unused71'}                           = $f;
  $self->{'heightAboveTerrain'}                  = $g;
  $self->{'heightOfTerrain'}                     = $h;
  $self->{'materialCode'}                        = $i;
  $self->{'normalVectorAzimuth'}                 = $j;
  $self->{'normalVectorElevation'}               = $k;
  $self->{'_unused72'}                           = $l;

  $self->{'hostFrameNumberLSN'}                  = $self->host_frame_number_lsn();
  $self->{'valid'}                               = $self->valid();

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $obj_name->byte_swap();

Byte swaps the packed data packet.

=cut

sub byte_swap($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  } else {
     $self->pack();
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g,$j,$i,$k,$l,$m,$n);
  $self->unpack();

  return $self->{'_Buffer'};
}

1;
__END__

=head1 SEE ALSO

Refer the the Common Image Generator Interface ICD which may be had at this URL:
L<http://cigi.sourceforge.net/specification.php>

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
