#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b35f2-200e-11de-bdd1-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse;

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

Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse - Perl extension for the 
Common Image Generator Interface - Maritime Surface Conditions Response data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse;
  my $msc_resp = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new();

  $packet_type = $msc_resp->packet_type();
  $packet_size = $msc_resp->packet_size();
  $request_ident = $msc_resp->request_ident(122);
  $sea_surface_height = $msc_resp->sea_surface_height(9.874);
  $surface_water_temperature = $msc_resp->surface_water_temperature(82.083);
  $surface_clarity = $msc_resp->surface_clarity(8.774);

=head1 DESCRIPTION

The Maritime Surface Conditions Response packet is sent in response to an 
Environmental Conditions Request packet whose Request Type attribute specifies 
Maritime Surface Conditions. The packet describes the sea surface state at the 
requested geodetic latitude and longitude.

=head2 EXPORT

None by default.

#==============================================================================

=item new $msc_resp = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new()

Constructor for Rinchi::MaritimeSurfaceConditionsResponse.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b35f2-200e-11de-bdd1-001c25551abc',
    '_Pack'                                => 'CCCCfff',
    '_Swap1'                               => 'CCCCVVV',
    '_Swap2'                               => 'CCCCNNN',
    'packetType'                           => 111,
    'packetSize'                           => 16,
    'requestIdent'                         => 0,
    '_unused81'                            => 0,
    'seaSurfaceHeight'                     => 0,
    'surfaceWaterTemperature'              => 0,
    'surfaceClarity'                       => 0,
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

 $value = $msc_resp->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Maritime Surface Conditions 
Response packet. The value of this attribute must be 111.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $msc_resp->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub request_ident([$newValue])

 $value = $msc_resp->request_ident($newValue);

Request ID.

This attribute identifies the environmental conditions request to which this 
response packet corresponds.

=cut

sub request_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'requestIdent'} = $nv;
  }
  return $self->{'requestIdent'};
}

#==============================================================================

=item sub sea_surface_height([$newValue])

 $value = $msc_resp->sea_surface_height($newValue);

Sea Surface Height.

This attribute indicates the height of the sea surface at equilibrium (i.e., 
without waves).

Note that the instantaneous elevation of the water including wave displacement 
may be determined from a Height Of Terrain request.

=cut

sub sea_surface_height() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'seaSurfaceHeight'} = $nv;
  }
  return $self->{'seaSurfaceHeight'};
}

#==============================================================================

=item sub surface_water_temperature([$newValue])

 $value = $msc_resp->surface_water_temperature($newValue);

Surface Water Temperature

This attribute indicates the water temperature at the sea surface.

=cut

sub surface_water_temperature() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceWaterTemperature'} = $nv;
  }
  return $self->{'surfaceWaterTemperature'};
}

#==============================================================================

=item sub surface_clarity([$newValue])

 $value = $msc_resp->surface_clarity($newValue);

Surface Clarity.

This attribute indicates the clarity of the water at its surface. A value of 
100% indicates pristine water, while a value of 0% indicates extremely turbid water.

=cut

sub surface_clarity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceClarity'} = $nv;
  }
  return $self->{'surfaceClarity'};
}

#==========================================================================

=item sub pack()

 $value = $msc_resp->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'requestIdent'},
        $self->{'_unused81'},
        $self->{'seaSurfaceHeight'},
        $self->{'surfaceWaterTemperature'},
        $self->{'surfaceClarity'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $msc_resp->unpack();

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
  $self->{'requestIdent'}                        = $c;
  $self->{'_unused81'}                           = $d;
  $self->{'seaSurfaceHeight'}                    = $e;
  $self->{'surfaceWaterTemperature'}             = $f;
  $self->{'surfaceClarity'}                      = $g;

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
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g);
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
