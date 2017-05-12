#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ad832-200e-11de-bdae-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::WaveControl;

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

Rinchi::CIGIPP::WaveControl - Perl extension for the Common Image Generator 
Interface - Wave Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::WaveControl;
  my $wave_ctl = Rinchi::CIGIPP::WaveControl->new();

  $packet_type = $wave_ctl->packet_type();
  $packet_size = $wave_ctl->packet_size();
  $region_ident = $wave_ctl->region_ident(57556);
  $entity_ident = $wave_ctl->entity_ident(19952);
  $wave_ident = $wave_ctl->wave_ident(240);
  $breaker_type = $wave_ctl->breaker_type(Rinchi::CIGIPP->Plunging);
  $scope = $wave_ctl->scope(Rinchi::CIGIPP->GlobalScope);
  $wave_enable = $wave_ctl->wave_enable(Rinchi::CIGIPP->Enable);
  $wave_height = $wave_ctl->wave_height(83.07);
  $wave_length = $wave_ctl->wave_length(12.084);
  $period = $wave_ctl->period(54.785);
  $direction = $wave_ctl->direction(24.212);
  $phase_offset = $wave_ctl->phase_offset(69.289);
  $leading = $wave_ctl->leading(26.815);

=head1 DESCRIPTION

The Wave Control packet is used to specify the behavior of waves propagating 
across the surface of a body of water. Examples include simulated swells and 
wind chop.

The basic waveform is defined by a wave height, wavelength, period, and 
direction of propagation. Wave height refers to the vertical distance between 
the wave's crest and trough. The wavelength is the distance from one crest to 
the next or from one trough to the next. 

The Phase Offset attribute specifies a phase angle to be added to the IG's 
reference phase. This is useful for modeling the interference patterns produced 
within a multiple-wave system. The Leading attribute determines the 
cross-sectional shape of the wave. This value is the phase angle at which the 
crest of the wave occurs. For a sinusoidal wave, this angle is zero (0) 
degrees. As the value increases, the trough flattens and the crest moves toward 
the front of the wave.

=head2 EXPORT

None by default.

#==============================================================================

=item new $wave_ctl = Rinchi::CIGIPP::WaveControl->new()

Constructor for Rinchi::WaveControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ad832-200e-11de-bdae-001c25551abc',
    '_Pack'                                => 'CCSCCSffffff',
    '_Swap1'                               => 'CCvCCvVVVVVV',
    '_Swap2'                               => 'CCnCCnNNNNNN',
    'packetType'                           => 14,
    'packetSize'                           => 32,
    'region_entityIdent'                   => 0,
    'waveIdent'                            => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused26, breakerType, scope, and waveEnable.
    'breakerType'                          => 0,
    'scope'                                => 0,
    'waveEnable'                           => 0,
    '_unused27'                            => 0,
    'waveHeight'                           => 0,
    'waveLength'                           => 0,
    'period'                               => 0,
    'direction'                            => 0,
    'phaseOffset'                          => 0,
    'leading'                              => 0,
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

 $value = $wave_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Wave Control packet. The 
value of this attribute must be 14.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $wave_ctl->packet_size();

Data Packet Size. This attribute indicates the number of bytes in this data 
packet. The value of this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub region_ident([$newValue])

 $value = $wave_ctl->region_ident($newValue);

Entity ID. (Entity-based Surface Conditions)

This attribute specifies the entity to which the surface attributes in this 
packet are applied.



=cut

sub region_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'region_entityIdent'} = $nv;
  }
  return $self->{'region_entityIdent'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $wave_ctl->entity_ident($newValue);

Region ID. (Regional Surface Conditions)

This attribute specifies the region to which the surface attributes are 
confined.
Note: Entity ID/Region ID is ignored if Scope is set to Global (0).

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'region_entityIdent'} = $nv;
  }
  return $self->{'region_entityIdent'};
}

#==============================================================================

=item sub wave_ident([$newValue])

 $value = $wave_ctl->wave_ident($newValue);

Wave ID.

This attribute specifies the wave to which the attributes in this packet are applied.

=cut

sub wave_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'waveIdent'} = $nv;
  }
  return $self->{'waveIdent'};
}

#==============================================================================

=item sub breaker_type([$newValue])

 $value = $wave_ctl->breaker_type($newValue);

Breaker Type.

This attribute specifies the type of breaker within the surf zone. This may be 
one of the following values:

Plunging - Plunging waves peak until the wave forms a vertical wall, at which 
point the crest moves faster than the base of the breaker. The wave will then 
break violently into the wave trough.

Spilling - Spilling breakers break gradually over a great distance. White water 
forms over the crest, which spills down the face of the breaker.

Surging - Surging breakers advance toward the beach as vertical walls of water. 
Unlike with plunging and spilling breakers, the crest does not fall over the 
front of the wave.

    Plunging   0
    Spilling   1
    Surging    2

=cut

sub breaker_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'breakerType'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x18;
    } else {
      carp "breaker_type must be 0 (Plunging), 1 (Spilling), or 2 (Surging).";
    }
  }
  return (($self->{'_bitfields1'} & 0x18) >> 3);
}

#==============================================================================

=item sub scope([$newValue])

 $value = $wave_ctl->scope($newValue);

Scope.

This attribute specifies whether the wave is defined for global, regional, or 
entity-controlled maritime surface conditions. If this value is set to Regional 
(1), the wave properties are applied only within the region specified by Region 
ID. If this value is set to Entity (2), the properties are applied to the area 
defined by the moving model specified by Entity ID.

    GlobalScope     0
    RegionalScope   1
    EntityScope     2

=cut

sub scope() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'scope'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x06;
    } else {
      carp "scope must be 0 (GlobalScope), 1 (RegionalScope), or 2 (EntityScope).";
    }
  }
  return (($self->{'_bitfields1'} & 0x06) >> 1);
}

#==============================================================================

=item sub wave_enable([$newValue])

 $value = $wave_ctl->wave_enable($newValue);

Wave Enable.

This attribute determines whether the wave is enabled or disabled. A disabled 
wave does not contribute to the shape of the water's surface.

    Disable   0
    Enable    1

=cut

sub wave_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'waveEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "wave_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub wave_height([$newValue])

 $value = $wave_ctl->wave_height($newValue);

Wave Height.

This attribute specifies the average vertical distance measured in meters from 
trough to crest produced by the wave. Wave Height is centered on Sea Surface Height.

=cut

sub wave_height() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'waveHeight'} = $nv;
  }
  return $self->{'waveHeight'};
}

#==============================================================================

=item sub wave_length([$newValue])

 $value = $wave_ctl->wave_length($newValue);

Wavelength.

This attribute specifies the distance from a particular phase on a wave to the 
same phase on an adjacent wave.

=cut

sub wave_length() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'waveLength'} = $nv;
  }
  return $self->{'waveLength'};
}

#==============================================================================

=item sub period([$newValue])

 $value = $wave_ctl->period($newValue);

Period.

This attribute specifies the time required for one complete oscillation of the wave.

=cut

sub period() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'period'} = $nv;
  }
  return $self->{'period'};
}

#==============================================================================

=item sub direction([$newValue])

 $value = $wave_ctl->direction($newValue);

Direction.

This attribute specifies the direction in which the wave propagates measured in 
degrees from true north.

=cut

sub direction() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'direction'} = $nv;
  }
  return $self->{'direction'};
}

#==============================================================================

=item sub phase_offset([$newValue])

 $value = $wave_ctl->phase_offset($newValue);

Phase Offset.

This attribute specifies a phase offset for the wave.

=cut

sub phase_offset() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'phaseOffset'} = $nv;
  }
  return $self->{'phaseOffset'};
}

#==============================================================================

=item sub leading([$newValue])

 $value = $wave_ctl->leading($newValue);

Leading.This attribute specifies the phase angle at which the crest occurs.

=cut

sub leading() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'leading'} = $nv;
  }
  return $self->{'leading'};
}

#==========================================================================

=item sub pack()

 $value = $wave_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'region_entityIdent'},
        $self->{'waveIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused26, breakerType, scope, and waveEnable.
        $self->{'_unused27'},
        $self->{'waveHeight'},
        $self->{'waveLength'},
        $self->{'period'},
        $self->{'direction'},
        $self->{'phaseOffset'},
        $self->{'leading'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $wave_ctl->unpack();

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
  $self->{'region_entityIdent'}                  = $c;
  $self->{'waveIdent'}                           = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused26, breakerType, scope, and waveEnable.
  $self->{'_unused27'}                           = $f;
  $self->{'waveHeight'}                          = $g;
  $self->{'waveLength'}                          = $h;
  $self->{'period'}                              = $i;
  $self->{'direction'}                           = $j;
  $self->{'phaseOffset'}                         = $k;
  $self->{'leading'}                             = $l;

  $self->{'breakerType'}                         = $self->breaker_type();
  $self->{'scope'}                               = $self->scope();
  $self->{'waveEnable'}                          = $self->wave_enable();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l);
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
