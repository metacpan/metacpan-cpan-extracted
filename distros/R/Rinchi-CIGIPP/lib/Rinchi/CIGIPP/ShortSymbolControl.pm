#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b15b8-200e-11de-bdc5-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ShortSymbolControl;

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

Rinchi::CIGIPP::ShortSymbolControl - Perl extension for the Common Image 
Generator Interface - Short Symbol Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ShortSymbolControl;
  my $ssym_ctl = Rinchi::CIGIPP::ShortSymbolControl->new();

  $packet_type = $ssym_ctl->packet_type();
  $packet_size = $ssym_ctl->packet_size();
  $symbol_ident = $ssym_ctl->symbol_ident(48088);
  $inherit_color = $ssym_ctl->inherit_color(Rinchi::CIGIPP->NotInherited);
  $flash_control = $ssym_ctl->flash_control(Rinchi::CIGIPP->RestartFlash);
  $attach_state = $ssym_ctl->attach_state(Rinchi::CIGIPP->Detach);
  $symbol_state = $ssym_ctl->symbol_state(Rinchi::CIGIPP->Hidden);
  $attribute_select1 = $ssym_ctl->attribute_select1(Rinchi::CIGIPP->None);
  $attribute_select2 = $ssym_ctl->attribute_select2(Rinchi::CIGIPP->None);
  $attribute_value1 = $ssym_ctl->attribute_value1(8789);
  $attribute_value2 = $ssym_ctl->attribute_value2(27011);

=head1 DESCRIPTION

The Short Symbol Control packet is provided as a lower-bandwidth alternative to 
the Symbol Control packet (CIGI ICD Section 4.1.33). It can be used when 
manipulation of only one or two symbol attributes of a symbol are necessary.

This packet allows for up to two symbol attributes to be modified. The 
attributes are specified by the Attribute Select 1 and Attribute Select 2 
attributes. The values of these attributes determine what data types are used 
to interpret the Attribute Value 1 and Attribute Value 2 attributes, 
respectively.
A symbol must be defined before the Host sends a Short Symbol Control packet 
referencing that symbol. Symbols may be predefined by the IG or may be created 
by the Host sending any one of the symbol definition packets.

Before the Host can send a Short Symbol Control referencing a symbol, the Host 
must first send a Symbol Control packet referencing that symbol so that all of 
the symbol's attributes can be set.

=head2 EXPORT

None by default.

#==============================================================================

=item new $ssym_ctl = Rinchi::CIGIPP::ShortSymbolControl->new()

Constructor for Rinchi::ShortSymbolControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b15b8-200e-11de-bdc5-001c25551abc',
    '_Pack'                                => 'CCSCCCCff',
    '_Swap1'                               => 'CCvCCCCVV',
    '_Swap2'                               => 'CCnCCCCNN',
    'packetType'                           => 35,
    'packetSize'                           => 16,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused63, inheritColor, flashControl, attachState, and symbolState.
    'inheritColor'                         => 0,
    'flashControl'                         => 0,
    'attachState'                          => 0,
    'symbolState'                          => 0,
    '_unused64'                            => 0,
    'attributeSelect1'                     => 0,
    'attributeSelect2'                     => 0,
    'attributeValue1'                      => 0,
    'attributeValue2'                      => 0,
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

 $value = $ssym_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Short Symbol Control packet. 
The value of this attribute must be 35.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $ssym_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub symbol_ident([$newValue])

 $value = $ssym_ctl->symbol_ident($newValue);

Symbol ID.

This attribute specifies the symbol to which this packet is applied. This value 
must be unique for each active symbol.

=cut

sub symbol_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'symbolIdent'} = $nv;
  }
  return $self->{'symbolIdent'};
}

#==============================================================================

=item sub inherit_color([$newValue])

 $value = $ssym_ctl->inherit_color($newValue);

Inherit Color.

This attribute specifies whether this symbol inherits its color from the symbol 
to which it is attached. If color is inherited, then this symbol's color, 
including the alpha component, is identical to the current color of the parent 
symbol. Note that the current color of the parent symbol may be inherited from 
another symbol.

If Attach State is set to Detach (0), this attribute is ignored.

    NotInherited   0
    Inherited      1

=cut

sub inherit_color() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'inheritColor'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "inherit_color must be 0 (NotInherited), or 1 (Inherited).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub flash_control([$newValue])

 $value = $ssym_ctl->flash_control($newValue);

Flash Control.

This attribute specifies whether the flash cycle is continued from its present 
point or whether it is restarted at the beginning.

This attribute is ignored if either Flash Duty Cycle Percentage or Flash Period 
is changed. This attribute may also be ignored if Flash Duty Cycle Percentage 
is set to 0 or 100.

    ContinueFlash   0
    RestartFlash    1

=cut

sub flash_control() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'flashControl'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "flash_control must be 0 (ContinueFlash), or 1 (RestartFlash).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub attach_state([$newValue])

 $value = $ssym_ctl->attach_state($newValue);

Attach State.

This attribute specifies whether the symbol should be attached as a child to a 
parent symbol.

If this attribute is set to Detach (0), then the symbol becomes or remains a 
top-level (non-child) symbol. The Parent Symbol attribute is ignored. The U 
Position, V Position, and Rotation attributes specify the symbol's position and 
rotation relative to the symbol surface's local coordinate system (see Section 
3.4.5.1).
If this attribute is set to Attach (1), then the symbol becomes or remains 
attached to the symbol specified by the Parent Symbol ID attribute. The U 
Position, V Position, and Rotation attributes specify the symbol's position and 
rotation relative to the parent symbol's local coordinate system (see Section 
3.4.5.2).
The attach state of a symbol may be changed at any time. The attachment or 
detachment takes place immediately and remains in effect until changed with 
another Symbol Control packet or Short Symbol Control packet.

    Detach   0
    Attach   1

=cut

sub attach_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'attachState'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "attach_state must be 0 (Detach), or 1 (Attach).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub symbol_state([$newValue])

 $value = $ssym_ctl->symbol_state($newValue);

Symbol State.

This attribute specifies whether the symbol should be hidden, visible, or 
destroyed. This attribute may be set to one of the following values:

Hidden – The symbol is hidden from view; however, it can be positioned, 
rotated, and scaled. It can also be attached to another symbol as a child. It 
can also be used as a parent by other symbols, although any children are also 
hidden.
Visible – The symbol is drawn on the surface. It can be positioned, rotated, 
and scaled. It can also be attached to another symbol as a child. It can also 
be used as a parent by other symbols.

Destroyed – The symbol is deleted and any system resources are freed. Any 
children are also destroyed. All other attributes in this packet are ignored.

Note: Although the Symbol Control packet supports destruction of symbols, it is 
recommended that the Short Symbol Control packet be used for this purpose since 
all other attributes are ignored.

    Hidden      0
    Visible     1
    Destroyed   2

=cut

sub symbol_state() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2)) {
      $self->{'symbolState'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x03;
    } else {
      carp "symbol_state must be 0 (Hidden), 1 (Visible), or 2 (Destroyed).";
    }
  }
  return ($self->{'_bitfields1'} & 0x03);
}

#==============================================================================

=item sub attribute_select1([$newValue])

 $value = $ssym_ctl->attribute_select1($newValue);

Attribute Select 1.

This attribute identifies the attribute whose value is specified in the 
Attribute Value 1 field.

If this attribute is set to None (0), then Attribute Value 1 is ignored.

    None                0
    SurfaceIdent        1
    ParentSymbolIdent   2
    Layer               3
    FlashDutyCycle      4
    FlashPeriod         5
    PositionU           6
    PositionV           7
    Rotation            8
    Color               9
    ScaleU              10
    ScaleV              11

=cut

sub attribute_select1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7) or ($nv==8) or ($nv==9) or ($nv==10) or ($nv==11)) {
      $self->{'attributeSelect1'} = $nv;
      if($nv >= 5 and $nv <= 10 and $nv !=9) {
        substr($self->{'_Pack'},7,1) = 'f';
      } else {
        substr($self->{'_Pack'},7,1) = 'I';
      }
    } else {
      carp "attribute_select1 must be 0 (None), 1 (SurfaceIdent), 2 (ParentSymbolIdent), 3 (Layer), 4 (FlashDutyCycle), 5 (FlashPeriod), 6 (PositionU), 7 (PositionV), 8 (Rotation), 9 (Color), 10 (ScaleU), or 11 (ScaleV).";
    }
  }
  return $self->{'attributeSelect1'};
}

#==============================================================================

=item sub attribute_select2([$newValue])

 $value = $ssym_ctl->attribute_select2($newValue);

Attribute Select 2.

This attribute identifies the attribute whose value is specified in the 
Attribute Value 2 field.

If this attribute is set to None (0), then Attribute Value 2 is ignored.

    None                0
    SurfaceIdent        1
    ParentSymbolIdent   2
    Layer               3
    FlashDutyCycle      4
    FlashPeriod         5
    PositionU           6
    PositionV           7
    Rotation            8
    Color               9
    ScaleU              10
    ScaleV              11

=cut

sub attribute_select2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7) or ($nv==8) or ($nv==9) or ($nv==10) or ($nv==11)) {
      $self->{'attributeSelect2'} = $nv;
      if($nv >= 5 and $nv <= 10 and $nv !=9) {
        substr($self->{'_Pack'},8,1) = 'f';
      } else {
        substr($self->{'_Pack'},8,1) = 'I';
      }
    } else {
      carp "attribute_select2 must be 0 (None), 1 (SurfaceIdent), 2 (ParentSymbolIdent), 3 (Layer), 4 (FlashDutyCycle), 5 (FlashPeriod), 6 (PositionU), 7 (PositionV), 8 (Rotation), 9 (Color), 10 (ScaleU), or 11 (ScaleV).";
    }
  }
  return $self->{'attributeSelect2'};
}

#==============================================================================

=item sub attribute_value1([$newValue])

 $value = $ssym_ctl->attribute_value1($newValue);

Attribute Value 1.

This attribute specifies the value of the attribute identified by the Attribute 
Select 1 field.

If Attribute Select 1 is set to Surface ID (1), Parent Symbol ID (2), Layer 
(3), or Flash Duty Cycle Percentage (4), then Attribute Value 1 is treated as a 
32-bit integer.

If Attribute Select 1 is set to Flash Period (5), Position U (6), Position V 
(7), Rotation (8), Scale V (10), or Scale V (11), then Attribute Value 1 is 
treated as a 32-bit single-precision floating-point number.

If Attribute Select 1 is Color (9), then Attribute Value 1 is treated as four 
8-bit integers specifying each of the four color components. The most 
significant byte specifies the red component, followed by the blue component, 
then green, and finally alpha.

Regardless of the attribute, the IG will byte-swap this attribute as a 32-bit 
value if byte-swapping is required.

=cut

sub attribute_value1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'attributeValue1'} = $nv;
  }
  return $self->{'attributeValue1'};
}

#==============================================================================

=item sub attribute_value2([$newValue])

 $value = $ssym_ctl->attribute_value2($newValue);

Attribute Value 2.

This attribute specifies the value of the attribute identified by the Attribute 
Select 2 field.

If Attribute Select 2 is set to Surface ID (1), Parent Symbol ID (2), Layer 
(3), or Flash Duty Cycle Percentage (4), then Attribute Value 2 is treated as a 
32-bit integer.

If Attribute Select 2 is set to Flash Period (5), Position U (6), Position V 
(7), Rotation (8), Scale V (10), or Scale V (11), then Attribute Value 2 is 
treated as a 32-bit single-precision floating-point number.

If Attribute Select 2 is Color (9), then Attribute Value 2 is treated as four 
8-bit integers specifying each of the four color components. The most 
significant byte specifies the red component, followed by the blue component, 
then green, and finally alpha.

Regardless of the attribute, the IG will byte-swap this attribute as a 32-bit 
value if byte-swapping is required.

=cut

sub attribute_value2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'attributeValue2'} = $nv;
  }
  return $self->{'attributeValue2'};
}

#==========================================================================

=item sub pack()

 $value = $ssym_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused63, inheritColor, flashControl, attachState, and symbolState.
        $self->{'_unused64'},
        $self->{'attributeSelect1'},
        $self->{'attributeSelect2'},
        $self->{'attributeValue1'},
        $self->{'attributeValue2'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $ssym_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  if($f >= 5 and $f <=10 and $f !=9) {
    $h = CORE::unpack('f',substr($self->{'_Buffer'},8));
    $self->{'_Pack'} = 'CCSCCCCf';
  } else {
    $h = CORE::unpack('I',substr($self->{'_Buffer'},8));
    $self->{'_Pack'} = 'CCSCCCCI';
  }
  if($g >= 5 and $g <=10 and $g !=9) {
    $i = CORE::unpack('f',substr($self->{'_Buffer'},12));
    $self->{'_Pack'} .= 'f';
  } else {
    $i = CORE::unpack('I',substr($self->{'_Buffer'},12));
    $self->{'_Pack'} .= 'I';
  }

  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'symbolIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused63, inheritColor, flashControl, attachState, and symbolState.
  $self->{'_unused64'}                           = $e;
  $self->{'attributeSelect1'}                    = $f;
  $self->{'attributeSelect2'}                    = $g;
  $self->{'attributeValue1'}                     = $h;
  $self->{'attributeValue2'}                     = $i;

  $self->{'inheritColor'}                        = $self->inherit_color();
  $self->{'flashControl'}                        = $self->flash_control();
  $self->{'attachState'}                         = $self->attach_state();
  $self->{'symbolState'}                         = $self->symbol_state();

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
