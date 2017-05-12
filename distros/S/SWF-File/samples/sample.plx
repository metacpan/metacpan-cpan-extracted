#!/usr/bin/perl

use SWF::File;

my $swf = SWF::File->new;

# Set the frame size and rate.

$swf->FrameSize(0, 0, 400, 400);
$swf->FrameRate(30);

# At first, you should set background color.

SWF::Element::Tag::SetBackgroundColor->new(
    BackgroundColor => [
      Red => 255,
      Green => 255,
      Blue => 255,     # white
    ],
)->pack($swf);

# Define the pink, half-transparent rectangle.

SWF::Element::Tag::DefineShape3->new(
    ShapeID => 1,
    ShapeBounds =>   # A region of the shape.
    [                # Minimum and maximum coordinates adjusted with the line width.
      Xmin => -25-4,
      Ymin => -18-4,
      Xmax => 25+4,
      Ymax => 18+4,
    ],
    Shapes => [
     LineStyles => [
      [ Width => 7,
        Color => [
	  Red => 255,
	  Green => 95,
	  Blue => 174,
	  Alpha => 128 ]
	]
      ],
     ShapeRecords => [
      [ MoveDeltaX => -25, MoveDeltaY => -18, LineStyle => 1 ], 
      [ DeltaX => 50 ],
      [ DeltaY => 36 ],
      [ DeltaX => -50 ],
      [ DeltaY => -36 ],
     ],
    ],
)->pack($swf);

my $sf = SWF::Element::Tag::ShowFrame->new;

# Set the matrix for the rectangle with position (0,200) and 10 times magnification.

my $matrix1 = SWF::Element::MATRIX->new->moveto(0,200)->scale(10);

# Set the another matrix with position (400,200) and 10 times magnification.

my $matrix2 = SWF::Element::MATRIX->new->moveto(400,200)->scale(10);

# place the rectangle to (0,200) of depth 1.

SWF::Element::Tag::PlaceObject2->new(
    Depth => 1,
    CharacterID => 1,
    Matrix => $matrix1,
)->pack($swf);

# place the another rectangle to (400,200) of depth 2 with color change.

SWF::Element::Tag::PlaceObject2->new(
    Depth => 2,
    CharacterID => 1,
    Matrix => $matrix2,
    ColorTransform => [
      RedMultTerm => 0,      # Red = 255*0/255 = 0
      GreenMultTerm => 255,  # Green = 95*255/255 = 95
      BlueMultTerm => 0,     # Blue = 174*0/255 = 174
      AlphaMultTerm => 255,  # Alpha = 128*255/255 = 128
    ]
)->pack($swf);

# show frame

$sf->pack($swf);

# Keep PlaceObject2 tags to move.

my $po1 = SWF::Element::Tag::PlaceObject2->new(
        PlaceFlagMove => 1,
        Depth => 1,
        Matrix => $matrix1,
   );
my $po2 = SWF::Element::Tag::PlaceObject2->new(
        PlaceFlagMove => 1,
        Depth => 2,
        Matrix => $matrix2,
   );


for($x=0; $x<100; $x++) {

# move, rotate, and reduce the rectangles' matrix.
    $matrix1->moveto($x*5,200)->rotate(15)->scale(.95);
    $matrix2->moveto(400-$x*5,200)->rotate(-15)->scale(.95);
# place the rectangles.
    $po1->pack($swf);
    $po2->pack($swf);
# show frame.
    $sf->pack($swf);
}

SWF::Element::Tag::End->new->pack($swf);
$swf->close('sample.swf');
