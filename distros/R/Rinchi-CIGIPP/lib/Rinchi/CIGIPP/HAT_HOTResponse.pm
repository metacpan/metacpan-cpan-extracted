#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b1b62-200e-11de-bdc7-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::HAT_HOTResponse;

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

our $VERSION = '0.02';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::HAT_HOTResponse - Perl extension for the Common Image Generator 
Interface - HAT/HOTResponse data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::HAT_HOTResponse;
  my $hgt_resp = Rinchi::CIGIPP::HAT_HOTResponse->new();

  $packet_type = $hgt_resp->packet_type();
  $packet_size = $hgt_resp->packet_size();
  $response_ident = $hgt_resp->response_ident(47273);
  $host_frame_number_lsn = $hgt_resp->host_frame_number_lsn(13);
  $response_type = $hgt_resp->response_type(Rinchi::CIGIPP->HeightAboveTerrain);
  $valid = $hgt_resp->valid(Rinchi::CIGIPP->Invalid);
  $height = $hgt_resp->height(51.413);

=head1 DESCRIPTION

The HAT/HOT Response packet is sent by the IG in response to a HAT/HOT Request 
packet whose Request Type attribute was set to HAT (0) or HOT (1). This packet 
provides either the Height Above Terrain (HAT) or Height Of Terrain (HOT) for 
the test point. This packet does not contain the material code or surface 
normal of the terrain.

If the Update Period attribute of the originating HAT/HOT Request packet was 
set to a value greater than zero, then the Host Frame Number LSN attribute of 
each corresponding HAT/HOT Response packet must contain the least significant 
nybble of the Host Frame Number value last received by the IG before the HAT or 
HOT value is calculated. The Host may correlate this LSN to an eyepoint 
position or may use the value to determine latency.

The IG can only return the HAT or HOT for a point that is within the bounds of 
the current database. If the HAT or HOT cannot be returned, the Valid attribute 
will be set to Invalid (0).

=head2 EXPORT

None by default.

#==============================================================================

=item new $hgt_resp = Rinchi::CIGIPP::HAT_HOTResponse->new()

Constructor for Rinchi::HAT_HOTResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b1b62-200e-11de-bdc7-001c25551abc',
    '_Pack'                                => 'CCSCCSd',
    '_Swap1'                               => 'CCvCCvVV',
    '_Swap2'                               => 'CCnCCnNN',
    'packetType'                           => 102,
    'packetSize'                           => 16,
    '_responseIdent'                       => 0,
    '_bitfields1'                          => 0, # Includes bitfields hostFrameNumberLSN, responseType, and valid.
    'hostFrameNumberLSN'                   => 0,
    'responseType'                         => 0,
    'valid'                                => 0,
    '_unused67'                            => 0,
    '_unused68'                            => 0,
    'height'                               => 0,
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

 $value = $hgt_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the HAT/HOT Response packet. The 
value of this attribute must be 102.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $hgt_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub response_ident([$newValue])

 $value = $hgt_resp->response_ident($newValue);

HAT/HOT ID.

This attribute identifies the HAT/HOT response. This value corresponds to the 
value of the HAT/HOT ID attribute in the associated HAT/HOT Request packet.

=cut

sub response_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'_responseIdent'} = $nv;
  }
  return $self->{'_responseIdent'};
}

#==============================================================================

=item sub host_frame_number_lsn([$newValue])

 $value = $hgt_resp->host_frame_number_lsn($newValue);

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

=item sub response_type([$newValue])

 $value = $hgt_resp->response_type($newValue);

Response Type.

This attribute indicates whether the Height attribute represents Height Above 
Terrain or Height Of Terrain.

    HeightAboveTerrain   0
    HeightOfTerrain      1

=cut

sub response_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'responseType'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "response_type must be 0 (HeightAboveTerrain), or 1 (HeightOfTerrain).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub valid([$newValue])

 $value = $hgt_resp->valid($newValue);

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

=item sub height([$newValue])

 $value = $hgt_resp->height($newValue);

Height.

This attribute contains the requested height. If Request Type is set to HAT 
(0), this value represents the Height Above Terrain. If Request Type is set to 
HOT (1), this value represents the Height Of Terrain.

This attribute is valid only if the Valid attribute is set to one (1).

=cut

sub height() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'height'} = $nv;
  }
  return $self->{'height'};
}

#==========================================================================

=item sub pack()

 $value = $hgt_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'_responseIdent'},
        $self->{'_bitfields1'},    # Includes bitfields hostFrameNumberLSN, unused66, responseType, and valid.
        $self->{'_unused67'},
        $self->{'_unused68'},
        $self->{'height'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $hgt_resp->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'_responseIdent'}                      = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields hostFrameNumberLSN, unused66, responseType, and valid.
  $self->{'_unused67'}                           = $e;
  $self->{'_unused68'}                           = $f;
  $self->{'height'}                              = $g;

  $self->{'hostFrameNumberLSN'}                  = $self->host_frame_number_lsn();
  $self->{'responseType'}                        = $self->response_type();
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
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$h,$g);
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
