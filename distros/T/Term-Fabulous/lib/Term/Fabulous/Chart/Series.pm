package Term::Fabulous::Chart::Series;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Chart::Series :strict(params) {
	use Carp qw(croak);
	use Scalar::Util qw(blessed looks_like_number);
	use Term::Fabulous::Check qw(describe glyph one_of);
	use Term::Fabulous::Chart::Curve qw(check_curve);
	use Term::Fabulous::Chart::Palette qw(chart_color);
	use Term::Fabulous::Chart::Transform qw(parse_transforms);

	my @TYPES = qw(line area bar scatter);

	# The markers each type may draw with.
	my %MARKERS = (
		line    => [qw(braille half quadrant sextant box)],
		area    => [qw(block braille half quadrant sextant)],
		bar     => [qw(block braille half quadrant sextant)],
		scatter => [qw(braille half quadrant sextant)],
	);

	# Dash patterns in subpixel steps.
	my %LINE_STYLE = ( solid => undef, dashed => [ 5, 3 ], dotted => [ 1, 2 ] );

	# The options a series takes besides name, type, data and color; undef
	# means "the chart's setting".
	my @OPTIONS = qw(marker curve tension line line_style points point fill_opacity stack from to transform span_gaps visible max_points trend value_labels);

	field $owner        :param;    # the chart class, for messages
	field $described_as :param = undef;    # how messages name the series; undef: series 'NAME', '': not at all
	field $check_points :param = undef;    # called with the series and its new points before they are stored
	field $name         :param :reader;
	field $type         :param :reader;
	field $slot         :param :reader;    # the palette slot, kept for life

	field $color;
	field $color_opacity = 1;
	field %option;
	field @points;    # [ x as given (undef: the point's index), y or undef ]
	field $revision = 0;

	ADJUST :params (%options) {
		croak "$owner: a series name must be a non-empty string, got " . describe($name)
			unless defined $name && !ref $name && length $name;
		one_of( $owner, "type of series '$name'", $type, @TYPES );
		my ( $data, $given_color ) = ( delete $options{data} // [], delete $options{color} );
		$self->set_color($given_color);
		$self->set_option( $_ => delete $options{$_} ) foreach grep { exists $options{$_} } @OPTIONS;
		croak "$owner: series '$name' does not take " . join( ', ', sort keys %options ) . " (known: name, type, data, color, " . join( ', ', @OPTIONS ) . ")" if %options;
		$self->set_data($data);
	}

	sub _is_number ($value) {
		return defined $value && !ref $value && looks_like_number($value) && $value == $value && $value - $value == 0;
	}

	method revision () {
		return $revision;
	}

	# ---------------------------------------------------------------------
	# Options
	# ---------------------------------------------------------------------

	# A new type; a marker the new type cannot draw with is dropped.
	method set_type ($new) {
		one_of( $owner, "type of series '$name'", $new, @TYPES );
		$type = $new;
		delete $option{marker} if defined $option{marker} && !grep { $_ eq $option{marker} } $MARKERS{$type}->@*;
		$revision++;
		return $self;
	}

	method color () {
		return $color;
	}

	method color_opacity () {
		return $color_opacity;
	}

	method set_color ($new) {
		( $color, $color_opacity ) = defined $new ? chart_color( $owner, "color of series '$name'", $new ) : ( undef, 1 );
		$revision++;
		return $self;
	}

	method option ($key) {
		croak "$owner: unknown series option '$key'" unless grep { $_ eq $key } @OPTIONS;
		return $option{$key};
	}

	# What messages call an option of the series.
	method _label ($key) {
		my $what = $described_as // "series '$name'";
		return length $what ? "$key of $what" : $key;
	}

	method set_option ( $key, $value ) {
		my $label = $self->_label($key);
		if ( !defined $value ) {
			delete $option{$key};
		}
		elsif ( $key eq 'marker' ) {
			my @allowed = $MARKERS{$type}->@*;
			croak "$owner: $label must be one of " . join( ', ', @allowed ) . " for a $type series, got " . describe($value) unless !ref $value && grep { $_ eq $value } @allowed;
			$option{$key} = $value;
		}
		elsif ( $key eq 'curve' ) {
			$option{$key} = check_curve( $owner, $label, $value );
		}
		elsif ( $key eq 'line_style' ) {
			one_of( $owner, $label, $value, keys %LINE_STYLE );
			$option{$key} = $value;
		}
		elsif ( $key eq 'tension' || $key eq 'fill_opacity' ) {
			croak "$owner: $label must be a number from 0 to 1, got " . describe($value) unless _is_number($value) && $value >= 0 && $value <= 1;
			$option{$key} = $value + 0;
		}
		elsif ( $key eq 'point' ) {
			$option{$key} = !ref $value && ( $value eq 'dot' || $value eq 'square' ) ? $value : glyph( $owner, $label, $value );
		}
		elsif ( $key eq 'stack' ) {
			croak "$owner: $label must be a group name, got " . describe($value) if ref $value;
			$option{$key} = "$value";
		}
		elsif ( $key eq 'from' || $key eq 'to' ) {
			croak "$owner: $label must be an x value, got " . describe($value) if ref $value && !( blessed $value && $value->can('epoch') );
			$option{$key} = $value;
		}
		elsif ( $key eq 'transform' ) {
			$option{$key} = parse_transforms( $owner, $label, $value );
		}
		elsif ( $key eq 'max_points' ) {
			croak "$owner: $label must be a positive integer, got " . describe($value) unless !ref $value && $value =~ /\A[1-9][0-9]*\z/;
			$option{$key} = $value + 0;
			$self->_trim;
		}
		else {    # line points span_gaps visible trend value_labels
			croak "$owner: $label must be a plain true or false value, got " . describe($value) if ref $value;
			$option{$key} = $value ? 1 : 0;
		}
		$revision++;
		return $self;
	}

	# The dash pattern of the line style, in subpixel steps.
	method dash_pattern ($style) {
		return $LINE_STYLE{$style};
	}

	method is_visible () {
		return $option{visible} // 1;
	}

	method marker_names :common ($series_type) {
		return ( $MARKERS{$series_type} // [] )->@*;
	}

	method option_names :common () {
		return @OPTIONS;
	}

	# ---------------------------------------------------------------------
	# Data
	# ---------------------------------------------------------------------

	# A data point as [ x or undef, y or undef ]: a number (y; the x is its
	# index), undef (a gap), [ x, y ] or { x => ..., y => ... }.
	method _point ( $item, $index ) {
		return [ undef, undef ] unless defined $item;
		my ( $x, $y );
		if ( !ref $item ) {
			$y = $item;
		}
		elsif ( ref $item eq 'ARRAY' ) {
			croak "$owner: data point $index of series '$name' must be [ x, y ], got an array of " . scalar(@$item) . " values" unless @$item == 2;
			( $x, $y ) = @$item;
		}
		elsif ( ref $item eq 'HASH' ) {
			my @unknown = grep { $_ ne 'x' && $_ ne 'y' } sort keys %$item;
			croak "$owner: data point $index of series '$name' takes only the keys x and y, got @unknown" if @unknown;
			( $x, $y ) = @$item{qw(x y)};
		}
		else {
			croak "$owner: data point $index of series '$name' must be a number, [ x, y ] or { x, y }, got " . describe($item);
		}
		croak "$owner: the y value of data point $index of series '$name' must be a finite number or undef, got " . describe($y) if defined $y && !_is_number($y);
		croak "$owner: the x value of data point $index of series '$name' must be a number, a label or a date, got " . describe($x)
			if ref $x && !( blessed $x && $x->can('epoch') );
		return [ $x, defined $y ? $y + 0 : undef ];
	}

	# The points of new data, parsed and checked; nothing is stored until
	# every point passed.
	method _parsed_points ( $items, $first_index ) {
		my $index = $first_index;
		my @new   = map { $self->_point( $_, $index++ ) } @$items;
		$check_points->( $self, \@new ) if $check_points;
		return @new;
	}

	method set_data ($data) {
		croak "$owner: the data of series '$name' must be an array reference, got " . describe($data) unless ref $data eq 'ARRAY';
		@points = $self->_parsed_points( $data, 0 );
		$self->_trim;
		$revision++;
		return $self;
	}

	method add_points (@items) {
		return $self->push_parsed( $self->parsed_points(@items) );
	}

	# New points as add_points would store them: parsed and checked, and
	# numbered on from the points the series has. Stores nothing.
	method parsed_points (@items) {
		return $self->_parsed_points( \@items, scalar @points );
	}

	# Stores points parsed_points made.
	method push_parsed (@parsed) {
		push @points, @parsed;
		$self->_trim;
		$revision++;
		return $self;
	}

	method clear () {
		@points = ();
		$revision++;
		return $self;
	}

	method _trim () {
		my $limit = $option{max_points} // return;
		$self->keep_last($limit);
		return;
	}

	# Drops all but the newest $limit points.
	method keep_last ($limit) {
		return $self if @points <= $limit;
		splice @points, 0, @points - $limit;
		$revision++;
		return $self;
	}

	# The points as given: [ x or undef, y or undef ] each. Read only.
	method points () {
		return \@points;
	}

	method count () {
		return scalar @points;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Series - One data series of an XY chart

=head1 SYNOPSIS

	# Series are made by the charts from hashes:
	my $chart = Term::Fabulous::Widget::LineChart->new(
		series => [ { name => 'CPU', data => [ 12, 40, 33 ], color => '#3987e5', curve => 'monotone' } ],
	);
	$chart->add_points( CPU => 51, 47 );

=head1 DESCRIPTION

The data and the options of one series of a
L<Term::Fabulous::Widget::XYChart>. The chart widgets create series from
the hashes in their C<series> parameter (see
L<Term::Fabulous::Widget::XYChart/SERIES>) and change them through their
own methods; you do not need this class directly. It checks every option
and data point when it is given, so a wrong value dies at once with the
series' name in the message.

=head1 CONSTRUCTOR

=head2 new

	my $series = Term::Fabulous::Chart::Series->new(
		owner => 'My::Chart',
		name  => 'CPU',
		type  => 'line',
		slot  => 0,
		data  => [ 12, 40, 33 ],
		color => '#3987e5',
		curve => 'monotone',
	);

C<owner> (the class name of the chart, which starts every message),
C<name> (a non-empty string), C<type> (C<line>, C<area>, C<bar> or
C<scatter>) and C<slot> (the palette slot) are required. C<data>
(default: none) and C<color> (default: C<undef>, the palette's) are
checked as L</set_data, add_points, clear> and
L</color, color_opacity, set_color> check them, and every option of
L<Term::Fabulous::Widget::XYChart/SERIES> may be given. Unknown parameters die. Two more
parameters serve the charts:

=over

=item C<described_as>

How the messages about the options name the series. Default: C<undef>,
C<series 'NAME'> (C<curve of series 'CPU' must be ...>); the empty string
leaves the series out (C<curve must be ...>), for the options a chart
takes for all of its series.

=item C<check_points>

A code reference called with the series and an array reference of its
new points (as L</points, count> holds them) before they are stored: from
the constructor, C<set_data>, C<add_points> and C<parsed_points>. It dies for points the
chart cannot show (a radar chart: a label it does not have), and the
data stays as it was. Default: none.

=back

=head1 METHODS

=head2 name, type, slot

The series' name, its type (C<line>, C<area>, C<bar> or C<scatter>) and
its palette slot (the color it has when it has no C<color> of its own).

=head2 set_type

	$series->set_type('area');

Changes the type. Drops the series' own C<marker> when the new type
cannot draw with it. Dies for an unknown type.

=head2 color, color_opacity, set_color

The color as a packed C<0xRRGGBB> integer (C<undef>: the palette's), and
its alpha as an opacity from 0 to 1. C<set_color> takes every color form
of L<Term::Fabulous::Color> or a packed integer; C<undef> returns to the
palette's color.

=head2 option, set_option

	my $curve = $series->option('curve');
	$series->set_option( curve => 'monotone' );

Reads and sets one option (see L<Term::Fabulous::Widget::XYChart/Series keys>);
C<undef> means the chart's setting. Both die for an unknown option name;
C<set_option> also dies for an invalid value.

=head2 set_data, add_points, clear

Replace, extend or empty the data. A data point is a number (the y value,
its x is its position in the series), C<undef> (a gap), C<[ $x, $y ]> or
C<< { x =E<gt> $x, y =E<gt> $y } >>. With C<max_points>, the oldest points
are dropped. An invalid point, or one C<check_points> refuses, dies and
changes nothing.

=head2 parsed_points, push_parsed

	my @parsed = $series->parsed_points( 4, [ 5, 6 ] );    # dies for invalid points
	$series->push_parsed(@parsed);

C<add_points> in two steps, for a caller that adds to several series at
once and must not change any of them when one refuses its points.
C<parsed_points> parses and checks new points as C<add_points> does
(their numbers in messages follow the points the series has) and returns
them, storing nothing; C<push_parsed> stores what it returned, drops the
oldest points with C<max_points> and returns the series.

=head2 points, count

The points as C<[ $x_or_undef, $y_or_undef ]> (read only) and their
number.

=head2 keep_last

	$series->keep_last(100);

Drops all but the newest points, as C<max_points> does.

=head2 is_visible

False when the series' C<visible> option is false. Default: true.

=head2 revision

A number that changes with every change of the series.

=head2 dash_pattern

	my $pattern = $series->dash_pattern('dashed');

The subpixel pattern of a line style.

=head2 marker_names, option_names

	my @markers = Term::Fabulous::Chart::Series->marker_names('bar');

The markers a type of series can be drawn with, and the names of all
options.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>.

=cut
