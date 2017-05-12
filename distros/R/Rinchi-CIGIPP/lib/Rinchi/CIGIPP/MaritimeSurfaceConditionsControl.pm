#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ad594-200e-11de-bdad-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::MaritimeSurfaceConditionsControl;

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

Rinchi::CIGIPP::MaritimeSurfaceConditionsControl - Perl extension for the 
Common Image Generator Interface - Maritime Surface Conditions Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::MaritimeSurfaceConditionsControl;
  my $msc_ctl = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new();

  $packet_type = $msc_ctl->packet_type();
  $packet_size = $msc_ctl->packet_size();
  $entity_ident = $msc_ctl->entity_ident(51957);
  $region_ident = $msc_ctl->region_ident(64233);
  $scope = $msc_ctl->scope(Rinchi::CIGIPP->GlobalScope);
  $whitecap_enable = $msc_ctl->whitecap_enable(Rinchi::CIGIPP->Disable);
  $surface_conditions_enable = $msc_ctl->surface_conditions_enable(Rinchi::CIGIPP->Disable);
  $sea_surface_height = $msc_ctl->sea_surface_height(32.113);
  $surface_water_temperature = $msc_ctl->surface_water_temperature(0.898);
  $surface_clarity = $msc_ctl->surface_clarity(56.091);

=head1 DESCRIPTION

The Maritime Surface Conditions Control packet is used to specify the surface 
behavior for seas and other bodies of water. This packet is used in conjunction 
with the Weather Control and Wave Control packets to define sea states.

Regional maritime surface conditions always take precedence over the global 
surface conditions. Once the surface conditions of a region are set, global 
changes will not affect the surface conditions within that region unless it is 
disabled. Global changes will, however, contribute to the conditions within a 
region's transition perimeter.

If two or more regions overlap, the value of each surface condition attribute 
defining the sea state within the area of overlap should be the average of the 
values determined by overlapping the regions.

To determine the maritime surface conditions within areas of overlap or through 
a transition perimeter, the Host can request the conditions at a specific 
latitude and longitude by issuing an Environmental Conditions Request packet. 
The Host can request the instantaneous height of the water surface at a 
specific latitude and longitude by sending a HAT/HOT Request packet.

=head2 EXPORT

None by default.

#==============================================================================

=item new $msc_ctl = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new()

Constructor for Rinchi::MaritimeSurfaceConditionsControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ad594-200e-11de-bdad-001c25551abc',
    '_Pack'                                => 'CCSCCSfffI',
    '_Swap1'                               => 'CCvCCvVVVV',
    '_Swap2'                               => 'CCnCCnNNNN',
    'packetType'                           => 13,
    'packetSize'                           => 24,
    'region_entityIdent'                   => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused22, scope, whitecapEnable, and surfaceConditionsEnable.
    'scope'                                => 0,
    'whitecapEnable'                       => 0,
    'surfaceConditionsEnable'              => 0,
    '_unused23'                            => 0,
    '_unused24'                            => 0,
    'seaSurfaceHeight'                     => 0,
    'surfaceWaterTemperature'              => 0,
    'surfaceClarity'                       => 0,
    '_unused25'                            => 0,
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

 $value = $msc_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Maritime Surface Conditions 
Control packet. The value of this attribute must be 13.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $msc_ctl->packet_size();

Data Packet Size. 

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 24.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $msc_ctl->entity_ident($newValue);

Entity ID. (Entity-based Surface Conditions)

This attribute specifies the entity to which the surface attributes in this 
packet are applied.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'region_entityIdent'} = $nv;
  }
  return $self->{'region_entityIdent'};
}

#==============================================================================

=item sub region_ident([$newValue])

 $value = $msc_ctl->region_ident($newValue);

Region ID. (Regional Surface Conditions)

This attribute specifies the region to which the surface attributes are 
confined.
Note: Entity ID/Region ID is ignored if Scope is set to Global (0).

=cut

sub region_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'region_entityIdent'} = $nv;
  }
  return $self->{'region_entityIdent'};
}

#==============================================================================

=item sub scope([$newValue])

 $value = $msc_ctl->scope($newValue);

Scope.

This attribute specifies whether this packet is applied globally, applied to a 
region, or assigned to an entity. If this value is set to Regional (1), the 
surface condition properties are applied only within the region specified by 
Region ID. If this value is set to Entity (2), the properties are applied to 
the area defined by the moving model specified by Entity ID.

    GlobalScope     0
    RegionalScope   1
    EntityScope     2

=cut

sub scope() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'scope'}                                = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x0C;
    } else {
      carp "scope must be 0 (GlobalScope), 1 (RegionalScope), or 2 (EntityScope).";
    }
  }
  return (($self->{'_bitfields1'} & 0x0C) >> 2);
}

#==============================================================================

=item sub whitecap_enable([$newValue])

 $value = $msc_ctl->whitecap_enable($newValue);

Whitecap Enable.

This attribute determines whether whitecaps are enabled.

    Disable   0
    Enable    1

=cut

sub whitecap_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'whitecapEnable'}                       = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "whitecap_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub surface_conditions_enable([$newValue])

 $value = $msc_ctl->surface_conditions_enable($newValue);

Surface Conditions Enable.

This attribute determines the state of the specified surface conditions. If 
this attribute is set to Disable (0), the surface conditions within the region 
or entity are the same as the global maritime surface conditions. If the 
attribute is set to Enable (1), the surface conditions are defined by this 
packet.
This attribute is ignored if Scope is set to Global (0).

    Disable   0
    Enable    1

=cut

sub surface_conditions_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'surfaceConditionsEnable'}              = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "surface_conditions_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub sea_surface_height([$newValue])

 $value = $msc_ctl->sea_surface_height($newValue);

Sea Surface Height.

This attribute specifies the height of the water above MSL at equilibrium. This 
attribute can also be used to specify the tide level within the surf zone.

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

 $value = $msc_ctl->surface_water_temperature($newValue);

Surface Water Temperature.

This attribute specifies in degrees Celsius the water temperature at the surface.

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

 $value = $msc_ctl->surface_clarity($newValue);

Surface Clarity.

This attribute specifies the clarity of the water at its surface. This is used 
to control the visual effect of the water's turbidity and sediment type. A 
value of 100% indicates pristine water. A value of 0% indicates extremely 
turbid water.

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

 $value = $msc_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'region_entityIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused22, scope, whitecapEnable, and surfaceConditionsEnable.
        $self->{'_unused23'},
        $self->{'_unused24'},
        $self->{'seaSurfaceHeight'},
        $self->{'surfaceWaterTemperature'},
        $self->{'surfaceClarity'},
        $self->{'_unused25'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $msc_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'region_entityIdent'}                  = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused22, scope, whitecapEnable, and surfaceConditionsEnable.
  $self->{'_unused23'}                           = $e;
  $self->{'_unused24'}                           = $f;
  $self->{'seaSurfaceHeight'}                    = $g;
  $self->{'surfaceWaterTemperature'}             = $h;
  $self->{'surfaceClarity'}                      = $i;
  $self->{'_unused25'}                           = $j;

  $self->{'scope'}                               = $self->scope();
  $self->{'whitecapEnable'}                      = $self->whitecap_enable();
  $self->{'surfaceConditionsEnable'}             = $self->surface_conditions_enable();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j);
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
