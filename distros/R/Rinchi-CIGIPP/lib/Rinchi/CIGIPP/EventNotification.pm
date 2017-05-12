#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b3dec-200e-11de-bdd4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::EventNotification;

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

Rinchi::CIGIPP::EventNotification - Perl extension for the Common Image 
Generator Interface - Event Notification data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::EventNotification;
  my $evt_ntc = Rinchi::CIGIPP::EventNotification->new();

  $packet_type = $evt_ntc->packet_type();
  $packet_size = $evt_ntc->packet_size();
  $event_ident = $evt_ntc->event_ident(37952);
  $event_data1 = $evt_ntc->event_data1(285);
  $event_data2 = $evt_ntc->event_data2(36545);
  $event_data3 = $evt_ntc->event_data3(12715);

=head1 DESCRIPTION

The Event Notification packet is used to pass event data to the Host. The Host 
may enable and disable individual events using either the Component Control or 
Short Component Control packet.

This packet contains three user-defined 32-bit word values that may contain 
data describing the attributes of the event (e.g., time of occurrence, 
position). These data may be formatted as needed; however, they must be 
byte-swapped as 32-bit fields when byte swapping is necessary. Refer to the 
description of the Component Control packet for more information.

=head2 EXPORT

None by default.

#==============================================================================

=item new $evt_ntc = Rinchi::CIGIPP::EventNotification->new()

Constructor for Rinchi::EventNotification.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b3dec-200e-11de-bdd4-001c25551abc',
    '_Pack'                                => 'CCSIII',
    '_Swap1'                               => 'CCvVVV',
    '_Swap2'                               => 'CCnNNN',
    'packetType'                           => 116,
    'packetSize'                           => 16,
    'eventIdent'                           => 0,
    'eventData1'                           => 0,
    'eventData2'                           => 0,
    'eventData3'                           => 0,
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

 $value = $evt_ntc->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Event Notification packet. 
The value of this attribute must be 116.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $evt_ntc->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub event_ident([$newValue])

 $value = $evt_ntc->event_ident($newValue);

Event ID.

This attribute indicates which event has occurred. Event ID assignments are IG-specific.

=cut

sub event_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'eventIdent'} = $nv;
  }
  return $self->{'eventIdent'};
}

#==============================================================================

=item sub event_data1([$newValue])

 $value = $evt_ntc->event_data1($newValue);

Event Data 1.

This attribute is one of three 32-bit words used for user-defined event data. 
If this attribute is not needed to describe the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use event_data1_short1 and event_data1_short2 for 
16-bit values, or event_data1_byte1, event_data1_byte2, event_data1_byte3, and 
event_data1_byte4 for 8-bit values.

=cut

sub event_data1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'eventData1'} = $nv;
  }
  return $self->{'eventData1'};
}

#==============================================================================

=item sub event_data1_float([$newValue])

 $value = $evt_ntc->event_data1_float($newValue);

Event Data 1.

This attribute represents as a float one of three 32-bit words used for user-defined 
event data. If this attribute is not needed by the event, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'eventData1'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'eventData1'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'eventData1'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'eventData1'}));
  }
}

#==============================================================================

=item sub event_data1_short1([$newValue])

 $value = $evt_ntc->event_data1_short1($newValue);

Event Data 1.

This attribute represents as a short the two most significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'eventData1'}  & 0xFFFF);
    $self->{'eventData1'} = $nv;
  }
  return ($self->{'eventData1'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub event_data1_short2([$newValue])

 $value = $evt_ntc->event_data1_short2($newValue);

Event Data 1.

This attribute represents as a short the two least significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'eventData1'}  & 0xFFFF0000);
    $self->{'eventData1'} = $nv;
  }
  return $self->{'eventData1'} & 0xFFFF;
}

#==============================================================================

=item sub event_data1_byte1([$newValue])

 $value = $evt_ntc->event_data1_byte1($newValue);

Event Data 1.

This attribute represents the most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'eventData1'}  & 0xFFFFFF);
    $self->{'eventData1'} = $nv;
  }
  return ($self->{'eventData1'} >> 24) & 0xFF;
}

#==============================================================================

=item sub event_data1_byte2([$newValue])

 $value = $evt_ntc->event_data1_byte2($newValue);

Event Data 1.

This attribute represents the second most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'eventData1'}  & 0xFF00FFFF);
    $self->{'eventData1'} = $nv;
  }
  return ($self->{'eventData1'} >> 16) & 0xFF;
}

#==============================================================================

=item sub event_data1_byte3([$newValue])

 $value = $evt_ntc->event_data1_byte3($newValue);

Event Data 1.

This attribute represents the second least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'eventData1'}  & 0xFFFF00FF);
    $self->{'eventData1'} = $nv;
  }
  return ($self->{'eventData1'} >> 8) & 0xFF;
}

#==============================================================================

=item sub event_data1_byte4([$newValue])

 $value = $evt_ntc->event_data1_byte4($newValue);

Event Data 1.

This attribute represents the least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'eventData1'}  & 0xFFFFFF00);
    $self->{'eventData1'} = $nv;
  }
  return $self->{'eventData1'} & 0xFF;
}

#==============================================================================

=item sub event_data1_and_2_double([$newValue])

 $value = $evt_ntc->event_data1_and_2_double($newValue);

Event Data 1.

This attribute represents as a double two of three 32-bit words used for user-defined 
event data. If this attribute is not needed by the event, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data1_and_2_double() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('d',$nv);
    if($self->{'_LittleEndian'}) {
      ($self->{'eventData2'}, $self->{'eventData1'}) = CORE::unpack('VV',$nvp);
    } else {
      ($self->{'eventData1'}, $self->{'eventData2'}) = CORE::unpack('NN',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('d',CORE::pack('VV',$self->{'eventData2'}, $self->{'eventData1'}));
  } else {
    return CORE::unpack('d',CORE::pack('NV',$self->{'eventData1'}, $self->{'eventData2'}));
  }
}

#==============================================================================

=item sub event_data2([$newValue])

 $value = $evt_ntc->event_data2($newValue);

Event Data 2.

This attribute is one of three 32-bit words used for user-defined event data. 
If this attribute is not needed to describe the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use event_data2_short1 and event_data2_short2 for 
16-bit values, or event_data2_byte1, event_data2_byte2, event_data2_byte3, and 
event_data2_byte4 for 8-bit values.

=cut

sub event_data2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'eventData2'} = $nv;
  }
  return $self->{'eventData2'};
}

#==============================================================================

=item sub event_data2_float([$newValue])

 $value = $evt_ntc->event_data2_float($newValue);

Event Data 2.

This attribute represents as a float one of three 32-bit words used for user-defined 
event data. If this attribute is not needed by the event, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'eventData2'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'eventData2'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'eventData2'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'eventData2'}));
  }
}

#==============================================================================

=item sub event_data2_short1([$newValue])

 $value = $evt_ntc->event_data2_short1($newValue);

Event Data 2.

This attribute represents as a short the two most significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'eventData2'}  & 0xFFFF);
    $self->{'eventData2'} = $nv;
  }
  return ($self->{'eventData2'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub event_data2_short2([$newValue])

 $value = $evt_ntc->event_data2_short2($newValue);

Event Data 2.

This attribute represents as a short the two least significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'eventData2'}  & 0xFFFF0000);
    $self->{'eventData2'} = $nv;
  }
  return $self->{'eventData2'} & 0xFFFF;
}

#==============================================================================

=item sub event_data2_byte1([$newValue])

 $value = $evt_ntc->event_data2_byte1($newValue);

Event Data 2.

This attribute represents the most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'eventData2'}  & 0xFFFFFF);
    $self->{'eventData2'} = $nv;
  }
  return ($self->{'eventData2'} >> 24) & 0xFF;
}

#==============================================================================

=item sub event_data2_byte2([$newValue])

 $value = $evt_ntc->event_data2_byte2($newValue);

Event Data 2.

This attribute represents the second most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'eventData2'}  & 0xFF00FFFF);
    $self->{'eventData2'} = $nv;
  }
  return ($self->{'eventData2'} >> 16) & 0xFF;
}

#==============================================================================

=item sub event_data2_byte3([$newValue])

 $value = $evt_ntc->event_data2_byte3($newValue);

Event Data 2.

This attribute represents the second least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'eventData2'}  & 0xFFFF00FF);
    $self->{'eventData2'} = $nv;
  }
  return ($self->{'eventData2'} >> 8) & 0xFF;
}

#==============================================================================

=item sub event_data2_byte4([$newValue])

 $value = $evt_ntc->event_data2_byte4($newValue);

Event Data 2.

This attribute represents the least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data2_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'eventData2'}  & 0xFFFFFF00);
    $self->{'eventData2'} = $nv;
  }
  return $self->{'eventData2'} & 0xFF;
}

#==============================================================================

=item sub event_data3([$newValue])

 $value = $evt_ntc->event_data3($newValue);

Event Data 3.

This attribute is one of three 32-bit words used for user-defined event data. 
If this attribute is not needed to describe the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly. Use event_data3_short1 and event_data3_short2 for 
16-bit values, or event_data3_byte1, event_data3_byte2, event_data3_byte3, and 
event_data3_byte4 for 8-bit values.

=cut

sub event_data3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'eventData3'} = $nv;
  }
  return $self->{'eventData3'};
}

#==========================================================================

=item sub pack()

 $value = $evt_ntc->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'eventIdent'},
        $self->{'eventData1'},
        $self->{'eventData2'},
        $self->{'eventData3'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $evt_ntc->unpack();

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
  $self->{'eventIdent'}                          = $c;
  $self->{'eventData1'}                          = $d;
  $self->{'eventData2'}                          = $e;
  $self->{'eventData3'}                          = $f;

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

#==============================================================================

=item sub event_data3_float([$newValue])

 $value = $evt_ntc->event_data3_float($newValue);

Event Data 3.

This attribute represents as a float one of three 32-bit words used for user-defined 
event data. If this attribute is not needed by the event, this value is 
ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_float() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $nvp = CORE::pack('f',$nv);
    if($self->{'_LittleEndian'}) {
      $self->{'eventData3'} = CORE::unpack('V',$nvp);
    } else {
      $self->{'eventData3'} = CORE::unpack('N',$nvp);
    }
  }
  if($self->{'_LittleEndian'}) {
    return CORE::unpack('f',CORE::pack('V',$self->{'eventData3'}));
  } else {
    return CORE::unpack('f',CORE::pack('N',$self->{'eventData3'}));
  }
}

#==============================================================================

=item sub event_data3_short1([$newValue])

 $value = $evt_ntc->event_data3_short1($newValue);

Event Data 3.

This attribute represents as a short the two most significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_short1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFFFF) << 16) | ($self->{'eventData3'}  & 0xFFFF);
    $self->{'eventData3'} = $nv;
  }
  return ($self->{'eventData3'} >> 16) & 0xFFFF;
}

#==============================================================================

=item sub event_data3_short2([$newValue])

 $value = $evt_ntc->event_data3_short2($newValue);

Event Data 3.

This attribute represents as a short the two least significant bytes of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_short2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFFFF) | ($self->{'eventData3'}  & 0xFFFF0000);
    $self->{'eventData3'} = $nv;
  }
  return $self->{'eventData3'} & 0xFFFF;
}

#==============================================================================

=item sub event_data3_byte1([$newValue])

 $value = $evt_ntc->event_data3_byte1($newValue);

Event Data 3.

This attribute represents the most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_byte1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 24) | ($self->{'eventData3'}  & 0xFFFFFF);
    $self->{'eventData3'} = $nv;
  }
  return ($self->{'eventData3'} >> 24) & 0xFF;
}

#==============================================================================

=item sub event_data3_byte2([$newValue])

 $value = $evt_ntc->event_data3_byte2($newValue);

Event Data 3.

This attribute represents the second most significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_byte2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 16) | ($self->{'eventData3'}  & 0xFF00FFFF);
    $self->{'eventData3'} = $nv;
  }
  return ($self->{'eventData3'} >> 16) & 0xFF;
}

#==============================================================================

=item sub event_data3_byte3([$newValue])

 $value = $evt_ntc->event_data3_byte3($newValue);

Event Data 3.

This attribute represents the second least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_byte3() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = (($nv & 0xFF) << 8) | ($self->{'eventData3'}  & 0xFFFF00FF);
    $self->{'eventData3'} = $nv;
  }
  return ($self->{'eventData3'} >> 8) & 0xFF;
}

#==============================================================================

=item sub event_data3_byte4([$newValue])

 $value = $evt_ntc->event_data3_byte4($newValue);

Event Data 3.

This attribute represents the least significant byte of one of 
three 32-bit words used for user-defined event data. If this attribute is not 
needed by the event, this value is ignored.

Note: This attribute will be byte-swapped as a 32-bit value if the receiver and 
sender use different byte ordering schemes. If the attribute is used to store 
multiple 8- or 16-bit values, the data should be packed so that byte swapping 
will be performed correctly.

=cut

sub event_data3_byte4() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $nv = ($nv & 0xFF) | ($self->{'eventData3'}  & 0xFFFFFF00);
    $self->{'eventData3'} = $nv;
  }
  return $self->{'eventData3'} & 0xFF;
}

#==============================================================================

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
