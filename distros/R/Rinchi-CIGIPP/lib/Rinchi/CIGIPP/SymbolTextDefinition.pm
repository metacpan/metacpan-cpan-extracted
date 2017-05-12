#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b0320-200e-11de-bdbe-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolTextDefinition;

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

Rinchi::CIGIPP::SymbolTextDefinition - Perl extension for the Common Image 
Generator Interface - Symbol Text Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolTextDefinition;
  my $sym_text = Rinchi::CIGIPP::SymbolTextDefinition->new();

  $packet_type = $sym_text->packet_type();
  $packet_size = $sym_text->packet_size(243);
  $symbol_ident = $sym_text->symbol_ident(29183);
  $orientation = $sym_text->orientation(Rinchi::CIGIPP->LeftToRight);
  $alignment = $sym_text->alignment(Rinchi::CIGIPP->TopCenter);
  $font_ident = $sym_text->font_ident(Rinchi::CIGIPP->IGDefault);
  $font_size = $sym_text->font_size(83.754);
  $text = $sym_text->text("Hello World!");

=head1 DESCRIPTION

The Symbol Text Definition packet is used to define a string of text, as well 
as its alignment, orientation, font, and size.

Each text symbol is identified by a Symbol ID value that is unique from all 
other symbols (text or otherwise). Every symbol must be created independently 
with its own unique Symbol ID, even if two or more symbols are visually 
identical.
Once a Symbol Text Definition packet describing a text symbol is sent to the 
IG, the definition of that symbol will not change. If any Symbol Text 
Definition, Symbol Circle Definition, Symbol Line Definition, or Symbol Clone 
packet specifying the same Symbol ID is then received, the existing symbol will 
be destroyed along with any children and a new symbol will be created using the 
new definition packet.

The Font ID attribute uniquely identifies a specific font and is defined by the 
IG. A font is a unique combination of typeface, style (such as italic), and 
weight (such as bold). Therefore, any special attribute of the font such as 
bold or italics shall be identified using a separate Font ID. Table 37 defines 
several default font styles; however, the exact typeface is IG-dependent. All 
other font assignments are IG-defined.

Font size is defined as the vertical space that a font occupies. This includes 
the cap height as well as the heights of any ascenders, descenders, accent 
marks, and vertical padding.

The text string is composed of multiple UTF-8 character data. The text must be 
terminated by NULL, or zero (0). If the terminating byte is not the last byte 
before an eight-byte boundary, then the remainder of the packet must be padded 
with zeroes up to the next eight-byte boundary. Zero-length text strings must 
be terminated with four bytes containing NULL to maintain eight-byte alignment. 
The maximum text length is dependent upon the sizes of the individual UTF-8 
character data and, therefore, to a large extent, the language being used.

The Packet Size attribute must contain the number of bytes up to and including 
the Font Size attribute (a total of 12 bytes) and the total number of bytes 
within the text, including the terminating NULL and any padding. This value 
must be an even multiple of eight (8). For example, if the string "Hello 
World!" were sent to the IG, the packet size would be 12 + 24, or 32 bytes. 

When the IG creates a new symbol, that symbol is always hidden by default. The 
symbol is not made visible until the Host sends a Symbol Control packet or 
Short Symbol Control packet with the Symbol State attribute set to Visible (1).

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_text = Rinchi::CIGIPP::SymbolTextDefinition->new()

Constructor for Rinchi::SymbolTextDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b0320-200e-11de-bdbe-001c25551abc',
    '_Pack'                                => 'CCSCCSf',
    '_Swap1'                               => 'CCvCCvV',
    '_Swap2'                               => 'CCnCCnN',
    'packetType'                           => 30,
    'packetSize'                           => 16,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields orientation, and alignment.
    'orientation'                          => 0,
    'alignment'                            => 0,
    'fontIdent'                            => 0,
    '_unused54'                            => 0,
    'fontSize'                             => 0,
    'text'                                 => '',
    '_pad'                                 => "\0\0\0\0",
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

 $value = $sym_text->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Text Definition 
packet. The value of this attribute must be 30.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size([$newValue])

 $value = $sym_text->packet_size($newValue);

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be an even multiple of 8 ranging from 16 to 248.

=cut

sub packet_size() {
  my ($self,$nv) = @_;
#  if (defined($nv)) {
#    $self->{'packetSize'} = $nv;
#  }
  return $self->{'packetSize'};
}

#==============================================================================

=item sub symbol_ident([$newValue])

 $value = $sym_text->symbol_ident($newValue);

Symbol ID.

This attribute specifies the identifier of the symbol that is being defined.

This identifier must be unique among all existing symbols. If a symbol with the 
specified identifier already exists, then that symbol and any children will be 
destroyed and a new symbol created.

=cut

sub symbol_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'symbolIdent'} = $nv;
  }
  return $self->{'symbolIdent'};
}

#==============================================================================

=item sub orientation([$newValue])

 $value = $sym_text->orientation($newValue);

Orientation.

This attribute specifies the orientation of the text.

    LeftToRight   0
    TopToBottom   1
    RightToLeft   2
    BottomToTop   3

=cut

sub orientation() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'orientation'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x30;
    } else {
      carp "orientation must be 0 (LeftToRight), 1 (TopToBottom), 2 (RightToLeft), or 3 (BottomToTop).";
    }
  }
  return (($self->{'_bitfields1'} & 0x30) >> 4);
}

#==============================================================================

=item sub alignment([$newValue])

 $value = $sym_text->alignment($newValue);

Alignment.

This attribute specifies the position of the symbol's reference point in 
relation to the text. If the text has multiple lines, this attribute also 
determines whether the text is left-, center-, or right-justified.

    TopLeft        0
    TopCenter      1
    TopRight       2
    CenterLeft     3
    Center         4
    CenterRight    5
    BottomLeft     6
    BottomCenter   7
    BottomRight    8

=cut

sub alignment() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7) or ($nv==8)) {
      $self->{'alignment'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x0F;
    } else {
      carp "alignment must be 0 (TopLeft), 1 (TopCenter), 2 (TopRight), 3 (CenterLeft), 4 (Center), 5 (CenterRight), 6 (BottomLeft), 7 (BottomCenter), or 8 (BottomRight).";
    }
  }
  return ($self->{'_bitfields1'} & 0x0F);
}

#==============================================================================

=item sub font_ident([$newValue])

 $value = $sym_text->font_ident($newValue);

Font ID.

This attribute specifies the font to be used for this text symbol.

This document defines a set of default proportional (variable-width) and 
monospace (constant-width) font styles for interoperability; however, the exact 
typefaces used will be IG-dependent.

Font IDs 17 through 255 are entirely IG-defined.

    IGDefault                         0
    ProportionalSansSerif             1
    ProportionalSanSerifBold          2
    ProportionalSansSerifItalic       3
    ProportionalSansSerifBoldItalic   4
    ProportionalSerif                 5
    ProportionalSerifBold             6
    ProportionalSerifItalic           7
    ProportionalSerifBoldItalic       8
    MonospaceSansSerif                9
    MonospaceSansSerifBold            10
    MonospaceSansSerifItalic          11
    MonospaceSansSerifBoldItalic      12
    MonospaceSerif                    13
    MonospaceSerifBold                14
    MonospaceSerifItalic              15
    MonospaceSerifBoldItalic          16

=cut

sub font_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6) or ($nv==7) or ($nv==8) or ($nv==9) or ($nv==10) or ($nv==11) or ($nv==12) or ($nv==13) or ($nv==14) or ($nv==15) or ($nv==16)) {
      $self->{'fontIdent'} = $nv;
    } else {
      carp "font_ident must be 0 (IGDefault), 1 (ProportionalSansSerif), 2 (ProportionalSanSerifBold), 3 (ProportionalSansSerifItalic), 4 (ProportionalSansSerifBoldItalic), 5 (ProportionalSerif), 6 (ProportionalSerifBold), 7 (ProportionalSerifItalic), 8 (ProportionalSerifBoldItalic), 9 (MonospaceSansSerif), 10 (MonospaceSansSerifBold), 11 (MonospaceSansSerifItalic), 12 (MonospaceSansSerifBoldItalic), 13 (MonospaceSerif), 14 (MonospaceSerifBold), 15 (MonospaceSerifItalic), or 16 (MonospaceSerifBoldItalic).";
    }
  }
  return $self->{'fontIdent'};
}

#==============================================================================

=item sub font_size([$newValue])

 $value = $sym_text->font_size($newValue);

Font Size.

This attribute specifies the font size in terms of the vertical units defined 
by the symbol surface's 2D coordinate system (see CIGI ICD Section 3.4.5.1).

=cut

sub font_size() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'fontSize'} = $nv;
  }
  return $self->{'fontSize'};
}

#==============================================================================

=item sub text([$newValue])

 $value = $sym_text->text($newValue);

Text.

These 8-bit data are used to store the UTF-8 code points in the string.

Note: The maximum length of the string, including a terminating NULL, is 236 
bytes. The pack method will add terminating and padding NULLs as needed.

=cut

sub text() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    my $len = length($nv);
    if ($len < 236) {
      $self->{'text'} = $nv; 
      $self->{'_pad'} = substr("\0\0\0\0\0\0\0\0",(($len+4)%8));
      $self->{'packetSize'} = $len + 12 + length($self->{'_pad'});
    } else {
      carp "New value exceeds 235 bytes";
    }
  }
  return $self->{'text'};
}

#==========================================================================

=item sub pack()

 $value = $sym_text->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused53, orientation, and alignment.
        $self->{'fontIdent'},
        $self->{'_unused54'},
        $self->{'fontSize'}
      ) . $self->{'text'} . $self->{'_pad'};

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sym_text->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  my $h = substr($self->{'_Buffer'},12);
  $h =~ s/(\0+)$//;
  my $i = $1;
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'symbolIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused53, orientation, and alignment.
  $self->{'fontIdent'}                           = $e;
  $self->{'_unused54'}                           = $f;
  $self->{'fontSize'}                            = $g;
  $self->{'text'}                                = $h;
  $self->{'_pad'}                                = $i;

  $self->{'orientation'}                         = $self->orientation();
  $self->{'alignment'}                           = $self->alignment();

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
  my $padded_text = substr($self->{'_Buffer'},12);

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g) . $padded_text;
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
