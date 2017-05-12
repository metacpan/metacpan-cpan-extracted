package Music::Image::Chord;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.006';

use Imager;

my $standard_6 =
	{
	c => 'x32010',
	d => 'xxO232',
	e => '022100',
	g => '210002',
	a => 'x02220',
	f => 'xx3211',
	b => 'xx4442',

	cm => 'xx5543',
	dm => 'xx0231',
	em => '022000',
	gm => 'xx5333',
	am => 'x02210',
	fm => 'xx3111',
	bm => 'xx4432',

	c7 => 'x32310',
	d7 => 'xx0212',
	e7 => '020100',
	g7 => '320001',
	a7 => 'x02020',
	f7 => 'xx1211',
	b7 => 'x21202',
	};

my $black = Imager::Color->new(0,0,0);
my $white = Imager::Color->new(255,255,255);

sub new
	{
	my $class = shift;
	bless {}, $class;
	}

sub bar_thickness { shift->{bar_thickness} ||= shift; }
sub crop_width    { shift->{crop_width}    ||= shift; }
sub debug         { shift->{debug}         ||= shift; }
sub font          { shift->{font}          ||= shift; }
sub file          { shift->{file}          ||= shift; }
sub fret          { shift->{fret}          ||= shift; }

sub bounds
	{
	my $self = shift;
	if(@_>0)
		{
		if($_[0]=~/\D/)
			{
			while(@_)
				{
				$_ = shift;
				if(/^w/i)
					{ $self->{bounds}->{w}    = shift; }
				elsif(/^h/i)
					{ $self->{bounds}->{h}    = shift; }
				elsif(/^xmin/i)
					{ $self->{bounds}->{xmin} = shift; }
				elsif(/^xmax/i)
					{ $self->{bounds}->{xmax} = shift; }
				elsif(/^ymin/i)
					{ $self->{bounds}->{ymin} = shift; }
				elsif(/^ymax/i)
					{ $self->{bounds}->{ymax} = shift; }
				}
			}
		else
			{
			$self->{bounds}->{w} = shift;
			$self->{bounds}->{h} = shift;
			}
		$self->{bounds}->{w} ||=
			$self->{bounds}->{xmax} - $self->{bounds}->{xmin};
		$self->{bounds}->{h} ||=
			$self->{bounds}->{ymax} - $self->{bounds}->{ymin};
		}
	return $self->{bounds};
	}

sub grid
	{
	my $self = shift;
	if(@_>0)
		{
		if($_[0]=~/\D/)
			{
			while(@_)
				{
				$_ = shift;
				if(/^w/i)    { $self->{grid}->{w} = shift; }
				elsif(/^h/i) { $self->{grid}->{h} = shift; }
				elsif(/^x/i) { $self->{grid}->{x} = shift; }
				elsif(/^y/i) { $self->{grid}->{y} = shift; }
				}
			}
		else
			{
			$self->{grid}->{x} = shift;
			$self->{grid}->{y} = shift;
			$self->{grid}->{w} = shift;
			$self->{grid}->{h} = shift;
			}
		}
	return %{$self->{grid}};
	}

sub draw
	{
	my $self = shift;
	while(@_)
		{
		my ($k,$v)=(shift(),shift());
		$self->{$k}=$v;
		}
	$self->{chord}  ||= $standard_6->{lc $self->{name}};

	if(length($self->{chord})<6)
		{
		$self->{chord} .= 'x' x 6-length($self->{chord});
		}

	my $i = 0;

	for(split //,lc $self->{chord})
		{
		if(/x/i)
			{
			push @{$self->{closed}},$i;
			}
		elsif(/[o0]/i)
			{
			push @{$self->{open}},$i;
			}
		else
			{
			push @{$self->{fingering}->[$_-1]},$i if $_>0 and $_<5;
			}
		$i++;
		}

	$self->{open_r}=($self->{grid}->{w}/2)-1;
	$self->{image} = Imager->new
		(
		xsize    => $self->bounds()->{w},
		ysize    => $self->bounds()->{h},
		channels => 1,
		);
	$self->{image}->{DEBUG}=1 if $self->debug();
	$self->{image}->box
		(
		color  => $white,
		xmin   => 0,
		ymin   => 0,
		xmax   => $self->bounds()->{w},
		ymax   => $self->bounds()->{h},
		filled => 1,
		);

	$self->_cropmarks() if $self->crop_width() > 0;
	$self->_grid();
	$self->_open_strings();
	$self->_closed_strings();
	$self->_fingering();
	$self->_top_label();

	$self->file()=~/\.(.*)$/;
	$self->{type} = $1;
	$self->{image}->write(file=>$self->{file},type=>$self->{type});
	}

sub _top_label
	{
	my $self = shift;
	my $text = $self->{name} || $self->{labels}{top};
	my $font = new Imager::Font(file => $self->font());
	$self->{image}->string
		(
		font  => $font,
		text  => $text,
		x     => 0,
		y     => 20,
		size  => 20,
		color => $black
		);
	}

sub _cropmarks
	{
	my $self       = shift;
	my $bounds     = $self->bounds();
	my $crop_width = $self->crop_width();
	$self->{image}->polyline
		(
		points=>
			[
			[0,$crop_width],
			[0,0],
			[$crop_width,0]
			],
		color=>$black
		);
	$self->{image}->polyline
		(
		points=>
			[
			[$bounds->{w}-$crop_width-1,$bounds->{h}-1],
			[$bounds->{w}-1,$bounds->{h}-1],
			[$bounds->{w}-1,$bounds->{h}-$crop_width-1]
			],
		color=>$black
		);
	}

sub _closed_strings
	{
	my $self   = shift;
	my $y      = $self->{grid}->{y}+$self->{grid}->{h}-$self->{grid}->{w};

	for(@{$self->{closed}})
		{
		my $x = $self->{grid}->{x}+$self->{open_r}+($self->{grid}->{w}*$_);
		$self->{image}->polyline
			(
			points=>
				[
				[$x-$self->{open_r},$y-$self->{open_r}],
				[$x+$self->{open_r},$y+$self->{open_r}-1],
				],
			color => $black
			);
		$self->{image}->polyline
			(
			points=>
				[
				[$x+$self->{open_r},$y-$self->{open_r}],
				[$x-$self->{open_r},$y+$self->{open_r}],
				],
			color => $black
			);
		}
	}

sub _open_strings
	{
	my $self   = shift;
	my $y = $self->{grid}->{y}+$self->{grid}->{h}-$self->{grid}->{w};

	for(@{$self->{open}})
		{
		my $x = $self->{grid}->{x}+$self->{open_r}+($self->{grid}->{w}*$_);
		$self->{image}->circle
			(
			r      => $self->{open_r},
			x      => $x,
			y      => $y,
			color  => $black,
			filled => 0
			);
		$self->{image}->circle
			(
			r      => $self->{open_r} - 1,
			x      => $x,
			y      => $y,
			color  => $white,
			filled => 0
			);
		}
	}

sub _fingering
	{
	my $self   = shift;
	my $row    = 0;
	my $grid_y = $self->{grid}->{y}+$self->{grid}->{h}+
		($self->{grid}->{h}/2)+($self->{open_r}/2)-$self->{open_r};

	for my $fret_ref(@{$self->{fingering}})
		{
		for(@{$fret_ref})
			{
			$self->{image}->circle
				(
				r      => $self->{open_r},
				x      => $self->{grid}->{x}+$self->{open_r}+($self->{grid}->{w}*($_)),
				y      => $grid_y+($row*($self->{grid}->{h}+2)),
				color  => $black,
				filled => 0
				);
			}
		$row++;
		}
	}

sub _grid
	{
	my $self = shift;

	for(0..5)
		{
		my $x = $self->{grid}->{x}+$self->{open_r}+($self->{grid}->{w}*$_);

		$self->{image}->polyline
			(
			points=>
				[
				[$x,$self->{grid}->{y}+$self->{grid}->{h}],
				[$x,$self->{grid}->{y}+$self->{grid}->{h}+($self->{grid}->{h}*5)],
				],
			color=>$black
			);
		}
	for(0..4)
		{
		my $y = $self->{grid}->{y}+($self->{grid}->{h}*($_+1));
		$self->{image}->polyline
			(
			points=>
				[
				[$self->{grid}->{x}+$self->{open_r},$y],
				[$self->{grid}->{x}+$self->{open_r}+($self->{grid}->{w}*5),$y],
				],
			color=>$black
			);
		}

	if ($self->fret() == 1)
		{
		$self->{image}->box
			(
			color  => $black,
			xmin   => $self->{grid}->{x}+$self->{open_r},
			ymin   => $self->{grid}->{y}+$self->{grid}->{h}-$self->bar_thickness(),
			xmax   => $self->{grid}->{x}+$self->{open_r}+(5*$self->{grid}->{w}),
			ymax   => $self->{grid}->{y}+$self->{grid}->{h},
			filled => 1,
			);
		}

	$self->{image}->polyline
		(
		points=>
			[
			[$self->{grid}->{x}+$self->{open_r},
			$self->{grid}->{y}+$self->{grid}->{h}+($self->{grid}->{h}*5)],
			[$self->{grid}->{x}+$self->{open_r}+(5*$self->{grid}->{w}),
			$self->{grid}->{y}+$self->{grid}->{h}+($self->{grid}->{h}*5)],
			],
		color=>$black
		);
	}

1;
__END__

=head1 NAME

Music::Image::Chord - Perl extension for generating guitar tab chords

=head1 SYNOPSIS

  use Music::Image::Chord;
  $image = new Music::Image::Chord();
  $old_font = $image->font('/path/to/my/TrueType/font.ttf');
  $old_file = $image->file('/path/to/file/to/save.png');
  $image->draw(name => 'D'); # Write the actual file.

=head1 DESCRIPTION

B<Image::Chord> is a simple package for creating images of guitar chords in any format that the B<Imager> module can produce.

The object's API is as follows:

=over

=item B<new Image::Chord()>

Creates and returns a new Image::Chord object.

=item B<bar_thickness>

Returns and optionally sets the thickness of the fret bar. Only used if on the first fret (which is the default).

=item B<bounds>

Returns and optionally sets the image boundaries. It accepts several formats:

 $image->bounds($width, $height);
 $image->bounds(width=>$wid, height=>$hgt);
 $image->bounds(xmin=>$xmin, xmax=>$xmax, yMIN=>$ymin, YMax=>$ymax);

=item B<crop_width>

Returns and optionally sets the width/height of the crop marks on the image. If this value is not set or is <= 0, then crop marks will not be drawn.

 $image->crop_width(5); # Crop marks will be 5 pixels wide.
 print $image->crop_width(); # Display the current crop mark width.

=item B<debug>

Returns and optionally sets the Imager debugging flag.

 $image->debug(1); # Set debugging
 print $image->debug(); # Get the current debugging value

=item B<font>

Returns and optionally sets the font used to render the chord's title.

 $image->font('/home/jgoff/Bach.ttf'); # Display in the Bach TrueType font
 $foo = $image->font(); # Assign $foo to the image's font

=item B<file>

Returns and optionally sets the file name to save the rendered image to. It also reads the extension of the file to determine how to save the image.

 $image->file('/home/jgoff/chord.png');

=item B<fret>

Returns and optionally sets the beginning fret in the image. Defaults to 1.

 $image->fret(5);
 print $image->fret(); # prints the current fret setting.

=item B<draw([optional named parameters])>

Renders the chord described into the appropriate file.
Optional named parameters are:

  name - The name of the chord
  fret - Beginning fret
  barres - Chord barres, not implemented yet.
  chord - If the chord isn't represented in the list, describe it like 'xx0232'.

$image->draw( name => 'D' ); # Draw a D chord

=item B<grid>

Returns and optionally sets the grid coordinates. X and Y are the UL corner of the grid, and w and h control (for the moment, this will change) the inter-string and inter-fret spacing.

 $image->grid($x,$y,$w,$h); # Set explicitly
 $image->grid(x=>$x,y=>$y,w=>$w,h=>$h); # Set through named parameters.

=back


=head1 SEE ALSO

L<Imager>
perl(1).

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.org<gt>
Inspiration by #perl

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
