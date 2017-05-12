#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78abfbe-200e-11de-bda5-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ShortComponentControl;

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

Rinchi::CIGIPP::ShortComponentControl - Perl extension for the Common Image 
Generator Interface - Short Component Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ShortComponentControl;
  my $scmp_ctl = Rinchi::CIGIPP::ShortComponentControl->new();

  $packet_type = $scmp_ctl->packet_type();
  $packet_size = $scmp_ctl->packet_size();
  $component_ident = $scmp_ctl->component_ident(8600);
  $instance_ident = $scmp_ctl->instance_ident(3133);
  $component_class = $scmp_ctl->component_class(Rinchi::CIGIPP->ViewCC);
  $component_state = $scmp_ctl->component_state(67);
  $data1 = $scmp_ctl->data1(43182);
  $data2 = $scmp_ctl->data2(31535);

=head1 DESCRIPTION

The Short Component Control packet, like the Component Control packet, is a 
generic packet used to control a variety of objects or functions on the IG. 
This packet is provided as a lower-bandwidth alternative to the Component 
Control packet for components that do not require more than two words of 
component data.

This packet uses the same Component ID and Instance ID mappings as the 
Component Control packet. If the additional data fields offered by the 
Component Control packet are not necessary for a component, then the two packet 
types should be interchangeable. In other words, all components that can be 
controlled with the Short Component Control packet can also be controlled with 
the Component Control packet.

When receiving a Short Component Control packet, the IG may copy the contents 
of the packet into a Component Control structure, padding the remainder of the 
packet with zeros (0). The two packet types can then be processed by the same 
packet-handling routine.

The Component Data 1 and Component Data 2 fields will be byte-swapped, if 
necessary, as 32-bit data types. Data should be packed into 32-bit units as 
described for the Component Control packet.

=head2 EXPORT

None by default.

#==============================================================================

=item new $scmp_ctl = Rinchi::CIGIPP::ShortComponentControl->new()

Constructor for Rinchi::ShortComponentControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78abfbe-200e-11de-bda5-001c25551abc',
    '_Pack'                                => 'CCSSCCII',
    '_Swap1'                               => 'CCvvCCVV',
    '_Swap2'                               => 'CCnnCCNN',
    'packetType'                           => 5,
    'packetSize'                           => 16,
    'componentIdent'                       => 0,
    'instanceIdent'                        => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused7, and componentClass.
    'componentClass'                       => 0,
    'componentState'                       => 0,
    'data1'                                => 0,
    'data2'                                => 0,
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

 $value = $scmp_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Short Component Control 
packet. The value of this attribute must be 5.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $scmp_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub component_ident([$newValue])

 $value = $scmp_ctl->component_ident($newValue);

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

 $value = $scmp_ctl->instance_ident($newValue);

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

 $value = $scmp_ctl->component_class($newValue);

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

 $value = $scmp_ctl->component_state($newValue);

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

 $value = $scmp_ctl->data1($newValue);

Component Data 1.

This attribute represents one of two 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

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

 $value = $scmp_ctl->data1_float($newValue);

Component Data 1.

This attribute represents as a float one of two 32-bit words used for user-defined 
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

 $value = $scmp_ctl->data1_short1($newValue);

Component Data 1.

This attribute represents as a short the two most significant bytes of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_short2($newValue);

Component Data 1.

This attribute represents as a short the two least significant bytes of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_byte1($newValue);

Component Data 1.

This attribute represents the most significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_byte2($newValue);

Component Data 1.

This attribute represents the second most significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_byte3($newValue);

Component Data 1.

This attribute represents the second least significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_byte4($newValue);

Component Data 1.

This attribute represents the least significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data1_and_2_double($newValue);

Component Data 1.

This attribute represents as a double both 32-bit words used for user-defined 
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

 $value = $scmp_ctl->data2($newValue);

Component Data 2.

This attribute represents one of two 32-bit words used for user-defined 
component data. If this attribute is not needed by the component, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

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

 $value = $scmp_ctl->data1_float($newValue);

Component Data 2.

This attribute represents as a float one of two 32-bit words used for user-defined 
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

 $value = $scmp_ctl->data2_short1($newValue);

Component Data 2.

This attribute represents as a short the two most significant bytes of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data2_short2($newValue);

Component Data 2.

This attribute represents as a short the two least significant bytes of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data2_byte1($newValue);

Component Data 2.

This attribute represents the most significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data2_byte2($newValue);

Component Data 2.

This attribute represents the second most significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data2_byte3($newValue);

Component Data 2.

This attribute represents the second least significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

 $value = $scmp_ctl->data2_byte4($newValue);

Component Data 2.

This attribute represents the least significant byte of one of 
two 32-bit words used for user-defined component data. If this attribute is not 
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

#==========================================================================

=item sub pack()

 $value = $scmp_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'componentIdent'},
        $self->{'instanceIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused7, and componentClass.
        $self->{'componentState'},
        $self->{'data1'},
        $self->{'data2'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $scmp_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'componentIdent'}                      = $c;
  $self->{'instanceIdent'}                       = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields unused7, and componentClass.
  $self->{'componentState'}                      = $f;
  $self->{'data1'}                               = $g;
  $self->{'data2'}                               = $h;

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
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h);
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
