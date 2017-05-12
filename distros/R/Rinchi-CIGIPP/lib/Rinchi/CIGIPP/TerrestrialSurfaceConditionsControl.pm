#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78adada-200e-11de-bdaf-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl;

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

Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl - Perl extension for the 
Common Image Generator Interface - Terrestrial Surface Conditions Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl;
  my $tsc_ctl = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new();

  $packet_type = $tsc_ctl->packet_type();
  $packet_size = $tsc_ctl->packet_size();
  $region_ident = $tsc_ctl->region_ident(32124);
  $entity_ident = $tsc_ctl->entity_ident(34318);
  $surface_condition_ident = $tsc_ctl->surface_condition_ident(62625);
  $severity = $tsc_ctl->severity(15);
  $scope = $tsc_ctl->scope(Rinchi::CIGIPP->RegionalScope);
  $surface_condition_enable = $tsc_ctl->surface_condition_enable(Rinchi::CIGIPP->Disable);
  $coverage = $tsc_ctl->coverage(174);

=head1 DESCRIPTION

The Terrestrial Surface Conditions Control packet is used to specify the 
conditions of the terrain surface. These typically describe driving conditions, 
runway contaminants, or conditions that would otherwise impede or add risk to 
the movement of vehicles on the ground.

The possible surface conditions are IG-dependent. Examples might range from 
weather-related conditions such as dry, wet, icy, or slushy, to hazards such as 
sand, dirt, and gravel.

Regional terrestrial surface conditions always take precedence over the global 
surface conditions. Once the surface conditions of a region are set, global 
changes will not affect the surface conditions within that region unless it is 
disabled. Global changes will, however, change the conditions within a region's 
transition perimeter.

If two or more regions overlap, the value of each surface condition attribute 
within the area of overlap should be the average of the values determined by 
the overlapping regions.

To determine the terrestrial surface conditions within areas of overlap or 
through a transition perimeter, the Host can request the conditions at a 
specific latitude and longitude by issuing an Environmental Conditions Request packet.

=head2 EXPORT

None by default.

#==============================================================================

=item new $tsc_ctl = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new()

Constructor for Rinchi::TerrestrialSurfaceConditionsControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78adada-200e-11de-bdaf-001c25551abc',
    '_Pack'                                => 'CCSSCC',
    '_Swap1'                               => 'CCvvCC',
    '_Swap2'                               => 'CCnnCC',
    'packetType'                           => 15,
    'packetSize'                           => 8,
    'region_entityIdent'                   => 0,
    'surfaceConditionIdent'                => 0,
    '_bitfields1'                          => 0, # Includes bitfields severity, scope, and surfaceConditionEnable.
    'severity'                             => 0,
    'scope'                                => 0,
    'surfaceConditionEnable'               => 0,
    'coverage'                             => 0,
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

 $value = $tsc_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Terrestrial Surface 
Conditions Control packet. The value of this attribute must be 15.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $tsc_ctl->packet_size();

Data Packet Size. This attribute indicates the number of bytes in this data 
packet. The value of this attribute must be 8.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub region_ident([$newValue])

 $value = $tsc_ctl->region_ident($newValue);

Region ID.

This attribute specifies the region to which the surface conditions are confined.

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

 $value = $tsc_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the environmental entity to which the surface 
condition attributes in this packet are applied.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'region_entityIdent'} = $nv;
  }
  return $self->{'region_entityIdent'};
}

#==============================================================================

=item sub surface_condition_ident([$newValue])

 $value = $tsc_ctl->surface_condition_ident($newValue);

Surface Condition ID.

This attribute identifies a surface condition or contaminant. Multiple 
conditions can be specified by sending multiple Terrestrial Surface Conditions 
Control packets.When this attribute is set to Dry (0), all existing surface 
conditions will be removed within the specified scope. All other surface 
condition codes are IG-dependent.

=cut

sub surface_condition_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceConditionIdent'} = $nv;
  }
  return $self->{'surfaceConditionIdent'};
}

#==============================================================================

=item sub severity([$newValue])

 $value = $tsc_ctl->severity($newValue);

Severity.

This attribute determines the degree of severity for the specified surface 
contaminant(s). A value of zero (0) indicates that any effects of the 
contaminant are negligible. A value of 31 indicates that the surface is impassable.

=cut

sub severity() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0 and $nv<=31 and int($nv)==$nv) {
      $self->{'severity'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0xF8;
    } else {
      carp "severity must be an integer 0-31.";
    }
  }
  return (($self->{'_bitfields1'} & 0xF8) >> 3);
}

#==============================================================================

=item sub scope([$newValue])

 $value = $tsc_ctl->scope($newValue);

Scope.

This attribute determines whether the specified surface conditions are applied 
globally, regionally, or to an environmental entity. If this value is set to 
Regional (1), the conditions are confined to the region specified by Region ID. 
If this value is set to Entity (2), the conditions are applied to the model 
specified by Entity ID.

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

=item sub surface_condition_enable([$newValue])

 $value = $tsc_ctl->surface_condition_enable($newValue);

Surface Condition Enable.

This attribute specifies whether the surface condition attribute identified by 
the Surface Condition ID attribute should be enabled.

    Disable   0
    Enable    1

=cut

sub surface_condition_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'surfaceConditionEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "surface_condition_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub coverage([$newValue])

 $value = $tsc_ctl->coverage($newValue);

Coverage.

This attribute determines the degree of coverage of the specified surface contaminant.

=cut

sub coverage() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'coverage'} = $nv;
  }
  return $self->{'coverage'};
}

#==========================================================================

=item sub pack()

 $value = $tsc_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'region_entityIdent'},
        $self->{'surfaceConditionIdent'},
        $self->{'_bitfields1'},    # Includes bitfields severity, scope, and surfaceConditionEnable.
        $self->{'coverage'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $tsc_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'region_entityIdent'}                  = $c;
  $self->{'surfaceConditionIdent'}               = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields severity, scope, and surfaceConditionEnable.
  $self->{'coverage'}                            = $f;

  $self->{'severity'}                            = $self->severity();
  $self->{'scope'}                               = $self->scope();
  $self->{'surfaceConditionEnable'}              = $self->surface_condition_enable();

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
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f);
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
