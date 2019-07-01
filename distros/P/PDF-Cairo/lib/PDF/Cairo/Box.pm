package PDF::Cairo::Box;

use 5.016;
use strict;
use warnings;
use Carp;
use PDF::Cairo::Util qw(paper_size);

our $VERSION = "1.05";
$VERSION = eval $VERSION;

=head1 NAME

PDF::Cairo::Box - rectangle-manipulation library

=head1 SYNOPSIS

PDF::Cairo::Box is designed to simplify PDF layout for forms, graph
paper, calendars, practice sheets, etc.

    use PDF::Cairo::Box;

    my $page = PDF::Cairo::Box->new(paper => "a4");
    my $half = $page->fold;
    $half->shrink(all => 36)->rotate;
    $page->center($half);
    ...

=head1 DESCRIPTION

=cut

BEGIN {
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw();
	our @EXPORT_OK = qw();
	our %EXPORT_TAGS = (all => \@EXPORT_OK);
}

=head2 Creating new boxes

=over 4

=item B<new> %options

=over 4

=item width => $width,

=item height => $height,

=item paper => $paper_size,

=item wide|landscape => 1,

=item tall|portrait => 1

=item x => $LLx,

=item y => $LLy,

=back

All arguments are optional. If called with no arguments, creates a
zero-size box with lower-left corner at (x,y)==(0,0). If called with
the name of a known paper size (see L<PDF::Cairo::Papers>) and
optional orientation, sets width and height to the size of that paper
in points.

=cut

sub new {
	my $class = shift;
	my %options = @_;
	my $self = {
		x => $options{x} || 0,
		y => $options{y} || 0,
		w => 0,
		h => 0,
	};
	paper_size($self, %options);
	bless($self,$class);
	return $self;
}

=item B<bounds> $box, ...

Return a new box that contains all the boxes passed as arguments.

=cut

sub bounds {
	shift unless ref $_[0]; # called w/ '->'
	my ($x1, $y1, $x2, $y2);
	foreach my $box (@_) {
		$x1 = $box->{x} if ! defined $x1 or $box->{x} < $x1;
		$y1 = $box->{y} if ! defined $y1 or $box->{y} < $y1;
		my $xtmp = $box->{x} + $box->{w};
		my $ytmp = $box->{y} + $box->{h};
		$x2 = $xtmp if ! defined $x2 or $xtmp > $x2;
		$y2 = $ytmp if ! defined $y2 or $ytmp > $y2;
	}
	return PDF::Cairo::Box->new(
		x => $x1, y => $y1,
		width => $x2 - $x1, height => $y2 - $y1
	);
}

=back

=head2 Setting/getting box parameters

=over 4

=item B<bbox> [$x,$y, $width,$height]

Return the boundaries of the current box (convenient for passing to
rect()). If four arguments are passed, set it to those values instead.

=cut

sub bbox {
	my $self = shift;
	if (@_ == 4) {
		$self->xy(shift, shift);
		$self->size(shift, shift);
	}else{
		return ($self->xy, $self->size);
	}
	return $self;
}

=item B<height> [$height]

Return the height of the current box. If an argument is passed, set the
height to that value instead.

=cut

sub height {
	my $self = shift;
	if (defined $_[0]) {
		$self->{h} = $_[0];
	}
	return $self->{h};
}

=item B<iswide>

Returns true if the current box is wider than it is tall.

=cut

sub iswide {
	my $self = shift;
	return $self->{w} > $self->{h};
}

=item B<size> [$width, $height]

Return the (width, height) of the current box. If two arguments are
passed, set them to those values.

=cut

sub size {
	my $self = shift;
	if (defined $_[0] and defined $_[1]) {
		$self->{w} = $_[0];
		$self->{h} = $_[1];
	}
	return ($self->{w}, $self->{h});
}

=item B<width> [$width]

Return the width of the current box. If an argument is passed, set the
width to that value instead.

=cut

sub width {
	my $self = shift;
	if (defined $_[0]) {
		$self->{w} = $_[0];
	}
	return $self->{w};
}

=item B<x> [$x]

Return the X coordinate of the current box's lower-left corner. If an
argument is passed, move the box to that location instead.

=cut

sub x {
	my $self = shift;
	if (defined $_[0]) {
		$self->{x} = $_[0];
	}
	return $self->{x};
}

=item B<y> [$y]

Return the Y coordinate of the current box's lower-left corner. If an
argument is passed, move the box to that location instead.

=cut

sub y {
	my $self = shift;
	if (defined $_[0]) {
		$self->{y} = $_[0];
	}
	return $self->{y};
}

=item B<xy> [$x, $y]

Return the (X,Y) coordinates of the current box's lower-left corner.
If two arguments are passed, move the box to that location instead.

=cut

sub xy {
	my $self = shift;
	if (defined $_[0] and defined $_[1]) {
		$self->{x} = $_[0];
		$self->{y} = $_[1];
	}
	return ($self->{x}, $self->{y});
}

=item B<cx> [$center_x]

Return the X coordinate of the current box's center. If an argument
is passed, move the box to that location instead.

=cut

sub cx {
	my $self = shift;
	if (defined $_[0]) {
		$self->{x} = $_[0] - $self->{w} / 2;
	}
	return $self->{x} + $self->{w} / 2;
}

=item B<cy> [$center_y]

Return the Y coordinate of the current box's center. If an argument
is passed, move the box to that location instead.

=cut

sub cy {
	my $self = shift;
	if (defined $_[0]) {
		$self->{y} = $_[0] - $self->{h} / 2;
	}
	return $self->{y} + $self->{h} / 2;
}

=item B<cxy> [$center_x, $center_y]

Return the (X,Y) coordinates of the current box's center.
If two arguments are passed, move the box to that location instead.

=cut

sub cxy {
	my $self = shift;
	if (defined $_[0] and defined $_[1]) {
		$self->{x} = $_[0] - $self->{w} / 2;
		$self->{y} = $_[1] - $self->{h} / 2;
	}
	return ($self->{x} + $self->{w} / 2, $self->{y} + $self->{h} / 2);
}

=back

=head2 Creating boxes from existing boxes

=over 4

=item B<copy>

Return a new copy of the current box.

=cut

sub copy {
	my ($self) = @_;
	my $tmp = {};
	foreach my $k (keys %$self) {
		$tmp->{$k} = $self->{$k};
	}
	bless($tmp, ref $self);
	return $tmp;
}

=item B<fold> $folds

ISO-style paper folding, without rounding. Returns a new box created
by halving the long dimension of the current box $folds times (default
1), maintaining the current orientation. That is, folding
portrait-format A4 once creates portrait-format A5, and folding it
twice creates portrait-format A6.

=cut

sub fold {
	my $self = shift;
	my $folds = shift || 1;
	my $newbox = $self->copy;
	if ($folds >= 1) {
		my $iswide = $self->{w} > $self->{h};
		my ($short, $long) = $iswide ?
			($self->{h}, $self->{w}) :
			($self->{w}, $self->{h});
		for my $i (1..$folds) {
			my $tmp = $short;
			$short = $long / 2;
			$long = $tmp;
		}
		if ($iswide) {
			$newbox->{w} = $long;
			$newbox->{h} = $short;
		}else{
			$newbox->{w} = $short;
			$newbox->{h} = $long;
		}
	}
	return $newbox;
}

=item B<grid> %options

=over 4

=item rows => $n,

=item columns => $n,

=item width => $size|'$size%',

=item height => $size|'$size%',

=item xpack => 'left|center|right',

=item ypack => 'top|center|bottom',

=item center => 1,

=back

Create a grid of new boxes by splitting the current box according to
the passed arguments, either by absolute size or percentage. Returns
an array of rows from top to bottom, with each row pointing to an array
of cells, left to right. This is equivalent to calling slice by columns
on the result of slice by rows.

By default, leftover space is evenly distributed between the boxes
and the parent box. The xpack/ypack arguments aligns all of the boxes at
the position requested, with no space between them. The center argument
is equivalent to setting both xpack and ypack to center.

=cut

sub grid {
	my $self = shift;
	my %options = @_;
	my ($slice_w, $slice_h) = (0, 0);
	if (defined $options{columns}) {
		$slice_w = $self->{w} / int($options{columns});
	}elsif (defined $options{width}) {
		if ($options{width} =~ s/%$//) {
			$slice_w = $self->{w} * $` / 100;
		}else{
			$slice_w = $options{width};
		}
	}else{
		croak "grid(): must supply both columns/width and rows/height";
	}
	if (defined $options{rows}) {
		$slice_h = $self->{h} / int($options{rows});
	}elsif (defined $options{height}) {
		if ($options{height} =~ s/%$//) {
			$slice_h = $self->{h} * $` / 100;
		}else{
			$slice_h = $options{height};
		}
	}else{
		croak "grid(): must supply both columns/width and rows/height";
	}
	my @result;
	%options = (
		center => $options{center},
		xpack => $options{xpack},
		ypack => $options{ypack},
	);
	foreach my $row ($self->slice(height => $slice_h, %options)) {
		push(@result, [ $row->slice(width => $slice_w, %options) ]);
	}
	return @result;
}

=item B<slice> %options

=over 4

=item rows => $n,

=item columns => $n,

=item width => $size|'$size%',

=item height => $size|'$size%',

=item xpack => 'left'|'center'|'right',

=item ypack => 'top'|'center'|'bottom',

=item center => 1,

=back

Returns an array of new boxes created by dividing the current box
according to the single argument provided. Width/height can be an
absolute size or percentage, while row/column must be an integer
greater than 1. Rows are returned left-to-right, columns
top-to-bottom.

By default, leftover space is evenly distributed between the boxes
and the parent box. The xpack/ypack arguments aligns all of the boxes at
the position requested, with no space between them. The center argument
is equivalent to setting both xpack and ypack to center.

=cut

sub slice {
	my $self = shift;
	my %options = @_;
	my ($slice_w, $slice_h) = (0, 0);
	my @result;
	if (defined $options{columns}) {
		$slice_w = $self->{w} / int($options{columns});
	}elsif (defined $options{rows}) {
		$slice_h = $self->{h} / int($options{rows});
	}elsif (defined $options{width}) {
		if ($options{width} =~ s/%$//) {
			$slice_w = $self->{w} * $` / 100;
		}else{
			$slice_w = $options{width};
		}
	}elsif (defined $options{height}) {
		if ($options{height} =~ s/%$//) {
			$slice_h = $self->{h} * $` / 100;
		}else{
			$slice_h = $options{height};
		}
	}
	if (defined $options{center}) {
		$options{xpack} = 'center';
		$options{ypack} = 'center';
	}
	if ($slice_w) {
		# columns, from left to right
		my $slices = int($self->{w} / $slice_w + 0.00001);
		my $space = $self->{w} - $slices * $slice_w;
		my ($margin, $gutter) = (0, 0);
		if (defined $options{xpack}) {
			if ($options{xpack} eq 'center') {
				$margin = $space / 2;
			}elsif ($options{xpack} eq 'right') {
				$margin = $space;
			}
		}else{
			$margin = $space / ($slices + 1);
			$gutter = $margin;
		}
		my $x = $self->{x} + $margin;
		foreach my $slice (1..$slices) {
			push(@result, PDF::Cairo::Box->new(
				x => $x, y => $self->{y},
				width => $slice_w, height => $self->{h},
			));
			$x += $slice_w + $gutter;
		}
	}elsif ($slice_h) {
		# rows, from top to bottom
		my $slices = int($self->{h} / $slice_h + 0.00001);
		my $space = $self->{h} - $slices * $slice_h;
		my ($margin, $gutter) = (0, 0);
		if (defined $options{ypack}) {
			if ($options{ypack} eq 'center') {
				$margin = $space / 2;
			}elsif ($options{ypack} eq 'bottom') {
				$margin = $space;
			}
		}else{
			$margin = $space / ($slices + 1);
			$gutter = $margin;
		}
		my $y = $self->{y} + $self->{h} - $margin;
		foreach my $slice (1..$slices) {
			$y -= $slice_h;
			push(@result, PDF::Cairo::Box->new(
				x => $self->{x}, y => $y,
				width => $self->{w}, height => $slice_h,
			));
			$y -= $gutter;
		}
	}
	return @result;
}

=item B<split> %options

=over 4

=item width => $size|'$size%',

=item height => $size|'$size%',

=back

Returns two new boxes created by splitting the current box at the
supplied width or height, either by absolute size or percentage.

=cut

sub split {
	my $self = shift;
	my %options = @_;
	my $box1 = $self->copy;
	my $box2 = $self->copy;
	if (defined $options{width}) {
		my $width = $options{width};
		if ($width =~ s/%$//) {
			$width = $self->{w} * $` / 100;
		}
		$box1->{w} = $width;
		$box2->{w} = $self->{w} - $width;
		$box2->{x} = $self->{x} + $width;
	}elsif (defined $options{height}) {
		my $height = $options{height};
		if ($height =~ s/%$//) {
			$height = $self->{h} * $` / 100;
		}
		$box1->{h} = $height;
		$box1->{y} = $self->{y} + $self->{h} - $height;
		$box2->{h} = $self->{h} - $height;
	}else{
		croak "PDF::Cairo::Box::Split: must supply either height or width";
	}
	return ($box1, $box2);
}

=item B<unfold> $folds

Reverses an ISO-style paper fold. Returns a new box created by
doubling the length of the short side of the current box $folds times,
maintaining the current orientation.

Note that due to rounding, the official B5 is slightly larger than an
unfolded B6.

=cut

sub unfold {
	my $self = shift;
	my $folds = shift || 1;
	my $newbox = $self->copy;
	if ($folds >= 1) {
		my $iswide = $self->{w} > $self->{h};
		my ($short, $long) = $iswide ?
			($self->{h}, $self->{w}) :
			($self->{w}, $self->{h});
		for my $i (1..$folds) {
			my $tmp = $long;
			$long = $short * 2;
			$short = $tmp;
		}
		if ($iswide) {
			$newbox->{w} = $long;
			$newbox->{h} = $short;
		}else{
			$newbox->{w} = $short;
			$newbox->{h} = $long;
		}
	}
	return $newbox;
}

#TODO: figure out if I really need this, and how it should work...
#=item B<fill> $box, %options

=back

=head2 Moving boxes

=over 4

=item B<align> [$box, ...], %options

=over 4

=item top => 1,

=item center_v => 1,

=item bottom => 1,

=item left => 1,

=item center_h => 1,

=item right => 1,

=item center => 1,

=back

Align one or more boxes to the current box. For convenience, if only
one box is passed in the first argument, it doesn't need to be wrapped
in an array reference.

=cut

sub align {
	my $self = shift;
	my $boxes = shift;
	$boxes = [ $boxes ] unless ref $boxes eq 'ARRAY';
	my %options = @_;
	if ($options{center}) {
		$options{center_v} = 1;
		$options{center_h} = 1;
	}
	foreach my $box (@$boxes) {
		if ($options{top}) {
			$box->{y} = $self->{y} + $self->{h} - $box->{h};
		}elsif ($options{center_v}) {
			$box->{y} = $self->{y} + ($self->{h} - $box->{h}) / 2;
		}elsif ($options{bottom}) {
			$box->{y} = $self->{y};
		}
		if ($options{left}) {
			$box->{x} = $self->{x};
		}elsif ($options{center_h}) {
			$box->{x} = $self->{x} + ($self->{w} - $box->{w}) / 2;
		}elsif ($options{right}) {
			$box->{x} = $self->{x} + $self->{w} - $box->{w};
		}
	}
	return @$boxes;
}

=item B<center> $box, ...

Center one or more boxes to the current box.

=cut

sub center {
	my $self = shift;
	$self->align([ @_ ], center => 1);
}

=item TODO B<distribute>

distribute({by_row, by_col, pack}, $box, ...)

=item B<move> $x, $y

=item B<move> $box

Move a box to an absolute location, or to the same (x,y)
position as another box.

=cut

sub move {
	my $self = shift;
	if (ref $_[0]) {
		$self->{x} = $_[0]->{x};
		$self->{y} = $_[0]->{y};
	}elsif (@_) {
		$self->{x} = $_[0];
		$self->{y} = $_[1];
	}else{
		croak "PDF::Cairo::Box::move: missing arguments";
	}
	return $self;
}

=item B<rel_move> $delta_x, $delta_y

Move a box relative to its current location.

=cut

sub rel_move {
	my $self = shift;
	if (@_) {
		$self->{x} = defined $self->{x} ? $self->{x} + $_[0] : $_[0];
		$self->{y} = defined $self->{y} ? $self->{y} + $_[1] : $_[1];
	}else{
		croak "PDF::Cairo::Box::rel_move: missing arguments";
	}
	return $self;
}

=back

=head2 Resizing boxes

=over 4

=item B<expand> %options

=over 4

=item top => $size|'$size%',

=item bottom => $size|'$size%',

=item left => $size|'$size%',

=item right => $size|'$size%',

=item all => $size|'$size%',

=back

Increases the size of the current box, maintaining its relative
position.

=cut

sub expand {
	my $self = shift;
	my %options = @_;
	if ($options{all}) {
		foreach my $opt (qw(top bottom left right)) {
			$options{$opt} = $options{all};
		}
	}
	# convert percentages to absolute values before applying any changes
	foreach my $opt (qw(top bottom)) {
		if (defined $options{$opt} and $options{$opt} =~ s/%$//) {
			$options{$opt} = $self->{h} * $` / 100;
		}
	}
	foreach my $opt (qw(left right)) {
		if (defined $options{$opt} and $options{$opt} =~ s/%$//) {
			$options{$opt} = $self->{w} * $` / 100;
		}
	}
	if ($options{top}) {
		$self->{h} += $options{top};
	}
	if ($options{bottom}) {
		$self->{h} += $options{bottom};
		$self->{y} -= $options{bottom};
	}
	if ($options{left}) {
		$self->{w} += $options{left};
		$self->{x} -= $options{left};
	}
	if ($options{right}) {
		$self->{w} += $options{right};
	}
	return $self;
}

=item B<rotate>

Swaps width/height of a box. Does not change its (x,y) position.

=cut

sub rotate {
	my $self = shift;
	my $tmpwidth = $self->{w};
	$self->{w} = $self->{h};
	$self->{h} = $tmpwidth;
	$self->{size} = "";
	return $self;
}

=item B<scale> $scale

Scale the location and size of the current box (1 = no change).

=cut

sub scale {
	my $self = shift;
	my $scale = shift;
	if (defined $scale and $scale > 0) {
		$self->{x} *= $scale;
		$self->{y} *= $scale;
		$self->{w} *= $scale;
		$self->{h} *= $scale;
	}
	return $self;
}

=item B<shrink> %options

=over 4

=item top => $size|'$size%',

=item bottom => $size|'$size%',

=item left => $size|'$size%',

=item right => $size|'$size%',

=item all => $size|'$size%',

=back

Reduces the size of the current box, maintaining its relative
position.

=cut

sub shrink {
	my $self = shift;
	my %options = @_;
	if ($options{all}) {
		foreach my $opt (qw(top bottom left right)) {
			$options{$opt} = $options{all};
		}
	}
	# convert percentages to absolute values before applying any changes
	foreach my $opt (qw(top bottom)) {
		if (defined $options{$opt} and $options{$opt} =~ s/%$//) {
			$options{$opt} = $self->{h} * $` / 100;
		}
	}
	foreach my $opt (qw(left right)) {
		if (defined $options{$opt} and $options{$opt} =~ s/%$//) {
			$options{$opt} = $self->{w} * $` / 100;
		}
	}
	if ($options{top}) {
		$self->{h} -= $options{top};
	}
	if ($options{bottom}) {
		$self->{h} -= $options{bottom};
		$self->{y} += $options{bottom};
	}
	if ($options{left}) {
		$self->{w} -= $options{left};
		$self->{x} += $options{left};
	}
	if ($options{right}) {
		$self->{w} -= $options{right};
	}
	return $self;
}

=back

=head1 BUGS

Gosh, none I hope.

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=cut

1;
