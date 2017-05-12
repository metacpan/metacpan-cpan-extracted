package SVG::GD;

$VERSION = '0.20';

no  strict 'refs';

use SVG;
use Exporter;
use warnings;

=pod 

=head1 Name: SVG::GD

=head1 Version 0.20

=head1 Author: Ronan Oger 

=head1 Abstract

Provide (as seamless as possible) an SVG wrapper to the GD API
in order to provide SVG output of images generate with the Perl GD module

=head1 Synopsis

	use GD;
	use SVG::GD;
	$im = new GD::Image(100,50);

	# allocate black -- this will be our background
	$black = $im->colorAllocate(0, 0, 0);

	# allocate white
	$white = $im->colorAllocate(255, 255, 255);

	# allocate red
	$red = $im->colorAllocate(255, 0, 0);

	# allocate blue
	$blue = $im->colorAllocate(0,0,255);

	#Inscribe an ellipse in the image
	$im->arc(50, 25, 98, 48, 0, 360, $white);

	# Flood-fill the ellipse. Fill color is red, and will replace the
	# black interior of the ellipse
	$im->fill(50, 21, $red);

	binmode STDOUT;

	# print the image to stdout
	print $im->png;

=cut


BEGIN {
	#first, let's re-map the GD::Image methods to somewhere else safe.
	#nb we will also have to do this with the GD::Font methods
#	*SVG::HGD::Image::new = \&GD::Image::new;
#	*SVG::HGD::gdSmallFont =\&GD::gdSmallFont;
#	*SVG::HGD::gdLargeFont =\&GD::gdLargeFont;
#	*SVG::HGD::gdMediumBoldFont =\&GD::gdMediumBoldFont;
#	*SVG::HGD::gdTinyFont =\&GD::gdTinyFont;
#	*SVG::HGD::gdGiantFont =\&GD::gdGiantFont;
#	*SVG::HGD::Image::_make_filehandle =\&GD::Image::_make_filehandle;
#	*SVG::HGD::Image::new =\&GD::Image::new;
#	*SVG::HGD::Image::newTrueColor =\&GD::Image::newTrueColor;
#	*SVG::HGD::Image::newPalette =\&GD::Image::newPalette;
#	*SVG::HGD::Image::newFromPng =\&GD::Image::newFromPng;
#	*SVG::HGD::Image::newFromJpeg =\&GD::Image::newFromJpeg;
#	*SVG::HGD::Image::newFromXbm =\&GD::Image::newFromXbm;
#	*SVG::HGD::Image::newFromGd =\&GD::Image::newFromGd;
#	*SVG::HGD::Image::newFromGd2 =\&GD::Image::newFromGd2;
#	*SVG::HGD::Image::newFromGd2Part =\&GD::Image::newFromGd2Part;
#	*SVG::HGD::Image::ellipse =\&GD::Image::ellipse;
#	*SVG::HGD::Image::clone =\&GD::Image::clone;
#	*SVG::HGD::Polygon::new =\&GD::Polygon::new;
#	*SVG::HGD::Polygon::DESTROY =\&GD::Polygon::DESTROY;
#	*SVG::HGD::Polygon::addPt =\&GD::Polygon::addPt;
#	*SVG::HGD::Polygon::getPt =\&GD::Polygon::getPt;
#	*SVG::HGD::Polygon::setPt =\&GD::Polygon::setPt;
#	*SVG::HGD::Polygon::length =\&GD::Polygon::length;
#	*SVG::HGD::Polygon::vertices =\&GD::Polygon::vertices;
#	*SVG::HGD::Polygon::bounds =\&GD::Polygon::bounds;
#	*SVG::HGD::Polygon::deletePt =\&GD::Polygon::deletePt;
#	*SVG::HGD::Polygon::offset =\&GD::Polygon::offset;
#	*SVG::HGD::Polygon::map =\&GD::Polygon::map;
#	*SVG::HGD::Image::polygon =\&GD::Image::polygon;
#	*SVG::HGD::Polygon::toPt =\&GD::Polygon::toPt;
#	*SVG::HGD::Polygon::transform =\&GD::Polygon::transform;
#	*SVG::HGD::Polygon::scale =\&GD::Polygon::scale;

	*GD::Font:: = *SVG::GD::Font::;
	*GD::Image:: = *SVG::GD::Image::;
}	

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;

our $tinyfontsize='5';
our $smallfontsize='7';
our $mediumfontsize='10';
our $largefontsize='12';
our $giantfontsize='16';
our $font = {};
our $fontindex = 0;

@ISA = qw/Exporter/;

@EXPORT = qw/
	gdBrushed
    gdDashSize
	gdMaxColors
	gdStyled
	gdStyledBrushed
	gdTiled
	gdTransparent
	gdSmallFont
	gdMediumBoldFont
	gdLargeFont
	gdGiantFont /;

@EXPORT_OK = qw/
    GD_CMP_IMAGE
	GD_CMP_NUM_COLORS
	GD_CMP_COLOR
	GD_CMP_SIZE_X
	GD_CMP_SIZE_Y
	GD_CMP_TRANSPARENT
	GD_CMP_BACKGROUND
	GD_CMP_INTERLACE
	GD_CMP_TRUECOLOR /;

%EXPORT_TAGS = ('cmp'  => [	qw/
		GD_CMP_IMAGE
		GD_CMP_NUM_COLORS
		GD_CMP_COLOR
		GD_CMP_SIZE_X
		GD_CMP_SIZE_Y
		GD_CMP_TRANSPARENT
		GD_CMP_BACKGROUND
		GD_CMP_INTERLACE
		GD_CMP_TRUECOLOR / ]
);

=head2 gdTinyFont

returns SVG::GD::Font::Tiny

=cut

#font control


sub SVG::GD::gdTinyFont {
	return SVG::GD::Font::Tiny();
}

#font control

=head2 gdSmallFont

returns SVG::GD::Font::Small();

=cut


sub SVG::GD::gdSmallFont {
	return SVG::GD::Font::Small();
}

=head2 gdMediumBoldFont

returns SVG::GD::Font::Bold();

=cut

#font control
sub SVG::GD::gdMediumBoldFont {
	return SVG::GD::Font::MediumBold();
}

=head2 gdLargeFont

Returns SVG::GD::Font::Large()

=cut

#font control
sub SVG::GD::gdLargeFont {
	return SVG::GD::Font::Large();
}


=head2 gdGiantFont

Returns SVG::GD::Font::Giant()

=cut


#font control

sub SVG::GD::gdGiantFont {
	return SVG::GD::Font::Giant();
}

=head2 gdBrushed

Does nothing at this time

=cut

sub SVG::GD::gdBrushed { 
	return '';
}

#
#
# OO font support (encountered in GD::Graph::radar)
#
#

package SVG::GD::Font;

use strict;
use Data::Dumper;
use warnings;

sub registerFont($) {
	my $size = shift;
	$fontindex++;
	$font->{$fontindex}->{fontheight} = $size;
	$font->{$fontindex}->{fontstyle} = {'font-size'=>$size};
	return $fontindex;
}

sub Giant {
    my $class = shift;
    my $size = $giantfontsize;
	SVG::GD::Font::registerFont($size);
}

sub Large {
    my $class = shift;
    my $size = $largefontsize;
	SVG::GD::Font::registerFont($size);
}

sub Medium {
    my $class = shift;
    my $size = $mediumfontsize;
	SVG::GD::Font::registerFont($size);
}

sub MediumBold {
    my $class = shift;
    my $size = $mediumfontsize;
	SVG::GD::Font::registerFont($size);
}

sub Small {
    my $class = shift;
    my $size = $smallfontsize;
	SVG::GD::Font::registerFont($size);
}

sub Tiny {
    my $class = shift;
    my $size = $tinyfontsize;
	SVG::GD::Font::registerFont($size);
}

sub height {
	my $id = shift;
	return 10;
}

sub width {
	my $myfont = shift;
	return 8;
}

=head2 getSVGstyle($font)

retrieve the style in SVG format for predefined fomts

=cut

sub getSVGstyle {
	my $myfont = shift;
	if (eval{defined $font->{$myfont}->{fontstyle} eq 'HASH'}) {
		return %{$font->{$myfont}->{fontstyle}};
	} else {
		return ();
	}
	
}
#
# SVG::GD::Image
#

package SVG::GD::Image;

use warnings;
use strict;

#constructor
sub SVG::GD::Image::new {
    my $class = shift;
	my $self = {};
	bless $self, $class;
   	#$self->{_GD_} = new SVG::HGD::Image(@_) 
	#		|| print STDERR "Quitting. Unable to construct new SVG::HGD::Image
	#	object using SVG::GD!: $!\n";
	#return undef unless defined $self->{_GD_};

	my ($val_1,$val_2,$val_3) = @_;
	#do we have drawing sizes?
	if ($val_1 =~ /^\d+$/ && $val_2 =~ /^\d+$/) {
		$self->{_ATTRIBUTES_}->{width} = $val_1;
		$self->{_ATTRIBUTES_}->{height} = $val_2;
		$self->{_ATTRIBUTES_}->{-truecolor} = $val_3 
			if defined $val_3;

	}
	#do we have a valid filename?
	elsif (-r $val_1) {
		$self->{_ATTRIBUTES_}->{FILENAME} = $val_1;
	} 
	#do we have a file reference?
	elsif (ref $val_1) {
		$self->{_ATTRIBUTES_}->{FILEHANDLE} = $val_1;
	}
	#then we have raw image data.
	elsif (defined $val_1) {
		$self->{_ATTRIBUTES_}->{IMAGEDATA} = $val_1;
	}
	else {return undef}
	#build the svg drawing
	$self->{_SVG_} = SVG->new(%{$self->{_ATTRIBUTES_}});
	$self->{scratch}->{index_colours} = 0;
	$self->{_COLOUR_}->{named} = {
		white => {svg=>'white',rgb=>'white'}, 
		lgray => {svg=>'gray',rgb=>'lgray'}, 
		gray  => {svg=>'gray',rgb=>'gray'}, 
		dgray => {svg=>'gray',rgb=>'dgray'}, 
		black =>{svg=>'black',rgb=>'black'}, 
		lblue =>{svg=>'lightblue',rgb=>'lblue'}, 
		blue => {svg=>'blue',rgb=>'blue'}, 
		dblue =>, {svg=>'darkblue',rgb=>'dblue'},
		gold => {svg=>'gold',rgb=>'gold'}, 
		lyellow =>{svg=>'yellow',rgb=>'lyellow'}, 
		yellow =>{svg=>'yellow',rgb=>'yellow'},
		dyellow =>{svg=>'gold',rgb=>'gold'}, 
		lgreen =>{svg=>'mintgreen',rgb=>'lgreen'}, 
		green =>{svg=>'green',rgb=>'green'}, 
		dgreen =>{svg=>'darkgreen',rgb=>'dgreen'}, 
		lred =>{svg=>'red',rgb=>'dred'}, 
		red => {svg=>'red',rgb=>'red'}, 
		dred =>{svg=>'red',rgb=>'dred'}, 
		lpurple =>{svg=>'gold',rgb=>'gold'}, 
		purple => {svg=>'purple',rgb=>'purple'}, 
		dpurple =>{svg=>'dpurple ',rgb=>'dpurple'},
		lorange =>{svg=>'lorange ',rgb=>'lorange'}, 
		orange => {svg=>'orange',rgb=>'orange'}, 
		pink => {svg=>'pink',rgb=>'pink'}, 
		dpink =>{svg=>'pink',rgb=>'dpink'}, 
		marine =>{svg=>'navy',rgb=>'marine'}, 
		cyan => {svg=>'cyan',rgb=>'cyan'}, 
		lbrown =>{svg=>'brown',rgb=>'lbrown'}, 
		dbrown => {svg=>'brown',rgb=>'dbrown'},
		};
	return $self;
}


#--------------------
#Wrapper methods

=head2 setPixel

set a pixel to a colour
Because SVG does not understand pixels, this method has to be faked. We know
from the image size what is meant by a pixel, so we create a rectangle of size
1x1 and give it a colour

=cut

sub SVG::GD::Image::setPixel($$$$) {
	my $self = shift;
	my ($x,$y,$colour) = @_;
	$self->{_SVG_}->rect(x=>$x,y=>$y,
		width=>1,height=>1,
		fill=>$self->getColour($colour));
#	$self->{_GD_}->setPixel($x,$y,$colour);	
}


=head2 colorAllocate

Allocate the colour to a variable (red,green,blue)

=cut

sub SVG::GD::Image::colorAllocate($$$$) {
	my $self = shift;
	my ($red,$green,$blue) = @_;
#	my $code = $self->{_GD_}->colorAllocate($red,$green,$blue);
	#if we get an rgb triplet, handle as an rgb triplet
	my $code = $self->{index_colour}++;
	
	if (defined $green && defined $blue) {
		#$code = "$red.$green.$blue" if (defined $green && defined $blue);
		$self->{_COLOUR_}->{$code}->{svg} = 
		$self->{_SVG_}->colorAllocate($red,$green,$blue);
		$self->{_COLOUR_}->{$code}->{rgb} = [$red,$green,$blue];
	} 
	#otherwise assume this is a named colour.
	else {
		$code = $red;
		$self->{_COLOUR_}->{$code}->{rgb} = [$code];
		$self->{_COLOUR_}->{$code}->{svg} = [$code];
	}
	return $code;	
}

=head2 colorResolve ($red,$green,$blue)

for an rbg tripplet, either returns the index for the colour or generates a new
index for that colour

=cut

*SVG::GD::Image::colorResolve = \&SVG::GD::Image::colorAllocate;

=head2 colorsTotal

return the number of allocated colors

=cut

sub SVG::GD::Image::colorsTotal ($) {
	my $self = shift;
	return scalar(keys %{$self->{_COLOUR_}});
}

=head2 colorExact

check for the existance of an exact color

=cut

sub SVG::GD::Image::colorExact ($$) {
	my $self = shift;
	my $colour = shift;
	return 1 if $self->{_COLOUR_}->{$colour};
	return -1;
}

=head2 colorClosest

returns the closest colour to the RGB triplet being submitted

=cut

sub SVG::GD::Image::colorClosest ($$$$) {
	my $self = shift;
	my ($red,$green,$blue) = @_;
	my $value = {};
	map {
		my $cc = $_; 
		#calculate the least-square distance
		my ($dr,$dg,$db) = (
			$red * $red -
			$self->{_COLOUR_}->{$cc}->[0] * $self->{_COLOUR_}->{$cc}->[0],
			$green * $blue -
			$self->{_COLOUR_}->{$cc}->[1] * $self->{_COLOUR_}->{$cc}->[1],
			$blue * $blue -
			$self->{_COLOUR_}->{$cc}->[2] * $self->{_COLOUR_}->{$cc}->[2],
		);
		
		$value->{$dr+$dg+$db} = $cc;

	}  keys %{$self->{_COLOUR_}};
	#
	my @array = sort {$a<=>$b} keys %$value;
	my $leastval = shift @array;
	my $code = $value->{$leastval};

}

=head2 line

Draw a line between 2 points

=cut

sub SVG::GD::Image::line($$$$$$) {
	my $self = shift;
	my ($x1,$y1,$x2,$y2,$colour) = @_;
#	$self->{_GD_}->line(@_);
	$self->{_SVG_}->line(x1=>$x1,x2=>$x2,y1=>$y1,y2=>$y2,
		stroke=>$self->getColour($colour));
}

sub SVG::GD::Image::dashedLine($$$$$$) {
	my $self = shift;
	my ($x1,$y1,$x2,$y2,$colour) = @_;
#	$self->{_GD_}->dashedLine(@_);
	$self->{_SVG_}->line(x1=>$x1,x2=>$x2,y1=>$y1,y2=>$y2,
		stroke=>$self->getColour($colour));
}

=head2 filledRectangle

Draw a filled rectangle.

=cut

sub SVG::GD::Image::filledRectangle($$$$$$$) {
	my $self = shift;
	my ($x1,$y1,$x2,$y2,$colour) = @_;
#	$self->{_GD_}->filledRectangle(@_);
	$self->{_SVG_}->rect(x=>$x1,y=>$y1,
			width=>$x2-$x1,height=>$y2-$y1,
			fill=>$self->getColour($colour),
			stroke=>$self->getColour($colour));
}

=head2 rectangle

Draw a rectangle.

=cut

sub SVG::GD::Image::rectangle($$$$$$$) {
	my $self = shift;
	my ($x1,$y1,$x2,$y2,$colour) = @_;
#	$self->{_GD_}->rectangle(@_);
	$self->{_SVG_}->rect(x=>$x1,y=>$y1,
			width=>$x2-$x1,height=>$y2-$y1,fill=>'none',
			stroke=>$self->getColour($colour));
}
=head2 arc

Draw an arc. Only supports closed arcs at present.
Note that we will ultimately need to differenciate between
an arc and a circle.

=cut

sub SVG::GD::Image::arc($$$$$$$$) {
	my $self = shift;
	my ($cx,$cy,$width,$height,$start,$end,$colour) = @_;
	$self->{_SVG_}->ellipse(cx=>$cx,cy=>$cy,
			rx=>$width/2,ry=>$height/2,fill=>'none',
			stroke=>$self->getColour($colour));
#	return $self->{_GD_}->arc(@_);
}

=head2  SVG::GD::Image::filledPolygon

Draw a polygon defined by ab SVG::GD::Polygon object

=cut

sub SVG::GD::Image::filledPolygon ($$$) {
	my $self = shift;
	my $poly = shift;
	my $fill = shift;
		
	my ($x,$y) = ([],[]);
	foreach my $set (@{$poly->{points}}) {
		my ($myx,$myy) = ($set->[0],$set->[1]);
		push @$x,$myx;
		push @$y,$myy;
	}
	my $points = $self->{_SVG_}->
	get_path(x=>$x, y=>$y,
		-type=>'path',
		-closed=>'true');
	$self->{_SVG_}->path(%$points,fill=>$self->getColour($fill));
}

=head2 polygon

Draw an empty polygon

=cut

sub SVG::GD::Image::polygon ($$$) {
	my $self = shift;
	my $poly = shift;
	my $stroke = shift;
		
	my ($x,$y) = ([],[]);
	foreach my $set (@{$poly->{points}}) {
		my ($myx,$myy) = ($set->[0],$set->[1]);
		push @$x,$myx;
		push @$y,$myy;
	}
	my $points = $self->{_SVG_}->
	get_path(x=>$x, y=>$y,
		-type=>'path',
		-closed=>'true');
	$self->{_SVG_}->path(%$points,stroke=>$self->getColour($stroke),fill=>'none');
}


#string methods

=head1 string methods

=head2 string

write a text string

=cut

sub SVG::GD::Image::string ($$$$$$) {
	my $self = shift;
	my ($myfont,$x,$y,$text,$colour) = @_;
#	$self->{_GD_}->string(@_);
	$self->{_SVG_}->text(
		'baseline-shift'=>'sub',
		style=>{
			SVG::GD::Font::getSVGstyle($myfont),
			fill=>$self->getColour($colour),
		},
		x=>$x,
		y=>$y)->tspan(dy=>'1em') ->cdata($text);
}

=head2 char

write a character

=cut

*SVG::GD::Image::char = \&SVG::GD::Image::string;

=head2 charUp

write a character upwards

=cut

sub SVG::GD::Image::stringUp ($$$$$$) {
    my $self = shift;
	my ($myfont,$x,$y,$text,$colour) = @_;
#	$self->{_GD_}->string(@_);
	$self->{_SVG_}->text(
		style=>{'writing-mode'=>'tb',
				SVG::GD::Font::getSVGstyle($myfont),
				fill=>$self->getColour($colour),
				},
		x=>$x,y=>$y,
		)->cdata($text);
}
*SVG::GD::Image::charUp = \&SVG::GD::Image::stringUp;

#---------------
#internal methods


sub SVG::GD::Image::getRGB($$) {
	my $self = shift;
	my $colour = shift;
	return $self->{_COLOUR_}->{$colour}->{rgb};
}

sub SVG::GD::Image::getColour($$) {
	my $self = shift;
	my $colour = shift;
	return $self->{_COLOUR_}->{$colour}->{svg};
}

=head2 rgb

Return the red,green,blue array for an allocated colour

=cut

sub SVG::GD::Image::rgb ($$) {
	my $self = shift;
	my $col = shift;
	return @{$self->getRBG($col)}; 
}

=head2 svg

replace the gif writing request with an svg writing request

=cut

sub SVG::GD::Image::svg ($) {
	my $self = shift;
	return $self->{_SVG_}->xmlify;
}

=head2 png

Return the binary image in PNG format

=cut

sub SVG::GD::Image::png ($) {
	my $self = shift;
	return $self->svg;
#	return $self->{_GD_}->png;
}

=head2 jpg

Return the binary image in JPEG format

=cut

sub SVG::GD::Image::wbmp ($$) {
	my $self = shift;
#	return $self->{_GD_}->wbmp(@_);
}	

=head2 gif

Return the binary image in GIF format
Note that some versions of SVG::GD do not support this method

=cut

sub SVG::GD::Image::gif ($) {
	my $self = shift;
	return $self->svg;
} 	
#------------------
#ignored methods that are meaningless
#or too difficult to implement


sub SVG::GD::Image::interlaced ($) {
	my $self = shift;
#	$self->{_GD_}->interlaced(@_);
}

sub SVG::GD::Image::transparent ($$) {
	my $self = shift;
	my $colour = shift;
#	$self->{_GD_}->transparent($colour)
}

sub SVG::GD::Image::fill ($$$$) {
	my $self = shift;
	my ($x,$y,$colour) = @_;
#	$self->{_GD_}->fill(@_);
}

sub SVG::GD::Image::fillToBorder ($$$$) {
	my $self = shift;
	my ($x,$y,$colour) = @_;
#	$self->{_GD_}->fillToBorder(@_);	
}

############################################################################
#
# new methods on GD::Image
#
############################################################################

sub SVG::GD::Image::polyline ($$$) {
    my $self = shift;   # the GD::Image
    my $p    = shift;   # the GD::Polyline (or GD::Polygon)
	my $c    = shift;   # the color

	my @points = $p->vertices();
	my $p1 = shift @points;
	my $p2;
	while ($p2 = shift @points) {
		$self->line(@$p1, @$p2, $c);
		$p1 = $p2;
	}
}

sub GD::Image::polydraw ($$$) {
	my $self = shift;   # the GD::Image
	my $p    = shift;   # the GD::Polyline or GD::Polygon
	my $c    = shift;
	# the color return
	$self->polyline($p, $c) if $p->isa('GD::Polyline');
	return $self->polygon($p, $c);
}
																	
sub setBrush ($$) {
	my $self = shift;
	my $brush = shift;
	return "Sorry..Ignoring this command. Unable to setBrush with this version
	of SVG::GD";
}



