#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78aca54-200e-11de-bda9-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::CelestialSphereControl;

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

Rinchi::CIGIPP::CelestialSphereControl - Perl extension for the Common Image 
Generator Interface - Celestial Sphere Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::CelestialSphereControl;
  my $sky_ctl = Rinchi::CIGIPP::CelestialSphereControl->new();

  $packet_type = $sky_ctl->packet_type();
  $packet_size = $sky_ctl->packet_size();
  $hour = $sky_ctl->hour(123);
  $minute = $sky_ctl->minute(7);
  $date_time_valid = $sky_ctl->date_time_valid(Rinchi::CIGIPP->Invalid);
  $star_field_enable = $sky_ctl->star_field_enable(Rinchi::CIGIPP->Disable);
  $moon_enable = $sky_ctl->moon_enable(Rinchi::CIGIPP->Disable);
  $sun_enable = $sky_ctl->sun_enable(Rinchi::CIGIPP->Disable);
  $ephemeris_model_enable = $sky_ctl->ephemeris_model_enable(Rinchi::CIGIPP->Enable);
  $date = $sky_ctl->date(5486);
  $star_field_intensity = $sky_ctl->star_field_intensity(29.575);

=head1 DESCRIPTION

The Celestial Sphere Control data packet allows the Host to specify properties 
of the sky model.

The Date attribute specifies the current date and the Hour and Minute 
attributes specify the current time of day. The IG uses these attributes to 
determine ambient light properties, sun and moon positions (and corresponding 
directional light positions), moon phase, and horizon glow.

An IG typically uses an ephemeris model to continuously update the time of day. 
A Celestial Sphere Control packet need not be sent each minute for the sole 
purpose of updating the time of day unless the Host has disabled the ephemeris 
model with the Ephemeris Model Enable flag.

Note: If the Host freezes the simulation, it must send a Celestial Sphere 
Control packet with the Ephemeris Model Enable attribute set to Disable (0); 
otherwise, the IG will continue to update the time of day. When the Host 
resumes the simulation, it must explicitly re-enable the ephemeris model.

The Date/Time Valid attribute specifies whether the IG should set the current 
date and time to the values specified by the Hour, Minute, and Date attributes. 
This enables the Host to change sky model properties without affecting the 
ephemeris model.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sky_ctl = Rinchi::CIGIPP::CelestialSphereControl->new()

Constructor for Rinchi::CelestialSphereControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78aca54-200e-11de-bda9-001c25551abc',
    '_Pack'                                => 'CCCCCCSIf',
    '_Swap1'                               => 'CCCCCCvVV',
    '_Swap2'                               => 'CCCCCCnNN',
    'packetType'                           => 9,
    'packetSize'                           => 16,
    'hour'                                 => 0,
    'minute'                               => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused12, dateTimeValid, starFieldEnable, moonEnable, sunEnable, and ephemerisModelEnable.
    'dateTimeValid'                        => 0,
    'starFieldEnable'                      => 0,
    'moonEnable'                           => 0,
    'sunEnable'                            => 0,
    'ephemerisModelEnable'                 => 0,
    '_unused13'                            => 0,
    '_unused14'                            => 0,
    'date'                                 => 0,
    'starFieldIntensity'                   => 0,
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

 $value = $sky_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Celestial Sphere Control 
packet. The value of this attribute must be 9.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sky_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub hour([$newValue])

 $value = $sky_ctl->hour($newValue);

Hour.

This attribute specifies the current hour of the day within the simulation.

=cut

sub hour() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'hour'} = $nv;
  }
  return $self->{'hour'};
}

#==============================================================================

=item sub minute([$newValue])

 $value = $sky_ctl->minute($newValue);

Minute.

This attribute specifies the current minute of the day within the simulation.

=cut

sub minute() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'minute'} = $nv;
  }
  return $self->{'minute'};
}

#==============================================================================

=item sub date_time_valid([$newValue])

 $value = $sky_ctl->date_time_valid($newValue);

Date/Time Valid.

This attribute specifies whether the Hour, Minute, and Date attributes are 
valid. If Date/Time Valid is set to Valid (1), these values will override the 
IG's current date and time.

    Invalid   0
    Valid     1

=cut

sub date_time_valid() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'dateTimeValid'}                       = $nv;
      $self->{'starFieldEnable'}                     = $nv;
      $self->{'moonEnable'}                          = $nv;
      $self->{'sunEnable'}                           = $nv;
      $self->{'ephemerisModelEnable'}                = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "date_time_valid must be 0 (Invalid), or 1 (Valid).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub star_field_enable([$newValue])

 $value = $sky_ctl->star_field_enable($newValue);

Star Field Enable.

This attribute specifies whether the star attribute is enabled in the sky 
model. The star positions are determined by the current date and time.

    Disable   0
    Enable    1

=cut

sub star_field_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "star_field_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub moon_enable([$newValue])

 $value = $sky_ctl->moon_enable($newValue);

Moon Enable.

This attribute specifies whether the moon is enabled in the sky model. The moon 
phase is determined by the current date.

    Disable   0
    Enable    1

=cut

sub moon_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "moon_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub sun_enable([$newValue])

 $value = $sky_ctl->sun_enable($newValue);

Sun Enable.

This attribute specifies whether the sun is enabled in the sky model.

    Disable   0
    Enable    1

=cut

sub sun_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "sun_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub ephemeris_model_enable([$newValue])

 $value = $sky_ctl->ephemeris_model_enable($newValue);

Ephemeris Model Enable.

This attribute controls whether the time of day is static or continuous. If 
this attribute is set to Enabled (1), the image generator will continuously 
update the time of day.

    Disable   0
    Enable    1

=cut

sub ephemeris_model_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "ephemeris_model_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub date([$newValue])

 $value = $sky_ctl->date($newValue);

Date.

This attribute specifies the current date within the simulation. The date is 
represented as a seven- or eight-digit decimal integer formatted as follows: 
MMDDYYYY = (month × 1000000) + (day × 10000) + year.

=cut

sub date() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'date'} = $nv;
  }
  return $self->{'date'};
}

#==============================================================================

=item sub star_field_intensity([$newValue])

 $value = $sky_ctl->star_field_intensity($newValue);

Star Field Intensity.

This attribute specifies the intensity of the star attribute within the sky 
model. This attribute is ignored if Star Field Enable is set to Disable (0).

=cut

sub star_field_intensity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'starFieldIntensity'} = $nv;
  }
  return $self->{'starFieldIntensity'};
}

#==========================================================================

=item sub pack()

 $value = $sky_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'hour'},
        $self->{'minute'},
        $self->{'_bitfields1'},    # Includes bitfields unused12, dateTimeValid, starFieldEnable, moonEnable, sunEnable, and ephemerisModelEnable.
        $self->{'_unused13'},
        $self->{'_unused14'},
        $self->{'date'},
        $self->{'starFieldIntensity'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sky_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'hour'}                                = $c;
  $self->{'minute'}                              = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused12, dateTimeValid, starFieldEnable, moonEnable, sunEnable, and ephemerisModelEnable.
  $self->{'_unused13'}                           = $f;
  $self->{'_unused14'}                           = $g;
  $self->{'date'}                                = $h;
  $self->{'starFieldIntensity'}                  = $i;

  $self->{'dateTimeValid'}                       = $self->date_time_valid();
  $self->{'starFieldEnable'}                     = $self->star_field_enable();
  $self->{'moonEnable'}                          = $self->moon_enable();
  $self->{'sunEnable'}                           = $self->sun_enable();
  $self->{'ephemerisModelEnable'}                = $self->ephemeris_model_enable();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i);
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
