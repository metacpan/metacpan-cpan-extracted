#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78abd0c-200e-11de-bda4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ComponentControl;

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

Rinchi::CIGIPP::ComponentControl - Perl extension for the Common Image 
Generator Interface - Component Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ComponentControl;
  my $cmp_ctl = Rinchi::CIGIPP::ComponentControl->new();

  $packet_type = $cmp_ctl->packet_type();
  $packet_size = $cmp_ctl->packet_size();
  $component_ident = $cmp_ctl->component_ident(37562);
  $instance_ident = $cmp_ctl->instance_ident(26282);
  $component_class = $cmp_ctl->component_class(Rinchi::CIGIPP->EntityCC);
  $component_state = $cmp_ctl->component_state(245);
  $data1 = $cmp_ctl->data1(26);
  $data2 = $cmp_ctl->data2(383);
  $data3 = $cmp_ctl->data3(25589);
  $data4 = $cmp_ctl->data4(28613);
  $data5 = $cmp_ctl->data5(23541);
  $data6 = $cmp_ctl->data6(43464);

=head1 DESCRIPTION

The Component Control packet is provided as a generic mechanism to control 
various components within the simulation. Because CIGI is designed to be a 
general-purpose interface, only the most common attributes of entities, views, 
and other objects are explicitly represented by attributes within specific data 
packets. Other attributes can be represented by components.

Components may correspond to parts or properties of entities, views and view 
groups, sensors, weather and environment, terrain, and even the IG itself. The 
type of object possessing the component is identified by the Component Class 
attribute. The specific instance of that object is specified by the Instance ID 
attribute. Depending upon the value of the Component Class attribute, the 
instance ID might correspond to an Entity ID, a view ID, an environmental 
attribute, etc. The Component ID attribute uniquely identifies the component 
for the instance.

Each component has zero or more discrete states, and/or up to six user-defined 
values. The user-defined values may either be integers or floating-point real 
numbers. A light, for instance, might have two discrete states (On and Off), an 
RGB color value represented as a 32-bit integer, and a real-value intensity 
level. A component representing the global lightpoint intensity value might 
have a real-value intensity level and no discrete states.

Regardless of how the six user-defined data fields are formatted, they will be 
byte-swapped as separate 32-bit values if the Host and IG use different byte 
ordering schemes. This ensures that all Component Control packets are 
byte-swapped in a consistent manner. The data should be packaged using masks 
and bit-wise operations so that the values are not changed when the 32-bit 
words are byte-swapped.

=head2 EXPORT

None by default.

#==============================================================================

=item new $cmp_ctl = Rinchi::CIGIPP::ComponentControl->new()

Constructor for Rinchi::ComponentControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78abd0c-200e-11de-bda4-001c25551abc',
    '_Pack'                                => 'CCSSCCIIIIII',
    '_Swap1'                               => 'CCvvCCVVVVVV',
    '_Swap2'                               => 'CCnnCCNNNNNN',
    'packetType'                           => 4,
    'packetSize'                           => 32,
    'componentIdent'                       => 0,
    'instanceIdent'                        => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused6, and componentClass.
    'componentClass'                       => 0,
    'componentState'                       => 0,
    'data1'                                => 0,
    'data2'                                => 0,
    'data3'                                => 0,
    'data4'                                => 0,
    'data5'                                => 0,
    'data6'                                => 0,
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
  $self->{'_LittleEndian'} = (CORE::unpack('v',CORE::pack('S',0x8000)) == 0x8000);

  bless($self,$class);
  return $self;
}

#==============================================================================

=item sub packet_type()

 $value = $cmp_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Component Control packet. The 
value of this attribute must be 4.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $cmp_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub component_ident([$newValue])

 $value = $cmp_ctl->component_ident($newValue);

Component Identifier.

This attribute uniquely identifies the component to which the data in this 
packet should be applied.

If Component Class is set to Regional Layered Weather (6), the weather layer ID 
is specified by the most significant byte of Component ID.

=cut

sub component_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'componentIdent'} = $nv;
  }
  return $self->{'componentIdent'};
}

#==============================================================================

=item sub instance_ident([$newValue])

 $value = $cmp_ctl->instance_ident($newValue);

Instance Identifier.

This attribute uniquely identifies the object to which the component belongs. 
This value corresponds to an entity ID, a view or view group ID, a sensor ID, 
environmental region ID, global weather layer ID, or event ID depending upon 
the value of the Component Class attribute.

=cut

sub instance_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'instanceIdent'} = $nv;
  }
  return $self->{'instanceIdent'};
}

#==============================================================================

=item sub component_class([$newValue])

 $value = $cmp_ctl->component_class($newValue);

Component Class.

This attribute identifies the type of object to which the Instance ID attribute 
refers. Both of these attributes are used in conjunction with Component ID to 
uniquely identify a component in the simulation.

    EntityCC                   0
    ViewCC                     1
    ViewGroupCC                2
    SensorCC                   3
    RegionalSeaSurfaceCC       4
    RegionalTerrainSurfaceCC   5
    RegionalLayeredWeatherCC   6
    GlobalSeaSurfaceCC         7
    GlobalTerrainSurfaceCC     8
    GlobalLayeredWeatherCC     9
    AtmosphereCC               10
    CelestialSphereCC          11
    EventCC                    12
    SystemCC                   13
    SymbolSurfaceCC            14
    SymbolCC                   15

=cut

sub component_class() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7) or ($nv==8) or ($nv==9) or ($nv==10) or ($nv==11) or ($nv==12) or ($nv==13) or ($nv==14) or ($nv==15)) {
      $self->{'componentClass'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x3F;
    } else {
      carp "component_class must be 0 (EntityCC), 1 (ViewCC), 2 (ViewGroupCC), 3 (SensorCC), 4 (RegionalSeaSurfaceCC), 5 (RegionalTerrainSurfaceCC), 6 (RegionalLayeredWeatherCC), 7 (GlobalSeaSurfaceCC), 8 (GlobalTerrainSurfaceCC), 9 (GlobalLayeredWeatherCC), 10 (AtmosphereCC), 11 (CelestialSphereCC), 12 (EventCC), 13 (SystemCC), 14 (SymbolSurfaceCC), or 15 (SymbolCC).";
    }
  }
  return ($self->{'_bitfields1'} & 0x3F);
}

#==============================================================================

=item sub component_state([$newValue])

 $value = $cmp_ctl->component_state($newValue);

Component State.

This attribute specifies a discrete state for the component. If a discrete 
state is not applicable to the component, this attribute is ignored.

=cut

sub component_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'componentState'} = $nv;
  }
  return $self->{'componentState'};
}

#==============================================================================

=item sub data1([$newValue])

 $value = $cmp_ctl->data1($newValue);

Component Data 1.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data1_short1 and data1_short2 for 16-bit values,
or data1_byte1, data1_byte2, data1_byte3, and data1_byte4 for 8-bit values.

=cut

sub data1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data1'} = $nv;
  }
  return $self->{'data1'};
}

#==============================================================================

=item sub data1_float([$newValue])

 $value = $cmp_ctl->data1_float($newValue);

Component Data 1.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data1'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data1'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data1'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data1'}));
  }
}

#==============================================================================

=item sub data1_short1([$newValue])

 $value = $cmp_ctl->data1_short1($newValue);

Component Data 1.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data1'}  & 0xFFFF);
    $self->{'data1'} = $nv;
  }
  return ($self->{'data1'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data1_short2([$newValue])

 $value = $cmp_ctl->data1_short2($newValue);

Component Data 1.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data1'}  & 0xFFFF0000);
    $self->{'data1'} = $nv;
  }
  return $self->{'data1'} & 0xFFFF;
}

#==============================================================================

=item sub data1_byte1([$newValue])

 $value = $cmp_ctl->data1_byte1($newValue);

Component Data 1.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data1'}  & 0xFFFFFF);
    $self->{'data1'} = $nv;
  }
  return ($self->{'data1'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data1_byte2([$newValue])

 $value = $cmp_ctl->data1_byte2($newValue);

Component Data 1.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data1'}  & 0xFF00FFFF);
    $self->{'data1'} = $nv;
  }
  return ($self->{'data1'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data1_byte3([$newValue])

 $value = $cmp_ctl->data1_byte3($newValue);

Component Data 1.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data1'}  & 0xFFFF00FF);
    $self->{'data1'} = $nv;
  }
  return ($self->{'data1'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data1_byte4([$newValue])

 $value = $cmp_ctl->data1_byte4($newValue);

Component Data 1.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data1'}  & 0xFFFFFF00);
    $self->{'data1'} = $nv;
  }
  return $self->{'data1'} & 0xFF;
}

#==============================================================================

=item sub data1_and_2_double([$newValue])

 $value = $cmp_ctl->data1_and_2_double($newValue);

Component Data 1.

This attribute represents as a double two of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data1_and_2_double() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('d',$nv);
    if($self->{'_LittleEndian'}) {
      ($self->{'data2'}, $self->{'data1'}) = CORE::unpack('VV',$nvp);
    } else {
      ($self->{'data1'}, $self->{'data2'}) = CORE::unpack('NN',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('d',CORE::pack('VV',$self->{'data2'}, $self->{'data1'}));
  } else {
    return CORE::unpack('d',CORE::pack('NV',$self->{'data1'}, $self->{'data2'}));
  }
}

#==============================================================================

=item sub data2([$newValue])

 $value = $cmp_ctl->data2($newValue);

Component Data 2.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data2_short1 and data2_short2 for 16-bit values,
or data2_byte1, data2_byte2, data2_byte3, and data2_byte4 for 8-bit values.

=cut

sub data2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data2'} = $nv;
  }
  return $self->{'data2'};
}

#==============================================================================

=item sub data2_float([$newValue])

 $value = $cmp_ctl->data2_float($newValue);

Component Data 2.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data2'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data2'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data2'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data2'}));
  }
}

#==============================================================================

=item sub data2_short1([$newValue])

 $value = $cmp_ctl->data2_short1($newValue);

Component Data 2.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data2'}  & 0xFFFF);
    $self->{'data2'} = $nv;
  }
  return ($self->{'data2'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data2_short2([$newValue])

 $value = $cmp_ctl->data2_short2($newValue);

Component Data 2.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data2'}  & 0xFFFF0000);
    $self->{'data2'} = $nv;
  }
  return $self->{'data2'} & 0xFFFF;
}

#==============================================================================

=item sub data2_byte1([$newValue])

 $value = $cmp_ctl->data2_byte1($newValue);

Component Data 2.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data2'}  & 0xFFFFFF);
    $self->{'data2'} = $nv;
  }
  return ($self->{'data2'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data2_byte2([$newValue])

 $value = $cmp_ctl->data2_byte2($newValue);

Component Data 2.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data2'}  & 0xFF00FFFF);
    $self->{'data2'} = $nv;
  }
  return ($self->{'data2'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data2_byte3([$newValue])

 $value = $cmp_ctl->data2_byte3($newValue);

Component Data 2.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data2'}  & 0xFFFF00FF);
    $self->{'data2'} = $nv;
  }
  return ($self->{'data2'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data2_byte4([$newValue])

 $value = $cmp_ctl->data2_byte4($newValue);

Component Data 2.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data2_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data2'}  & 0xFFFFFF00);
    $self->{'data2'} = $nv;
  }
  return $self->{'data2'} & 0xFF;
}

#==============================================================================

=item sub data3([$newValue])

 $value = $cmp_ctl->data3($newValue);

Component Data 3.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data3_short1 and data3_short2 for 16-bit values,
or data3_byte1, data3_byte2, data3_byte3, and data3_byte4 for 8-bit values.

=cut

sub data3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data3'} = $nv;
  }
  return $self->{'data3'};
}

#==============================================================================

=item sub data3_float([$newValue])

 $value = $cmp_ctl->data3_float($newValue);

Component Data 3.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data3'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data3'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data3'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data3'}));
  }
}

#==============================================================================

=item sub data3_short1([$newValue])

 $value = $cmp_ctl->data3_short1($newValue);

Component Data 3.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data3'}  & 0xFFFF);
    $self->{'data3'} = $nv;
  }
  return ($self->{'data3'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data3_short2([$newValue])

 $value = $cmp_ctl->data3_short2($newValue);

Component Data 3.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data3'}  & 0xFFFF0000);
    $self->{'data3'} = $nv;
  }
  return $self->{'data3'} & 0xFFFF;
}

#==============================================================================

=item sub data3_byte1([$newValue])

 $value = $cmp_ctl->data3_byte1($newValue);

Component Data 3.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data3'}  & 0xFFFFFF);
    $self->{'data3'} = $nv;
  }
  return ($self->{'data3'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data3_byte2([$newValue])

 $value = $cmp_ctl->data3_byte2($newValue);

Component Data 3.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data3'}  & 0xFF00FFFF);
    $self->{'data3'} = $nv;
  }
  return ($self->{'data3'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data3_byte3([$newValue])

 $value = $cmp_ctl->data3_byte3($newValue);

Component Data 3.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data3'}  & 0xFFFF00FF);
    $self->{'data3'} = $nv;
  }
  return ($self->{'data3'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data3_byte4([$newValue])

 $value = $cmp_ctl->data3_byte4($newValue);

Component Data 3.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data3'}  & 0xFFFFFF00);
    $self->{'data3'} = $nv;
  }
  return $self->{'data3'} & 0xFF;
}

#==============================================================================

=item sub data3_and_4_double([$newValue])

 $value = $cmp_ctl->data3_and_4_double($newValue);

Component Data 3 and 4.

This attribute represents as a double two of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data3_and_4_double() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('d',$nv);
    if($self->{'_LittleEndian'}) {
      ($self->{'data4'}, $self->{'data3'}) = CORE::unpack('VV',$nvp);
    } else {
      ($self->{'data3'}, $self->{'data4'}) = CORE::unpack('NN',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('d',CORE::pack('VV',$self->{'data4'}, $self->{'data3'}));
  } else {
    return CORE::unpack('d',CORE::pack('NV',$self->{'data3'}, $self->{'data4'}));
  }
}

#==============================================================================

=item sub data4([$newValue])

 $value = $cmp_ctl->data4($newValue);

Component Data 4.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data4_short1 and data4_short2 for 16-bit values,
or data4_byte1, data4_byte2, data4_byte3, and data4_byte4 for 8-bit values.

=cut

sub data4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data4'} = $nv;
  }
  return $self->{'data4'};
}

#==============================================================================

=item sub data4_float([$newValue])

 $value = $cmp_ctl->data1_float($newValue);

Component Data 4.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data4'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data4'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data4'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data4'}));
  }
}

#==============================================================================

=item sub data4_short1([$newValue])

 $value = $cmp_ctl->data4_short1($newValue);

Component Data 4.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data4'}  & 0xFFFF);
    $self->{'data4'} = $nv;
  }
  return ($self->{'data4'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data4_short2([$newValue])

 $value = $cmp_ctl->data4_short2($newValue);

Component Data 4.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data4'}  & 0xFFFF0000);
    $self->{'data4'} = $nv;
  }
  return $self->{'data4'} & 0xFFFF;
}

#==============================================================================

=item sub data4_byte1([$newValue])

 $value = $cmp_ctl->data4_byte1($newValue);

Component Data 4.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data4'}  & 0xFFFFFF);
    $self->{'data4'} = $nv;
  }
  return ($self->{'data4'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data4_byte2([$newValue])

 $value = $cmp_ctl->data4_byte2($newValue);

Component Data 4.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data4'}  & 0xFF00FFFF);
    $self->{'data4'} = $nv;
  }
  return ($self->{'data4'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data4_byte3([$newValue])

 $value = $cmp_ctl->data4_byte3($newValue);

Component Data 4.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data4'}  & 0xFFFF00FF);
    $self->{'data4'} = $nv;
  }
  return ($self->{'data4'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data4_byte4([$newValue])

 $value = $cmp_ctl->data4_byte4($newValue);

Component Data 4.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data4_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data4'}  & 0xFFFFFF00);
    $self->{'data4'} = $nv;
  }
  return $self->{'data4'} & 0xFF;
}

#==============================================================================

=item sub data5([$newValue])

 $value = $cmp_ctl->data5($newValue);

Component Data 5.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data5_short1 and data5_short2 for 16-bit values,
or data5_byte1, data5_byte2, data5_byte3, and data5_byte4 for 8-bit values.

=cut

sub data5() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data5'} = $nv;
  }
  return $self->{'data5'};
}

#==============================================================================

=item sub data5_float([$newValue])

 $value = $cmp_ctl->data1_float($newValue);

Component Data 5.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data5'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data5'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data5'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data5'}));
  }
}

#==============================================================================

=item sub data5_short1([$newValue])

 $value = $cmp_ctl->data5_short1($newValue);

Component Data 5.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data5'}  & 0xFFFF);
    $self->{'data5'} = $nv;
  }
  return ($self->{'data5'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data5_short2([$newValue])

 $value = $cmp_ctl->data5_short2($newValue);

Component Data 5.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data5'}  & 0xFFFF0000);
    $self->{'data5'} = $nv;
  }
  return $self->{'data5'} & 0xFFFF;
}

#==============================================================================

=item sub data5_byte1([$newValue])

 $value = $cmp_ctl->data5_byte1($newValue);

Component Data 5.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data5'}  & 0xFFFFFF);
    $self->{'data5'} = $nv;
  }
  return ($self->{'data5'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data5_byte2([$newValue])

 $value = $cmp_ctl->data5_byte2($newValue);

Component Data 5.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data5'}  & 0xFF00FFFF);
    $self->{'data5'} = $nv;
  }
  return ($self->{'data5'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data5_byte3([$newValue])

 $value = $cmp_ctl->data5_byte3($newValue);

Component Data 5.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data5'}  & 0xFFFF00FF);
    $self->{'data5'} = $nv;
  }
  return ($self->{'data5'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data5_byte4([$newValue])

 $value = $cmp_ctl->data5_byte4($newValue);

Component Data 5.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data5'}  & 0xFFFFFF00);
    $self->{'data5'} = $nv;
  }
  return $self->{'data5'} & 0xFF;
}

#==============================================================================

=item sub data5_and_6_double([$newValue])

 $value = $cmp_ctl->data5_and_6_double($newValue);

Component Data 5 and 6.

This attribute represents as a double two of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data5_and_6_double() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('d',$nv);
    if($self->{'_LittleEndian'}) {
      ($self->{'data6'}, $self->{'data5'}) = CORE::unpack('VV',$nvp);
    } else {
      ($self->{'data5'}, $self->{'data6'}) = CORE::unpack('NN',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('d',CORE::pack('VV',$self->{'data6'}, $self->{'data5'}));
  } else {
    return CORE::unpack('d',CORE::pack('NV',$self->{'data5'}, $self->{'data6'}));
  }
}

#==============================================================================

=item sub data6([$newValue])

 $value = $cmp_ctl->data6($newValue);

Component Data 6.

This attribute represents one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use data6_short1 and data6_short2 for 16-bit values,
or data6_byte1, data6_byte2, data6_byte3, and data6_byte4 for 8-bit values.

=cut

sub data6() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'data6'} = $nv;
  }
  return $self->{'data6'};
}

#==============================================================================

=item sub data6_float([$newValue])

 $value = $cmp_ctl->data1_float($newValue);

Component Data 6.

This attribute represents as a float one of six 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'data6'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'data6'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'data6'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'data6'}));
  }
}

#==============================================================================

=item sub data6_short1([$newValue])

 $value = $cmp_ctl->data6_short1($newValue);

Component Data 6.

This attribute represents as a short the two most significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'data6'}  & 0xFFFF);
    $self->{'data6'} = $nv;
  }
  return ($self->{'data6'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub data6_short2([$newValue])

 $value = $cmp_ctl->data6_short2($newValue);

Component Data 6.

This attribute represents as a short the two least significant bytes of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'data6'}  & 0xFFFF0000);
    $self->{'data6'} = $nv;
  }
  return $self->{'data6'} & 0xFFFF;
}

#==============================================================================

=item sub data6_byte1([$newValue])

 $value = $cmp_ctl->data6_byte1($newValue);

Component Data 6.

This attribute represents the most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'data6'}  & 0xFFFFFF);
    $self->{'data6'} = $nv;
  }
  return ($self->{'data6'} >> 24) & 0xFF;
}

#==============================================================================

=item sub data6_byte2([$newValue])

 $value = $cmp_ctl->data6_byte2($newValue);

Component Data 6.

This attribute represents the second most significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'data6'}  & 0xFF00FFFF);
    $self->{'data6'} = $nv;
  }
  return ($self->{'data6'} >> 16) & 0xFF;
}

#==============================================================================

=item sub data6_byte3([$newValue])

 $value = $cmp_ctl->data6_byte3($newValue);

Component Data 6.

This attribute represents the second least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'data6'}  & 0xFFFF00FF);
    $self->{'data6'} = $nv;
  }
  return ($self->{'data6'} >> 8) & 0xFF;
}

#==============================================================================

=item sub data6_byte4([$newValue])

 $value = $cmp_ctl->data6_byte4($newValue);

Component Data 6.

This attribute represents the least significant byte of one of 
six 32-bit words used for user-defined component data. If this attribute is not 
needed by the component, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub data6_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'data6'}  & 0xFFFFFF00);
    $self->{'data6'} = $nv;
  }
  return $self->{'data6'} & 0xFF;
}

#==========================================================================

=item sub pack()

 $value = $cmp_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'componentIdent'},
        $self->{'instanceIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused6, and componentClass.
        $self->{'componentState'},
        $self->{'data1'},
        $self->{'data2'},
        $self->{'data3'},
        $self->{'data4'},
        $self->{'data5'},
        $self->{'data6'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $cmp_ctl->unpack();

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
  $self->{'componentIdent'}                      = $c;
  $self->{'instanceIdent'}                       = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused6, and componentClass.
  $self->{'componentState'}                      = $f;
  $self->{'data1'}                               = $g;
  $self->{'data2'}                               = $h;
  $self->{'data3'}                               = $i;
  $self->{'data4'}                               = $j;
  $self->{'data5'}                               = $k;
  $self->{'data6'}                               = $l;

  $self->{'componentClass'}                      = $self->component_class();

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

#==========================================================================

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
