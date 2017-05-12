#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b0b0e-200e-11de-bdc1-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolLineDefinition;

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

Rinchi::CIGIPP::SymbolLineDefinition - Perl extension for the Common Image 
Generator Interface - Symbol Line Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolLineDefinition;
  my $sym_line = Rinchi::CIGIPP::SymbolLineDefinition->new();

  $packet_type = $sym_line->packet_type();
  $packet_size = $sym_line->packet_size(191);
  $symbol_ident = $sym_line->symbol_ident(19346);
  $primitive_type = $sym_line->primitive_type(Rinchi::CIGIPP->Point);
  $stipple_pattern = $sym_line->stipple_pattern(36348);
  $line_width = $sym_line->line_width(49.086);
  $stipple_pattern_length = $sym_line->stipple_pattern_length(16.425);

  my $vertex0 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(0, $vertex0);
  $vertex0->vertex_u(0.0);
  $vertex0->vertex_v(0.0);

  my $vertex1 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(1, $vertex1);
  $vertex1->vertex_u(10.0);
  $vertex1->vertex_v(0.0);

  my $vertex2 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(2, $vertex2);
  $vertex2->vertex_u(10.0);
  $vertex2->vertex_v(10.0);

  my $vertex3 = Rinchi::CIGIPP::SymbolVertex->new();
  $sym_line->vertex(3, $vertex3);
  $vertex3->vertex_u(20.0);
  $vertex3->vertex_v(10.0);

=head1 DESCRIPTION

The Symbol Line Definition packet is used to define a set of line segments or 
points. This packet can be used to create points, lines, a line strip, a line 
loop, triangles, a triangle strip, or a triangle fan. Note that this section 
includes all of these primitives when referring to "line symbols."

Each line symbol is identified by a Symbol ID value that is unique from all 
other symbols (including text and circle symbols). Every symbol must be created 
independently with its own unique Symbol ID, even if two or more symbols are 
visually identical.

Once a Symbol Line Definition packet describing a circle or composite symbol is 
sent to the IG, the definition of that symbol will not change. If any Symbol 
Text Definition, Symbol Circle Definition, Symbol Line Definition, or Symbol 
Clone packet specifying the same Symbol ID is then received, the existing 
symbol will be destroyed along with any children and a new symbol will be 
created using the new definition packet.

Every line symbol is defined as an ordered set of zero or more points. Each 
point is defined with respect to the symbol's 2D coordinate system (see CIGI 
ICD Section 3.4.5.2) by a pair of coordinates specified in the Vertex U and 
Vertex V attributes

The method and order by which the points are connected is determined by the 
Primitive Type attribute.

The pen attributes of each line comprising a line symbol are defined by the 
Line Width, Stipple Pattern, and Stipple Pattern Length attributes.

Line Width specifies the thickness of the line in scaled symbol surface units. 
Note that if the surface's horizontal and vertical units are not equal in size, 
then horizontal, diagonal, and vertical lines will not appear to be the same 
thickness.
The Stipple Pattern attribute defines a bit mask to be applied to the line: if 
a bit is set (1) then the section of the line corresponding to that bit will be 
drawn; if the bit is cleared (0) then the corresponding section will not be 
drawn. If the value of this attribute is 0xFFFF, then the line is solid.

The length of each section is equal to 1/32 of the length specified by the 
Stipple Pattern Length attribute. This attribute defines the length of the 
stipple pattern in terms of scaled symbol surface units. If the curved line is 
longer than the stipple pattern length, then the pattern is repeated.

The pen attributes are ignored for triangles, triangle strips, and triangle fans.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_line = Rinchi::CIGIPP::SymbolLineDefinition->new()

Constructor for Rinchi::SymbolLineDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b0b0e-200e-11de-bdc1-001c25551abc',
    '_Pack'                                => 'CCSCCSff',
    '_Swap1'                               => 'CCvCCvVV',
    '_Swap2'                               => 'CCnCCnNN',
    'packetType'                           => 32,
    'packetSize'                           => 16,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused57, and primitiveType.
    'primitiveType'                        => 0,
    '_unused58'                            => 0,
    'stipplePattern'                       => 0,
    'lineWidth'                            => 0,
    'stipplePatternLength'                 => 0,
    '_vertex'                              => [],
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

 $value = $sym_line->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Line Definition 
packet. The value of this attribute must be 32.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size([$newValue])

 $value = $sym_line->packet_size($newValue);

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

 $value = $sym_line->symbol_ident($newValue);

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

=item sub primitive_type([$newValue])

 $value = $sym_line->primitive_type($newValue);

Primitive Type.

This attribute specifies the type of point or line primitive used in this 
symbol. The possible primitives are described in enumeration LinePrimitiveType.

    Point           0
    Line            1
    LineStrip       2
    LineLoop        3
    Triangle        4
    TriangleStrip   5
    TriangleFan     6

=cut

sub primitive_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6)) {
      $self->{'primitiveType'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x0F;
    } else {
      carp "primitive_type must be 0 (Point), 1 (Line), 2 (LineStrip), 3 (LineLoop), 4 (Triangle), 5 (TriangleStrip), or 6 (TriangleFan).";
    }
  }
  return ($self->{'_bitfields1'} & 0x0F);
}

#==============================================================================

=item sub stipple_pattern([$newValue])

 $value = $sym_line->stipple_pattern($newValue);

Stipple Pattern.This attribute specifies the dash pattern used when drawing 
lines.
Each line is divided into sections that are 1/32 of the length specified by the 
Stipple Pattern Length attribute. The stipple pattern is a bit mask that is 
used when drawing the sections. If a bit is set (1) then section corresponding 
to that bit will be drawn; if the bit is cleared (0) then the corresponding 
section will not be drawn.

If the value of this attribute is 0xFFFF, then the line will be solid.

If the line is longer than the stipple pattern length, the pattern is repeated.

This value is ignored if the Primitive Type attribute is set to Point (0), 
Triangle (4), Triangle Strip (5), or Triangle Fan (6).

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

 $value = $sym_line->line_width($newValue);

Line Width.

For point primitives, this attribute specifies the diameter of each point in 
the symbol.

For line, line strip, and line loop primitives, this attribute specifies the 
thickness of each line in the symbol.

The value of this attribute is measured in symbol surface units and will be 
scaled if the symbol is scaled (see CIGI ICD Section 3.4.5.2).

Note that if the symbol surface's horizontal and vertical units are not the 
same size, then horizontal, diagonal, and vertical lines will not appear to be 
the same thickness.

This value is ignored if the Primitive Type attribute is set to Triangle (4), 
Triangle Strip (5), or Triangle Fan (6).

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

 $value = $sym_line->stipple_pattern_length($newValue);

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

=item sub vertex($index,[$newValue])

 $value = $sym_line->vertex($index,$newValue);

Vertex Array.

=cut

sub vertex() {
  my ($self,$index,$nv) = @_;
  if (defined($index) and $index < 9) {
    if (defined($nv)) {
      $self->{'_vertex'}[$index] = $nv;
      my $sz = 24 + 8 * $index;
      $self->{'packetSize'} = $sz if ($sz > $self->{'packetSize'});
    }
    return $self->{'_vertex'}[$index];
  } else {
    return undef;
  }
}

#==========================================================================

=item sub pack()

 $value = $sym_line->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused57, and primitiveType.
        $self->{'_unused58'},
        $self->{'stipplePattern'},
        $self->{'lineWidth'},
        $self->{'stipplePatternLength'}
      );
  my $buffer = $self->{'_Buffer'};
  foreach my $vertex (@{$self->{'_vertex'}}) {
    $buffer .= $vertex->pack();
  }

  return $buffer;
}

#==========================================================================

=item sub unpack()

 $value = $sym_line->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  my $vbuffer;
  if (@_) {
    my $buf = shift @_;
    $self->{'_Buffer'} = substr($buf,0,16);
    $self->{'_vertex'} = [];
    $vbuffer = substr($buf,16);
  }

  my ($a,$b,$c,$d,$e,$f,$g,$h) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'symbolIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused57, and primitiveType.
  $self->{'_unused58'}                           = $e;
  $self->{'stipplePattern'}                      = $f;
  $self->{'lineWidth'}                           = $g;
  $self->{'stipplePatternLength'}                = $h;

  $self->{'primitiveType'}                       = $self->primitive_type();

  my $index = 0;
  while(length($vbuffer) >= 8) {
    $self->vertex($index,Rinchi::CIGIPP::SymbolVertex->new())unless (defined($self->vertex($index)));
    $self->vertex($index)->unpack(substr($vbuffer,0,8));
    $vbuffer = substr($vbuffer,8);
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
  foreach my $vertex (@{$self->{'_vertex'}}) {
    $vertex->byte_swap();
  }

  $self->unpack();

  return $self->{'_Buffer'};
}

#==========================================================================

package Rinchi::CIGIPP::SymbolVertex;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGIPP::SymbolVertex ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#==============================================================================

=item new $vertex = Rinchi::CIGIPP::SymbolVertex->new()

Constructor for Rinchi::SymbolVertex.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => '090805fe-27b1-11de-96a9-001c25551abc',
    '_Pack'                                => 'ff',
    '_Swap1'                               => 'VV',
    '_Swap2'                               => 'NN',
    'vertexU'                              => 0,
    'vertexV'                              => 0,
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

=item sub vertex_u([$newValue])

 $value = $vertex->vertex_u($newValue);

Vertex U.

This attribute specifies the u position of a vertex with respect to the 
symbol's local coordinate system. This position is measured in scaled 
symbol surface units (see CIGI ICD Section 3.4.5.2).

=cut

sub vertex_u() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'vertexU'} = $nv
  }
  return $self->{'vertexU'};
}

#==============================================================================

=item sub vertex_v([$newValue])

 $value = $vertex->vertex_v($newValue);

Vertex V.

This attribute specifies the v position of a vertex with respect to the 
symbol's local coordinate system. This position is measured in scaled 
symbol surface units (see CIGI ICD Section 3.4.5.2).

=cut

sub vertex_v() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'vertexV'} = $nv
  }
  return $self->{'vertexV'};
}

#==========================================================================

=item sub pack()

 $value = $vertex->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'vertexU'},
        $self->{'vertexV'}
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $vertex->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});

  $self->{'vertexU'}                            = $a;
  $self->{'vertexV'}                            = $b;

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $vertex->byte_swap();

Byte swaps the packed circle data.

=cut

sub byte_swap($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  } else {
     $self->pack();
  }
  my ($a,$b) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b);
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
