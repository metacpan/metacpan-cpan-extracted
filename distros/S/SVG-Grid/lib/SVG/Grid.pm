package SVG::Grid;

use strict;
use warnings;
use warnings qw(FATAL utf8);

use Moo;

use SVG;

use Types::Standard qw/Any Int HashRef Str/;

has cell_height =>
(
	default		=> sub {return 40},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has cell_width =>
(
	default		=> sub {return 40},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has colors =>
(
	default		=> sub {return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has height =>
(
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has output_file_name =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has style =>
(
	default		=> sub {return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has svg =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has x_cell_count =>
(
	default		=> sub {return 30},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has x_offset =>
(
	default		=> sub {return 40},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has width =>
(
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has y_cell_count =>
(
	default		=> sub {return 30},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has y_offset =>
(
	default		=> sub {return 40},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

our $VERSION = '1.09';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> colors
	({
		black		=> 'rgb(  0,   0,   0)',
		blue		=> 'rgb(  0,   0, 255)',
		dimgray		=> 'rgb(105, 105, 105)',
		indianred	=> 'rgb(205,  92,  92)',
		red			=> 'rgb(255,   0,   0)',
		silver		=> 'rgb(192, 192, 192)',
		white		=> 'rgb(255, 255, 255)',
	});
	$self -> style
	({
		'fill-opacity'	=> 0,
		font			=> 'Arial',
		'font-size'		=> 14,
		'font-weight'	=> 'normal',
		stroke			=> 'rgb(0, 0, 0)',
		'stroke-width'	=> 1,
	});
	$self -> width
	(
		$self -> x_cell_count * $self -> cell_width
			+ 2 * $self -> x_offset
			+ 2 * $self -> cell_width
	);
	$self -> height
	(
		$self -> y_cell_count * $self -> cell_height
			+ 2 * $self -> y_offset
			+ 2 * $self -> cell_height
	);
	$self -> svg(SVG -> new(width => $self -> width, height => $self -> height) );

} # End of BUILD.

# ----------------------------------------------

sub frame
{
	my($self, %options)	= @_;
	my($frame_x)		= [0, $self -> width - 1,  $self -> width - 1,                    0, 0];
	my($frame_y)		= [0,                   0, $self -> height - 1, $self -> height - 1, 0];
	my($points)			= $self -> svg -> get_path
							(
								-type	=> 'polyline',
								x		=> $frame_x,
								y		=> $frame_y,
							);
	my($defaults)		= $self -> _get_defaults(%options);
	my($id)				= 'frame_' . $$frame_x[2] . '_' . $$frame_y[2]; # Try to make it unique.

	$self -> svg -> polyline
	(
		%$points,
		id		=> $id,
		style	=>
		{
			%{$self -> style},
			'fill-opacity'	=> $$defaults{fill_opacity},
			stroke			=> $$defaults{stroke},
			'stroke-width'	=> $$defaults{stroke_width},
		}
	);

} # End of frame.

# ----------------------------------------------

sub _get_defaults
{
	my($self, %options) = @_;

	return
	{
		fill			=> $options{fill}			|| ${$self -> style}{fill}				|| 'rgb(205, 92, 92)', # Aka indianred.
		fill_opacity	=> $options{'fill-opacity'}	|| ${$self -> style}{'fill-opacity'}	|| 0,
		font_size		=> $options{'font-size'}	|| ${$self -> style}{'font-size'}		|| 14,
		font_weight		=> $options{'font-weight'}	|| $options{style}{'font-weight'}		|| 'normal',
		stroke			=> $options{stroke}			|| ${$self -> colors}{dimgray}			|| 'rgb(105, 105, 105)', # Aka dimgray.
		stroke_width	=> $options{'stroke-width'}	|| ${$self -> style}{'stroke-width'}	|| 1,
		text_color		=> $options{text_color}		|| ${$self -> colors}{blue}				|| 'rgb(  0,   0, 255)', # Aka blue.
	};

} # End of _get_defaults.

# ----------------------------------------------

sub grid
{
	my($self, %options)	= @_;
	my($count)			= 0;
	my($defaults)		= $self -> _get_defaults(%options);
	my($limit)			= int( ($self -> width - 2 * $self -> x_offset) / $self -> cell_width);

	my(%opts);

	for (my $i = $self -> x_offset; $i <= ($self -> width - $self -> cell_width); $i += $self -> cell_width)
	{
		$count++;

		# Draw vertical lines.

		$self -> svg -> line
				(
					id		=> "grid_x_$i", # Try to make it unique.
					x1		=> $i,
					y1		=> $self -> cell_height,
					x2		=> $i,
					y2		=> $self -> height - $self -> y_offset - 1,
					style	=>
					{
						%{$self -> style},
						stroke			=> $$defaults{stroke},
						'stroke-width'	=> $$defaults{stroke_width},
					}
				);

		# This 'if' stops the x-axis labels appearing on top/bottom of the y-axis labels.

		if ( ($count > 1) && ($count < $limit) )
		{
			# Add x-axis labels across the top.

			%opts			= ();
			$opts{x}		= $i + $$defaults{font_size};
			$opts{y}		= $self -> y_offset + 2 * $$defaults{font_size};
			$opts{stroke}	= $$defaults{text_color};
			$opts{text}		= $count - 1;

			$self -> text(%opts);

			# Add x-axis labels across the bottom.

			%opts			= ();
			$opts{x}		= $i + $$defaults{font_size};
			$opts{y}		= $self -> height - $self -> y_offset - $$defaults{font_size};
			$opts{stroke}	= $$defaults{text_color};
			$opts{text}		= $count - 1;

			$self -> text(%opts);
		}
	}

	$count	= 0;
	$limit	= int( ($self -> height - 2 * $self -> y_offset) / $self -> cell_height);

	for (my $i = $self -> y_offset; $i <= ($self -> height - $self -> cell_height); $i += $self -> cell_height)
	{
		$count++;

		# Draw horizontal lines.

		$self -> svg -> line
				(
					id		=> "grid_y_$i", # Try to make it unique.
					x1		=> $self -> x_offset,
					y1		=> $i,
					x2		=> $self -> width - $self -> x_offset - 1,
					y2		=> $i,
					style	=>
					{
						%{$self -> style},
						stroke			=> $$defaults{stroke},
						'stroke-width'	=> $$defaults{stroke_width},
					}
				);

		# This 'if' stops the y-axis labels appearing to the left/right of the x-axis labels.

		if ( ($count > 1) && ($count < $limit) )
		{
			# Add y-axis labels down the left.

			%opts			= ();
			$opts{x}		= $self -> x_offset + $$defaults{font_size};
			$opts{y}		= $i + 2 * $$defaults{font_size};
			$opts{stroke}	= $$defaults{text_color};
			$opts{text}		= $count - 1;

			$self -> text(%opts);

			# Add y-axis labels down the right.

			%opts			= ();
			$opts{x}		= $self -> width - $self -> x_offset - 2 * $$defaults{font_size};
			$opts{y}		= $i + 2 * $$defaults{font_size};
			$opts{stroke}	= $$defaults{text_color};
			$opts{text}		= $count - 1;

			$self -> text(%opts);
		}
	}

} # End of grid.

# ----------------------------------------------

sub image_link
{
	my($self, %options)	= @_;
	my($image_id)		= "image_$options{x}_$options{y}"; # Try to make it unique.
	my(%anchor_options)	=
	(
		-href	=> $options{href},
		id		=> "anchor_$options{x}_$options{y}", # Try to make it unique.
		-show	=> $options{show} || 'new',
	);
	$anchor_options{-title} = $options{title} if ($options{title} && (length($options{title}) > 0) );

	$self -> svg -> anchor(%anchor_options) -> image
	(
		-href	=> $options{image},
		id		=> $image_id,
		width	=> $self -> cell_width,
		height	=> $self -> cell_height,
		x		=> $self -> x_offset + $self -> cell_width * $options{x},
		y		=> $self -> y_offset + $self -> cell_height * $options{y},
	);

	return $image_id;

} # End of image_link.

# ------------------------------------------------

sub report
{
	my($self) = @_;

	print sprintf("x_cell_count: %d. cell_width: %d. x_offset: %d. width: %d. \n",
			$self -> x_cell_count, $self -> cell_width, $self -> x_offset, $self -> width);
	print sprintf("y_cell_count: %d. cell_height: %d. y_offset: %d. height: %d. \n",
			$self -> y_cell_count, $self -> cell_height, $self -> y_offset, $self -> height);

} # End of report.

# ----------------------------------------------

sub rectangle_link
{
	my($self, %options) = @_;
	my($defaults)		= $self -> _get_defaults(%options);
	my(%anchor_options)	=
	(
		-href	=> $options{href},
		id		=> "anchor_$options{x}_$options{y}", # Try to make it unique.
		-show	=> $options{show} || 'new',
	);
	$anchor_options{-title} = $options{title} if ($options{title} && (length($options{title}) > 0) );
	my($rectangle_id)		= "rectangle_$options{x}_$options{y}"; # Try to make it unique.

	$self -> svg -> anchor(%anchor_options) -> rectangle
	(
		fill			=> $$defaults{fill},
		'fill-opacity'	=> $$defaults{fill_opacity} || 0.5, # We use 0.5 since the default is 0.
		id				=> $rectangle_id,
		stroke			=> $$defaults{stroke},
		'stroke-width'	=> $$defaults{stroke_width},
		width			=> $self -> cell_width,
		height			=> $self -> cell_height,
		x				=> $self -> x_offset + $self -> cell_width * $options{x},
		y				=> $self -> y_offset + $self -> cell_height * $options{y},
	);

	return $rectangle_id;

} # End of rectangle_link.

# ----------------------------------------------

sub text
{
	my($self, %options)	= @_;
	my($defaults)		= $self -> _get_defaults(%options);

	$self -> svg -> text
	(
		id		=> "note_$options{x}_$options{y}", # Try to make it unique.
		x		=> $options{x},
		y		=> $options{y},
		style	=>
		{
			%{$self -> style},
			'fill-opacity'	=> $$defaults{fill_opacity},
			'font-size'		=> $$defaults{font_size},
			'font-weight'	=> $$defaults{font_weight},
			stroke			=> $$defaults{stroke},
		}
	) -> cdata($options{text});

} # End of text.

# ----------------------------------------------

sub text_link
{
	my($self, %options)	= @_;
	my($defaults)		= $self -> _get_defaults(%options);
	my($half_font)		= int($$defaults{font_size} / 2);
	my(%anchor_options)	=
	(
		-href	=> $options{href},
		id		=> "anchor_$options{x}_$options{y}", # Try to make it unique.
		-show	=> $options{show} || 'new',
	);
	$anchor_options{-title} = $options{title} if ($options{title} && (length($options{title}) > 0) );
	my($text_id)			= "text_$options{x}_$options{y}"; # Try to make it unique.

	$self -> svg -> anchor(%anchor_options) -> text
	(
		id		=> $text_id,
		x		=> $self -> x_offset + $self -> cell_width * $options{x} + $$defaults{font_size} - $half_font,
		y		=> $self -> y_offset + $self -> cell_height * $options{y} + $$defaults{font_size} + $half_font,
		style	=>
		{
			%{$self -> style},
			'fill-opacity'	=> $$defaults{fill_opacity},
			'font-size'		=> $$defaults{font_size},
			'font-weight'	=> $$defaults{font_weight},
			stroke			=> $$defaults{stroke},
			'stroke-width'	=> $$defaults{stroke_width},

		}
	) -> cdata($options{text});

	return $text_id;

} # End of text_link.

# ------------------------------------------------

sub write
{
	my($self, %options)	= @_;
	my($file_name)		= $options{output_file_name} || $self -> output_file_name;

	open(my $fh, '>:encoding(UTF-8)', $file_name);
	print $fh  $self -> svg -> xmlify;
	close $fh;

} # End of write.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<SVG::Grid> - Address SVG images using cells of $n1 x $n2 pixels

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use utf8;
	use warnings;

	use SVG::Grid;

	# ------------

	my($cell_width)   = 40;
	my($cell_height)  = 40;
	my($x_cell_count) =  3;
	my($y_cell_count) =  3;
	my($x_offset)     = 40;
	my($y_offset)     = 40;
	my($svg)          = SVG::Grid -> new
	(
		cell_width   => $cell_width,
		cell_height  => $cell_height,
		x_cell_count => $x_cell_count,
		y_cell_count => $y_cell_count,
		x_offset     => $x_offset,
		y_offset     => $y_offset,
	);

	$svg -> frame('stroke-width' => 3);
	$svg -> text
	(
		'font-size'   => 20,
		'font-weight' => '400',
		text          => 'Front Garden',
		x             => $svg -> x_offset,     # Pixel co-ord.
		y             => $svg -> y_offset / 2, # Pixel co-ord.
	);
	$svg -> text
	(
		'font-size'   => 14,
		'font-weight' => '400',
		text          => '--> N',
		x             => $svg -> width - 2 * $svg -> cell_width, # Pixel co-ord.
		y             => $svg -> y_offset / 2,                   # Pixel co-ord.
	);
	$svg -> grid(stroke => 'blue');
	$svg -> image_link
	(
		href   => 'http://savage.net.au/Flowers/Chorizema.cordatum.html',
		image  => 'http://savage.net.au/Flowers/images/Chorizema.cordatum.0.jpg',
		show   => 'new',
		title  => 'MouseOver® an image',
		x      => 1, # Cell co-ord.
		y      => 2, # Cell co-ord.
	);
	$svg -> rectangle_link
	(
		href   => 'http://savage.net.au/Flowers/Alyogyne.huegelii.html',
		show   => 'new',
		title  => 'MouseOver™ a rectangle',
		x      => 2, # Cell co-ord.
		y      => 3, # Cell co-ord.
	);
	$svg -> text_link
	(
		href   => 'http://savage.net.au/Flowers/Aquilegia.McKana.html',
		stroke => 'rgb(255, 0, 0)',
		show   => 'new',
		text   => '3,1',
		title  => 'MouseOvér some text',
		x      => 3, # Cell co-ord.
		y      => 1, # Cell co-ord.
	);
	$svg -> write(output_file_name => 'data/synopsis.svg');

Output: L<http://savage.net.au/assets/images/articles/synopsis.svg>

See also scripts/*.pl.

=head1 Description

C<SVG::Grid> allows you to I<mostly> use cell co-ordinates (like a spreadsheet) to place items on
an L<SVG> image. These co-ordinates are in the form (x, y) = (integer, integer), where x and y
refer to the position of a cell within a row and a column. You define these rows and columns when
you call the L</new(%options)> method. Cell co-ordinates are numbered 1 .. N.

Here, I<mostly> means all method calls except adding text via the L</text(%options)]> method. With
C<text()>, you use pixels locations so that the text can be placed anywhere. Pixel co-ordinates are
numbered 0 .. N.

Note: Objects of type C<SVG::Grid> are not daughters of L<SVG>. They are stand-alone objects.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<SVG::Grid> as you would any C<Perl> module:

Run:

	cpanm SVG::Grid

or run:

	sudo cpan SVG::Grid

And then:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($svg) = SVG::Grid -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<SVG::Grid>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text(%options)>]:

=over 4

=item o cell_height => $integer

The height of each cell, in pixels.

Default: 40.

=item o cell_width => $integer

The width of each cell, in pixels.

Default: 40.

=item o colors => $hashref

The set of default colors, so you don't have to provide a C<color> parameter to various methods.

It also means you can refer to colors by their names, rather than the awkward C<'rgb($R, $G, $B)'>
structures that the L<SVG> module uses.

Default:

	$self -> colors
	({
		black     => 'rgb(  0,   0,   0)',
		blue      => 'rgb(  0,   0, 255)',
		dimgray   => 'rgb(105, 105, 105)',
		indianred => 'rgb(205,  92,  92)',
		red       => 'rgb(255,   0,   0)',
		silver    => 'rgb(192, 192, 192)',
		white     => 'rgb(255, 255, 255)',
	});

=item o output_file_name =>

The name of the SVG file to write, if the L</write(%options)> method is called.

Default: ''.

=item o style => $hashref

The default style to use, so you don't have to provide a C<style> parameter to various methods.

Default:

	$self -> style
	({
		'fill-opacity'	=> 0,
		font            => 'Arial',
		'font-size'     => 14,
		'font-weight'   => 'normal',
		stroke          => 'rgb(0, 0, 0)',
		'stroke-width'  => 1,
	});

=item o x_cell_count => $integer

The number of cells aross the SVG.

Each cell will be C<cell_width> pixels wide.

Default: 30.

=item o x_offset => $integer

The distance between the left and right sides of the SVG and the co-ordinate grid, in pixels.

Default: 40.

=item o y_cell_count => $integer

The number of cells down the SVG.

Each cell will be C<cell_height> pixels high.

Default: 30.

=item o y_offset => $integer

The distance between the top and bottom sides of the SVG and the co-ordinate grid, in pixels.

=back

=head1 Methods

=head2 cell_height()

Gets the height of each cell, in pixels.

C<cell_height> is a parameter to L</new()>.

=head2 cell_width()

Gets the width of each cell, in pixels.

C<cell_width> is a parameter to L</new()>.

=head2 colors([$hashref])

Here, [] indicates an optional parameter.

Gets or sets the default hashref of colors.

C<colors> is a parameter to L</new()>.

=head2 frame([%options])

Draws the frame.

This method uses these keys in C<%options>:

=over 4

=item o fill-opacity

Default:  0.

=item o stroke

Default: 'rgb(105, 105, 105)' aka dimgray.

=item o stroke-width

Default: 1.

=back

=head2 grid(%options)

Draws a grid onto the SVG.

This method uses these keys in C<%options>:

=over 4

=item o font-size

Default: 14.

=item o stroke

Default: 'rgb(105, 105, 105)' aka dimgray.

=item o stroke-width

Default: 1;

=item o text_color

Default: 'rgb(0, 0, 255)' aka blue.

=back

=head2 height()

Returns the calculated height, in pixels, of the SVG.

=head2 image_link(%options)

Places an image onto the SVG and makes it clickable.

This method uses these keys in C<%options>:

=over 4

=item o href => $url

This is the link you are taken to if you click in the specified C<image>. Sample:

href => 'http://savage.net.au/Flowers/Chorizema.cordatum.html'

=item o image => $url

This is the image which appears on the SVG, and which is made clickable. Sample:

image => 'http://savage.net.au/Flowers/images/Chorizema.cordatum.0.jpg'

=item o show => $string

For $string you must choose one of the SVG specification values: embed|new|none|other|replace.

L<The SVG specification for Behavior Attributes|https://www.w3.org/TR/xlink/#link-behaviors>.

Note: The parameter passed to L<SVG> is actually called C<-show>.

Default: 'new'

'new' is similar to the effect achieved by the following HTML fragment:

	<A HREF="http://www.example.org" target="_blank">...</A>

=item o title => $string.

This string, if not empty, is passed to L<SVG> as the value of the C<-title> parameter.

The effect is to activate a tooltip when you MouseOver the image.

=item o x => $integer

This is the cell # across the SVG.

Cell co-ordinates are numbered 1 .. N.

=item o y => $integer

This is the cell # down the SVG.

Cell co-ordinates are numbered 1 .. N.

=back

=head2 output_file_name($string)

Here, [] indicates an optional parameter.

Gets or sets the name of the output file.

C<output_file_name> is a parameter to L</new()>.

=head2 rectangle_link(%options)

Places a rectangle (which fills a cell) onto the SVG and makes it clickable.

This method uses these keys in C<%options>:

=over 4

=item o fill

Default: 'rgb(205, 92, 92)' aka indianred.

=item o fill-opacity

Default: 0.5.

=item o href => $url

This is the link you are taken to if you click in the rectangle specified by (x, y). Sample:

href => 'http://savage.net.au/Flowers/Alyogyne.huegelii.html'

=item o stroke

Default: 'rgb(105, 105, 105)' aka dimgray.

=item o show => $string

For $string you must choose one of the SVG specification values: embed|new|none|other|replace.

L<The SVG specification for Behavior Attributes|https://www.w3.org/TR/xlink/#link-behaviors>.

Note: The parameter passed to L<SVG> is actually called C<-show>.

Default: 'new'

'new' is similar to the effect achieved by the following HTML fragment:

	<A HREF="http://www.example.org" target="_blank">...</A>

=item o title => $string.

This string, if not empty, is passed to L<SVG> as the value of the C<-title> parameter.

The effect is to activate a tooltip when you MouseOver the rectangle.

=item o x => $integer

This is the cell # across the SVG.

Cell co-ordinates are numbered 1 .. N.

=item o y => $integer

This is the cell # down the SVG.

Cell co-ordinates are numbered 1 .. N.

=back

=head2 style([$hashref])

Here, [] indicates an optional parameter.

Gets or sets the default hashref of styles.

C<style> is a parameter to L</new()>.

=head2 svg()

Returns the internal L<SVG> object.

=head2 text(%options)

Places a text string onto the SVG.

Warning: This method uses (x, y) in pixels.

This method uses these keys in C<%options>:

=over 4

=item o fill-opacity

Default:  0.

=item o font-size

Default: 14.

=item o font-weight

Default: 'normal'.

=item o stroke

Default: 'rgb(105, 105, 105)' aka dimgray.

=item o x => $integer

This is the pixel # across the SVG.

Pixel co-ordinates are numbered 0 .. N.

=item o y => $integer

This is the pixel # down the SVG.

Pixel co-ordinates are numbered 0 .. N.

=back

=head2 text_link(%options)

Places a text string onto the SVG and makes it clickable.

The clickable area is just the text. The remainer of the cell does not respond to the click.

This method uses these keys in C<%options>:

=over 4

=item o fill-opacity

Default: 0.

=item o font-size

Default: 14.

=item o font-weight

Default: 'normal'.

=item o href => $url

This is the link you are taken to if you click in the C<text> in the cell specified by (x, y).
Sample:

href => 'http://savage.net.au/Flowers/Aquilegia.McKana.html'

=item o stroke

Default: 'rgb(105, 105, 105)' aka dimgray.

=item o stroke-width

Default: 1.

=item o show => $string

For $string you must choose one of the SVG specification values: embed|new|none|other|replace.

L<The SVG specification for Behavior Attributes|https://www.w3.org/TR/xlink/#link-behaviors>.

Note: The parameter passed to L<SVG> is actually called C<-show>.

Default: 'new'

'new' is similar to the effect achieved by the following HTML fragment:

	<A HREF="http://www.example.org" target="_blank">...</A>

=item o text => $string

This is the text which will be written into the cell and made clickable.

=item o title => $string.

This string, if not empty, is passed to L<SVG> as the value of the C<-title> parameter.

The effect is to activate a tooltip when you MouseOver the rectangle.

=item o x => $integer

This is the cell # across the SVG.

Cell co-ordinates are numbered 1 .. N.

=item o y => $integer

This is the cell # down the SVG.

Cell co-ordinates are numbered 1 .. N.

=back

=head2 width()

Returns the calculated width, in pixels, of the SVG.

=head2 write(%options)

Writes the SVG to the file name passed to L</new(%options)> or passed to C<write()>. The latter
value has priority.

=head2 x_cell_count()

Gets the count of cells horizontally.

C<x_cell_count> is a parameter to L</new()>.

=head2 x_offset()

Gets the horizontal gap between the edges of the SVG and the grid.

C<x_offset> is a parameter to L</new()>.

=head2 y_cell_count()

Gets the count of cells vertically.

C<y_cell_count> is a parameter to L</new()>.

=head2 y_offset()

Gets the vertical gap between the edges of the SVG and the grid.

C<y_offset> is a parameter to L</new()>.

=head1 FAQ

=head2 Does this module support Unicode?

Yes. The L</write(%options)> method uses an encoding of UTF-8 on the output file handle.

Note: To use Unicode, you must include 'use utf8;' in your programs. See scripts/synopsis.pl.

=head2 Does this module support tootips via MouseOver?

Yes. Just search this document for 'MouseOver'.

=head2 Does this module use the SVG 'g' element?

No. This means there is no grouping done by default. Nevertheless, you can call L</svg()> to get
the internal SVG object, and use 'g' yourself at any time.

See L<https://www.w3.org/TR/SVG11/struct.html#Groups> for details of the 'g' element.

=head2 How does this module handle duplicate element ids?

By using method parameters to generate a hopefully-unique id. This line copied from the
L</image_link(%options)> method shows the general technique I've used:

	id => "image_$options{x}_$options{y}", # Try to make it unique.

=head2 Is there any difference between C<fill> and C<stroke> for text?

I don't think so, but I have had some odd results. Ultimately, you need to read the docs for the
L<SVG> module to see what it expects.

=head2 Is there any way to hide the coordinate numbering system?

Not in V 1.00. However, it is on the TODO list.

=head1 See Also

L<GD>

L<Imager>

L<Image::Magick>

L<Image::Magick::Chart>

L<Image::Magick::PolyText>

L<Image::Magick::Tiler>

L<SVG>

L<https://www.w3.org/Graphics/SVG/>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/SVG-Grid>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=SVG::Grid>.

=head1 Author

L<SVG::Grid> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

My homepage: L<http://savage.net.au/>

=head1 Copyright and Licence

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
