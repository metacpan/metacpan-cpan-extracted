#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b05be-200e-11de-bdbf-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolCircleDefinition;

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

Rinchi::CIGIPP::SymbolCircleDefinition - Perl extension for the Common Image 
Generator Interface - Symbol Circle Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolCircleDefinition;
  my $sym_circ = Rinchi::CIGIPP::SymbolCircleDefinition->new();

  $packet_type = $sym_circ->packet_type();
  $packet_size = $sym_circ->packet_size(144);
  $symbol_ident = $sym_circ->symbol_ident(64120);
  $drawing_style = $sym_circ->drawing_style(Rinchi::CIGIPP->DrawingStyleLine);
  $stipple_pattern = $sym_circ->stipple_pattern(0x1F1F);
  $line_width = $sym_circ->line_width(1.125);
  $stipple_pattern_length = $sym_circ->stipple_pattern_length(21.99115);

  my $circle0 = Rinchi::CIGIPP::SymbolCircle->new();
  $sym_circ->circle(0, $circle0);
  $circle0->center_u(0.0);
  $circle0->center_v(0.0);
  $circle0->radius(7.0);
  $circle0->inner_radius(4.0);
  $circle0->start_angle(45);
  $circle0->end_angle(135);

  my $circle1 = Rinchi::CIGIPP::SymbolCircle->new();
  $sym_circ->circle(1, $circle1);
  $circle1->center_u(0.0);
  $circle1->center_v(0.0);
  $circle1->radius(10.0);
  $circle1->inner_radius(7.0);
  $circle1->start_angle(135);
  $circle1->end_angle(45);

=head1 DESCRIPTION

The Symbol Circle Definition packet is used to create a single circle or arc. 
This packet can also be used to create a composite symbol composed of up to 9 
circles and/or arcs. Note that this section uses the term "circle" to refer to 
both circles and arcs unless otherwise indicated.

Each circle symbol is identified by a Symbol ID value that is unique from all 
other symbols (including text and line symbols). Every symbol must be created 
independently with its own unique Symbol ID, even if two or more symbols are 
visually identical.

Once a Symbol Circle Definition packet describing a circle symbol is sent to 
the IG, that symbol's type may not be changed. If a Symbol Text Definition, 
Symbol Line Definition, or Symbol Clone packet is received specifying the same 
Symbol ID but a different type, then the existing circle symbol will be 
destroyed along with any children and a new symbol will be created using the 
new definition packet.

The center of each circle is located at a point (u, v) on the symbol's 2D 
coordinate system (see CIGI ICD Section 3.4.5.2) as defined by the Center U and 
Center V attributes. The radius of the circle is specified in scaled symbol 
surface units by the Radius attribute. Note that if the symbol surface's 2D 
coordinate system is defined such that horizontal units are not the same length 
as vertical units, then a circle will appear as an ellipse and an arc will 
appear as an elliptical arc.

The Start Angle and End Angle attributes define the endpoints of the curve. 
These angles are measured counter-clockwise from the symbol's +U axis. If these 
two values are equal, then the symbol defines a full circle. If these two 
values are not equal, then the symbol defines an arc. For circles, it is 
recommended that values of 0.0 be used for consistency and to avoid 
floating-point errors.

A circle can either be drawn as a curved line along the circumference or be 
filled, depending upon the value of the Drawing Style attribute. If Drawing 
Style is set to Line (0), then a curve is drawn from the start angle to the end 
angle with the specified Radius. The Inner Radius attribute is ignored.

A curved line's pen attributes are defined by the Line Width, Stipple Pattern, 
and Stipple Pattern Length attributes.

Line Width specifies the thickness of the line in scaled symbol surface units. 
Note that if the surface's horizontal and vertical units are not equal in size, 
then curved lines will not appear to be uniform in thickness. 

The Stipple Pattern attribute defines a bit mask to be applied to the line: if 
a bit is set (1) then the section of the curve corresponding to that bit will 
be drawn; if the bit is cleared (0) then the corresponding section will not be 
drawn. If the value of this attribute is 0xFFFF, then the line is solid.

The length of each section is equal to 1/16 of the length specified by the 
Stipple Pattern Length attribute. This attribute defines the length of the 
stipple pattern in terms of scaled symbol surface units. If the curved line is 
longer than the stipple pattern length, then the pattern is repeated.

Note that the end-cap style of a curved line is implementation-dependent and 
may optionally be controlled with a Component Control packet.

If Drawing Style is set to Fill (1), then the circle is drawn as a filled 
region defined by the Start Angle, End Angle, Radius, and Inner Radius 
attributes. Note that if the Inner Radius attribute is 0.0, then the circle is 
completely filled.

The Line Width, Stipple Pattern, and Stipple Pattern Length attributes are 
ignored for filled circle symbols.

When the IG creates a new symbol, that symbol is always hidden by default. The 
symbol is not made visible until the Host sends a Symbol Control packet or 
Short Symbol Control packet with the Symbol State attribute set to Visible (1).

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_circ = Rinchi::CIGIPP::SymbolCircleDefinition->new()

Constructor for Rinchi::SymbolCircleDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b05be-200e-11de-bdbf-001c25551abc',
    '_Pack'                                => 'CCSCCSff',
    '_Swap1'                               => 'CCvCCvVV',
    '_Swap2'                               => 'CCnCCnNN',
    'packetType'                           => 31,
    'packetSize'                           => 16,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused55, and drawingStyle.
    'drawingStyle'                         => 0,
    '_unused56'                            => 0,
    'stipplePattern'                       => 0,
    'lineWidth'                            => 0,
    'stipplePatternLength'                 => 0,
    '_circle'                              => [],
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

 $value = $sym_circ->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Circle Definition 
packet. The value of this attribute must be 31.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size([$newValue])

 $value = $sym_circ->packet_size($newValue);

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be an even multiple of 8 ranging from 16 to 232.

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

 $value = $sym_circ->symbol_ident($newValue);

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

=item sub drawing_style([$newValue])

 $value = $sym_circ->drawing_style($newValue);

Drawing Style.

This attribute specifies whether the circles and arcs defined in this packet 
are defined as curved lines or filled volumes.

    DrawingStyleLine   0
    DrawingStyleFill   1

=cut

sub drawing_style() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'drawingStyle'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "drawing_style must be 0 (DrawingStyleLine), or 1 (DrawingStyleFill).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub stipple_pattern([$newValue])

 $value = $sym_circ->stipple_pattern($newValue);

Stipple Pattern.

This attribute specifies the dash pattern used when drawing the curved line of 
a circle or arc.

Each curved line is divided into sections that are 1/32 of the length specified 
by the Stipple Pattern Length attribute. The stipple pattern is a bit mask that 
is used when drawing the sections. If a bit is set (1) then section 
corresponding to that bit will be drawn; if the bit is cleared (0) then the 
corresponding section will not be drawn.

If the value of this attribute is 0xFFFF, then the line will be solid.

If the line is longer than the stipple pattern length, the pattern is repeated.

This value is ignored if the Drawing Style attribute is set to Fill (1).

=cut

sub stipple_pattern() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'stipplePattern'} = $nv;
  }
  return $self->{'stipplePattern'};
}

#==============================================================================

=item sub line_width([$newValue])

 $value = $sym_circ->line_width($newValue);

Line Width.

This attribute specifies the thickness of the line used to draw the circles and 
arcs. This thickness is measured in symbol surface units and will be scaled if 
the symbol is scaled (see CIGI ICD Section 3.4.5.2).

Note that if the symbol surface's horizontal and vertical units are not the 
same size, then horizontal, diagonal, and vertical lines will not appear to be 
the same thickness.

This attribute is ignored if the Drawing Style attribute is set to Fill (1).

=cut

sub line_width() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'lineWidth'} = $nv;
  }
  return $self->{'lineWidth'};
}

#==============================================================================

=item sub stipple_pattern_length([$newValue])

 $value = $sym_circ->stipple_pattern_length($newValue);

Stipple Pattern Length.

This attribute specifies the length of one complete repetition of the stipple 
pattern. This length is measured in symbol surface units and will be scaled if 
the symbol is scaled (see CIGI ICD Section 3.4.5.2).

If a line is longer than the stipple pattern length, then the pattern is 
repeated along that line.

This attribute is ignored if the Drawing Style attribute is set to Fill (1).

=cut

sub stipple_pattern_length() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'stipplePatternLength'} = $nv;
  }
  return $self->{'stipplePatternLength'};
}

#==============================================================================

=item sub circle($index,[$newCircle])

 $circle = $sym_circ->circle($index,$newCircle);

Circle Array.

=cut

sub circle() {
  my ($self,$index,$nv) = @_;
  if (defined($index) and $index < 9) {
    if (defined($nv)) {
      $self->{'_circle'}[$index] = $nv;
      my $sz = 40 + 24 * $index;
      $self->{'packetSize'} = $sz if ($sz > $self->{'packetSize'});
    }
    return $self->{'_circle'}[$index];
  } else {
    return undef;
  }
}

#==========================================================================

=item sub pack()

 $value = $sym_circ->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused55, and drawingStyle.
        $self->{'_unused56'},
        $self->{'stipplePattern'},
        $self->{'lineWidth'},
        $self->{'stipplePatternLength'},
      );
  my $buffer = $self->{'_Buffer'};
  foreach my $circle (@{$self->{'_circle'}}) {
    $buffer .= $circle->pack();
  }

  return $buffer;
}

#==========================================================================

=item sub unpack()

 $value = $sym_circ->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;

  my $cbuffer;
  if (@_) {
    my $buf = shift @_;
    $self->{'_Buffer'} = substr($buf,0,16);
    $self->{'_circle'} = [];
    $cbuffer = substr($buf,16);
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'symbolIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused55, and drawingStyle.
  $self->{'_unused56'}                           = $e;
  $self->{'stipplePattern'}                      = $f;
  $self->{'lineWidth'}                           = $g;
  $self->{'stipplePatternLength'}                = $h;

  $self->{'drawingStyle'}                        = $self->drawing_style();

  my $index = 0;
  while(length($cbuffer) >= 24) {
    $self->circle($index,Rinchi::CIGIPP::SymbolCircle->new())unless (defined($self->circle($index)));
    $self->circle($index)->unpack(substr($cbuffer,0,24));
    $cbuffer = substr($cbuffer,24);
    $index++;
  }
  return $self->pack();
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
  foreach my $circle (@{$self->{'_circle'}}) {
    $circle->byte_swap();
  }

  $self->unpack();

  return $self->{'_Buffer'};
}

#==========================================================================

package Rinchi::CIGIPP::SymbolCircle;

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

#==============================================================================

=item new $circle = Rinchi::CIGIPP::SymbolCircle->new()

Constructor for Rinchi::SymbolCircle.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'c4ea6364-2795-11de-a5b1-001c25551abc',
    '_Pack'                                => 'ffffff',
    '_Swap1'                               => 'VVVVVV',
    '_Swap2'                               => 'NNNNNN',
    'centerU'                              => 0,
    'centerV'                              => 0,
    'radius'                               => 0,
    'innerRadius'                          => 0,
    'startAngle'                           => 0,
    'endAngle'                             => 0,
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

=item sub center_u([$newValue])

 $value = $circle->center_u($newValue);

Center U.

This attribute specifies the u position of the circle's center with 
respect to the symbol's local coordinate system. This position is 
measured in scaled symbol surface units (see CIGI ICD Section 3.4.5.2).

=cut

sub center_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'centerU'} = $nv
  }
  return $self->{'centerU'};
}

#==============================================================================

=item sub center_v([$newValue])

 $value = $circle->center_v($newValue);

Center V.

This attribute specifies the v position of the circle's center with 
respect to the symbol's local coordinate system. This position is 
measured in scaled symbol surface units (see CIGI ICD Section 3.4.5.2).

=cut

sub center_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'centerV'} = $nv
  }
  return $self->{'centerV'};
}

#==============================================================================

=item sub radius([$newValue])

 $value = $circle->radius($newValue);

Radius.

For a filled circle or arc, this attribute specifies the distance from 
the center of the circle to its outer circumference.

For a line circle or arc, this attribute specifies the distance from the 
center of the circle to the center ofthe curve.

This value is measured in scaled symbol surface units(see CIGI ICD 
Section 3.4.5.2).

=cut

sub radius() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'radius'} = $nv
  }
  return $self->{'radius'};
}

#==============================================================================

=item sub inner_radius([$newValue])

 $value = $circle->inner_radius($newValue);

Inner Radius.

For a filled circle or arc, this attribute specifies the distance from 
the center of the circle to its inner boundary in scaled symbol surface 
units (see CIGI ICD Section 3.4.5.2). The fill extends from the Inner 
Radius to the Radius.

For line circles and arcs, this attribute is ignored.

=cut

sub inner_radius() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'innerRadius'} = $nv
  }
  return $self->{'innerRadius'};
}

#==============================================================================

=item sub start_angle([$newValue])

 $value = $circle->start_angle($newValue);

Start Angle.

This attribute specifies the starting angle of the arc and is measured 
counter-clockwise from the +U axis.

If Start Angle is greater than End Angle, then the arc will cross the +U 
axis.

=cut

sub start_angle() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'startAngle'} = $nv
  }
  return $self->{'startAngle'};
}

#==============================================================================

=item sub end_angle([$newValue])

 $value = $circle->end_angle($newValue);

End Angle.

This attribute specifies the ending angle of the arc and is measured 
counter-clockwise from the +U axis.

If Start Angle is greater than End Angle, then the arc will cross the +U 
axis.

=cut

sub end_angle() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'endAngle'} = $nv
  }
  return $self->{'endAngle'};
}

#==========================================================================

=item sub pack()

 $value = $circle->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'centerU'},
        $self->{'centerV'},
        $self->{'radius'},
        $self->{'innerRadius'},
        $self->{'startAngle'},
        $self->{'endAngle'}
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $circle->unpack();

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
  $self->{'centerU'}                            = $a;
  $self->{'centerV'}                            = $b;
  $self->{'radius'}                             = $c;
  $self->{'innerRadius'}                        = $d;
  $self->{'startAngle'}                         = $e;
  $self->{'endAngle'}                           = $f;

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $circle->byte_swap();

Byte swaps the packed circle data.

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
