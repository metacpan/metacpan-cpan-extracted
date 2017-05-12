#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b1310-200e-11de-bdc4-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolControl;

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

Rinchi::CIGIPP::SymbolControl - Perl extension for the Common Image Generator 
Interface - Symbol Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolControl;
  my $sym_ctl = Rinchi::CIGIPP::SymbolControl->new();

  $packet_type = $sym_ctl->packet_type();
  $packet_size = $sym_ctl->packet_size();
  $symbol_ident = $sym_ctl->symbol_ident(44253);
  $inherit_color = $sym_ctl->inherit_color(Rinchi::CIGIPP->NotInherited);
  $flash_control = $sym_ctl->flash_control(Rinchi::CIGIPP->RestartFlash);
  $attach_state = $sym_ctl->attach_state(Rinchi::CIGIPP->Attach);
  $symbol_state = $sym_ctl->symbol_state(Rinchi::CIGIPP->Visible);
  $parent_symbol_ident = $sym_ctl->parent_symbol_ident(18590);
  $surface_ident = $sym_ctl->surface_ident(34382);
  $layer = $sym_ctl->layer(40);
  $flash_duty_cycle = $sym_ctl->flash_duty_cycle(84);
  $flash_period = $sym_ctl->flash_period(16.565);
  $position_u = $sym_ctl->position_u(77.791);
  $position_v = $sym_ctl->position_v(26.596);
  $rotation = $sym_ctl->rotation(36.297);
  $red = $sym_ctl->red(61);
  $green = $sym_ctl->green(0);
  $blue = $sym_ctl->blue(203);
  $alpha = $sym_ctl->alpha(39);
  $scale_u = $sym_ctl->scale_u(60.944);
  $scale_v = $sym_ctl->scale_v(75.746);

=head1 DESCRIPTION

The Symbol Control packet is used to specify position, rotation, and other 
attributes describing a symbol's state.

A symbol must be defined before the Host sends a Symbol Control packet 
referencing that symbol. Symbols may be predefined by the IG or may be created 
by the Host sending any one of the symbol definition packets.

Each symbol is identified by a unique Symbol ID value. When the IG receives a 
Symbol Control packet, the packet will be applied to the symbol corresponding 
to the specified symbol ID. If a symbol with that ID does not exist, then the 
IG will ignore the packet. Each symbol must be created independently with its 
own unique Symbol ID value even if two visually identical symbols are used.

Symbols can be attached to one another in a hierarchical relationship. In such 
a hierarchy, a child symbol's position and rotation are specified relative to 
its parent symbol's local coordinate system. The Host needs only to control the 
parent symbol's position and rotation in order to move all lower symbols in the 
hierarchy as a group. No explicit manipulation of a child symbol's position and 
rotation is necessary unless its position and rotation change with respect to 
its parent. Additionally, a child symbol may inherit certain display states 
from its parent.

The Attach State attribute of the Symbol Control packet determines whether a 
symbol is attached to a parent. If this attribute is set to Attach (1), the 
symbol is attached to the symbol specified by the Parent Symbol ID attribute.

The Symbol State field is used to control when a symbol is visible and when a 
symbol's geometry is unloaded. When a symbol is created, that symbol is hidden 
until the Host sends a Symbol Control packet with the Symbol State field set to 
Visible (1). Any immediate children of that symbol either remain hidden or 
become visible depending upon their individual states. The symbol and all of 
its children can be hidden at any time by setting Symbol State to Hidden (0). 
When the Symbol is no longer needed, Symbol State can be set to Destroyed (2) 
to direct the IG to unload the symbol and free any associated resources. Any 
children attached to the symbol are also destroyed.

The Red, Blue, Green, and Alpha attributes define the color and transparency of 
a symbol. Alternatively, child symbols may inherit these values directly from 
their parents. If the Inherit Color attribute is set to Inherited (1), then the 
Red, Blue, Green, and Alpha attributes are ignored and the values of the parent 
are used. The Inherit Color attribute is ignored for top-level (i.e., root) 
symbols.
A symbol may flash or blink as determined by the Flash Period and Flash Duty 
Cycle Percentage attributes. The Flash Period attribute specifies the amount of 
time between two consecutive flashes. The Flash Duty Cycle Percentage attribute 
specifies the percentage of each flash cycle that the symbol is visible. If 
this attribute is set to 100%, then no flashing occurs and the symbol is always 
visible.
If a symbol's duty cycle is less than 100%, then any descendents (child 
symbols, grandchildren, etc.) will inherit the symbol's duty cycle and flash 
period. The Flash Duty Cycle Percentage and Flash Period attributes of the 
descendents will be ignored. If a symbol flashes, then any descendents will 
flash in synchronization with that symbol.

If a symbol's flash period or duty cycle is changed, then that symbol's flash 
cycle will be restarted.

A symbol may be moved without resetting its flash cycle. If a Symbol Control 
packet's Flash Control attribute is set to Continue (0), and if the Flash 
Period and Flash Duty Cycle Percentage attributes have not changed for the 
given symbol, then the symbol's flash cycle will not be reset. If the Flash 
Control attribute is set to Reset (1), then the symbol's flash cycle will be 
restarted from the beginning.

The drawing order of symbols is determined by layer. Each symbol surface has 
256 logical layers, which are rendered in order of increasing layer number. In 
other words, symbols assigned to Layer 0 are drawn first, followed by the 
symbols on Layer 1, then those on Layer 2, etc. Symbols on higher-numbered 
layers may occult those on any lower-numbered layers. Symbols assigned to the 
same layer will be drawn in order of increasing symbol ID.

The position of a top-level (root) symbol is always specified with respect to 
the surface's 2D coordinate system (see Section 3.4.5.1). The position of a 
child symbol is always specified with respect to the parent symbol's local 
coordinate system (see CIGI ICD Section 3.4.5.2).

The Scale U and Scale V attributes specify a symbol's scale along the symbol's 
local U and V axes, respectively. The symbol's apparent size is also affected 
by any ancestors' scaling factors as described in CIGI ICD Section 3.4.5.2.

Once a Symbol Control packet is sent to the IG, the state of the specified 
symbol will not change again until another Symbol Control or Short Symbol 
Control packet containing the same Symbol ID value is received, or until the 
symbol is implicitly deleted.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_ctl = Rinchi::CIGIPP::SymbolControl->new()

Constructor for Rinchi::SymbolControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b1310-200e-11de-bdc4-001c25551abc',
    '_Pack'                                => 'CCSCCSSCCffffCCCCff',
    '_Swap1'                               => 'CCvCCvvCCVVVVCCCCVV',
    '_Swap2'                               => 'CCnCCnnCCNNNNCCCCNN',
    'packetType'                           => 34,
    'packetSize'                           => 40,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused61, inheritColor, flashControl, attachState, and symbolState.
    'inheritColor'                         => 0,
    'flashControl'                         => 0,
    'attachState'                          => 0,
    'symbolState'                          => 0,
    '_unused62'                            => 0,
    'parentSymbolIdent'                    => 0,
    'surfaceIdent'                         => 0,
    'layer'                                => 0,
    'flashDutyCycle'                       => 0,
    'flashPeriod'                          => 0,
    'positionU'                            => 0,
    'positionV'                            => 0,
    'rotation'                             => 0,
    'red'                                  => 0,
    'green'                                => 0,
    'blue'                                 => 0,
    'alpha'                                => 0,
    'scaleU'                               => 0,
    'scaleV'                               => 0,
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

 $value = $sym_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Control packet. The 
value of this attribute must be 34.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sym_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 40.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub symbol_ident([$newValue])

 $value = $sym_ctl->symbol_ident($newValue);

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

 $value = $sym_ctl->inherit_color($newValue);

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

 $value = $sym_ctl->flash_control($newValue);

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

 $value = $sym_ctl->attach_state($newValue);

Attach State.

This attribute specifies whether the symbol should be attached as a child to a 
parent symbol.

If this attribute is set to Detach (0), then the symbol becomes or remains a 
top-level (non-child) symbol. The Parent Symbol attribute is ignored. The U 
Position, V Position, and Rotation attributes specify the symbol's position and 
rotation relative to the symbol surface's local coordinate system (see CIGI ICD 
Section 3.4.5.1).

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

 $value = $sym_ctl->symbol_state($newValue);

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

=item sub parent_symbol_ident([$newValue])

 $value = $sym_ctl->parent_symbol_ident($newValue);

Parent Symbol ID.

This attribute specifies the parent for the symbol. If the Attach State 
attribute is set to Detach (0), this attribute is ignored.

The value of this attribute may be changed without first detaching the symbol 
from its existing parent.

If the specified parent symbol is invalid, no change in the attachment will be made.

=cut

sub parent_symbol_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'parentSymbolIdent'} = $nv;
  }
  return $self->{'parentSymbolIdent'};
}

#==============================================================================

=item sub surface_ident([$newValue])

 $value = $sym_ctl->surface_ident($newValue);

Surface ID.

This attribute specifies the symbol surface on which the symbol is drawn.

If the symbol is a child, then the top-level parent symbol's surface is used 
and this attribute is ignored.

If the specified surface is invalid and this symbol is not a child, then the 
symbol will not be drawn.

=cut

sub surface_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'surfaceIdent'} = $nv;
  }
  return $self->{'surfaceIdent'};
}

#==============================================================================

=item sub layer([$newValue])

 $value = $sym_ctl->layer($newValue);

Layer.

This attribute specifies the layer to which the symbol is assigned. Layers are 
drawn in order of increasing layer number. For example, Layer 0 will be drawn 
first, followed by Layer 1, etc. Symbols on higher-numbered layers may occlude 
symbols on lower-numbered layers. If two or more symbols occupy the same layer, 
then the symbols are drawn in order of increasing symbol ID.

Note that any two siblings in a symbol hierarchy may or may not be assigned to 
the same layer or to adjacent layers.

=cut

sub layer() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'layer'} = $nv;
  }
  return $self->{'layer'};
}

#==============================================================================

=item sub flash_duty_cycle([$newValue])

 $value = $sym_ctl->flash_duty_cycle($newValue);

Flash Duty Cycle Percentage.

This attribute specifies the duty cycle for a flashing symbol. This is the 
percentage of one flash cycle that the symbol will be visible.

If this value is set to zero (0), then the symbol is always invisible. If this 
value is set to 100%, then the symbol is always visible.

This attribute is ignored if this symbol inherits flashing behavior.

=cut

sub flash_duty_cycle() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'flashDutyCycle'} = $nv;
  }
  return $self->{'flashDutyCycle'};
}

#==============================================================================

=item sub flash_period([$newValue])

 $value = $sym_ctl->flash_period($newValue);

Flash Period.

This attribute specifies the duration of a single flash cycle.

This attribute is ignored if Flash Duty Cycle Percentage is set to 0% or 100%.

This attribute is ignored if the symbol inherits its flashing behavior from its parent.

=cut

sub flash_period() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'flashPeriod'} = $nv;
  }
  return $self->{'flashPeriod'};
}

#==============================================================================

=item sub position_u([$newValue])

 $value = $sym_ctl->position_u($newValue);

Position U.

This attribute specifies the U component of the symbol's position.

For top-level (non-child) symbols, this position is defined with respect to the 
symbol surface's 2D coordinate system as described in CIGI ICD Section 3.4.5.1.

For child symbols, this position is defined with respect to the parent symbol's 
local coordinate system as described in CIGI ICD Section 3.4.5.2.

=cut

sub position_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'positionU'} = $nv;
  }
  return $self->{'positionU'};
}

#==============================================================================

=item sub position_v([$newValue])

 $value = $sym_ctl->position_v($newValue);

Position V.

This attribute specifies the V component of the symbol's position.

For top-level (non-child) symbols, this position is defined with respect to the 
symbol surface's 2D coordinate system as described in CIGI ICD Section 3.4.5.1.

For child symbols, this position is defined with respect to the parent symbol's 
local coordinate system as described in Section 3.4.5.2.

=cut

sub position_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'positionV'} = $nv;
  }
  return $self->{'positionV'};
}

#==============================================================================

=item sub rotation([$newValue])

 $value = $sym_ctl->rotation($newValue);

Rotation.

This attribute specifies a rotation for the symbol. This rotation is always 
counter-clockwise about the symbol's local origin.

Note that each child symbol is oriented relative to its parent's local 
coordinate system.

=cut

sub rotation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'rotation'} = $nv;
  }
  return $self->{'rotation'};
}

#==============================================================================

=item sub red([$newValue])

 $value = $sym_ctl->red($newValue);

Red.

This attribute specifies the red component of the symbol's color.

This value is ignored if Inherit Color is set to inherit (1).

=cut

sub red() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'red'} = $nv;
  }
  return $self->{'red'};
}

#==============================================================================

=item sub green([$newValue])

 $value = $sym_ctl->green($newValue);

Green.

This attribute specifies the green component of the symbol's color.

This value is ignored if Inherit Color is set to inherit (1).

=cut

sub green() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'green'} = $nv;
  }
  return $self->{'green'};
}

#==============================================================================

=item sub blue([$newValue])

 $value = $sym_ctl->blue($newValue);

Blue.

This attribute specifies the blue component of the symbol's color.

This value is ignored if Inherit Color is set to inherit (1).

=cut

sub blue() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'blue'} = $nv;
  }
  return $self->{'blue'};
}

#==============================================================================

=item sub alpha([$newValue])

 $value = $sym_ctl->alpha($newValue);

Alpha.

This attribute specifies the alpha component of the symbol's color. A value of 
zero (0) corresponds to fully transparent; a value of 255 corresponds to fully 
opaque.
This value is ignored if Inherit Color is set to inherit (1).

=cut

sub alpha() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'alpha'} = $nv;
  }
  return $self->{'alpha'};
}

#==============================================================================

=item sub scale_u([$newValue])

 $value = $sym_ctl->scale_u($newValue);

Scale U.

This attribute specifies the scaling factor of the symbol along the symbol's 
local U axis. A value less than 1.0 will cause the symbol to be reduced in 
size. A value greater than 1.0 will cause the symbol to be increased in size.

Note that a symbol's actual size and shape will be affected by the symbol's 
scaling factors, as well as those of any ancestor symbols.

=cut

sub scale_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'scaleU'} = $nv;
  }
  return $self->{'scaleU'};
}

#==============================================================================

=item sub scale_v([$newValue])

 $value = $sym_ctl->scale_v($newValue);

Scale V.

This attribute specifies the scaling factor of the symbol along the symbol's 
local V axis. A value less than 1.0 will cause the symbol to be reduced in 
size. A value greater than 1.0 will cause the symbol to be increased in size.

Note that a symbol's actual size and shape will be affected by the symbol's 
scaling factors, as well as those of any ancestor symbols.

=cut

sub scale_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'scaleV'} = $nv;
  }
  return $self->{'scaleV'};
}

#==========================================================================

=item sub pack()

 $value = $sym_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused61, inheritColor, flashControl, attachState, and symbolState.
        $self->{'_unused62'},
        $self->{'parentSymbolIdent'},
        $self->{'surfaceIdent'},
        $self->{'layer'},
        $self->{'flashDutyCycle'},
        $self->{'flashPeriod'},
        $self->{'positionU'},
        $self->{'positionV'},
        $self->{'rotation'},
        $self->{'red'},
        $self->{'green'},
        $self->{'blue'},
        $self->{'alpha'},
        $self->{'scaleU'},
        $self->{'scaleV'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sym_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                         = $a;
  $self->{'packetSize'}                         = $b;
  $self->{'symbolIdent'}                        = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused61, inheritColor, flashControl, attachState, and symbolState.
  $self->{'_unused62'}                           = $e;
  $self->{'parentSymbolIdent'}                  = $f;
  $self->{'surfaceIdent'}                       = $g;
  $self->{'layer'}                              = $h;
  $self->{'flashDutyCycle'}                     = $i;
  $self->{'flashPeriod'}                        = $j;
  $self->{'positionU'}                          = $k;
  $self->{'positionV'}                          = $l;
  $self->{'rotation'}                           = $m;
  $self->{'red'}                                = $n;
  $self->{'green'}                              = $o;
  $self->{'blue'}                               = $p;
  $self->{'alpha'}                              = $q;
  $self->{'scaleU'}                             = $r;
  $self->{'scaleV'}                             = $s;

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n,$o,$p,$q,$r,$s);
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
