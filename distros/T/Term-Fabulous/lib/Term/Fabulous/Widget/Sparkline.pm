package Term::Fabulous::Widget::Sparkline;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::XYChart;

class Term::Fabulous::Widget::Sparkline
	:isa(Term::Fabulous::Widget::XYChart)
	:strict(params)
{
	use Carp qw(croak);
	use Clay::XS qw(sizing_grow);
	use List::Util ();
	use Term::Fabulous::Check qw(boolean one_of);

	use constant SERIES => 'values';

	my @TYPES = qw(line area bar);

	field $type   :param = 'line';
	field $values :param = [];
	field $color  :param = undef;
	field $min    :param = undef;
	field $max    :param = undef;
	field $zero   :param = undef;    # undef: by type

	ADJUST {
		one_of( $self, type => $type, @TYPES );
		$zero = $self->_checked_zero($zero);
		$self->legend('none');
		$self->x_axis( { visible => 0 } );
		$self->_set_value_axis( $type, $min, $max, $zero );
		$self->add_series( { name => SERIES, type => $type, data => $values, ( defined $color ? ( color => $color ) : () ) } );
		$values = undef;
	}

	method default_series_type () { return 'line' }

	# A bar takes at least a cell: with more values than columns, the bars
	# show the newest values that fit.
	method fit_prepared :override ( $width, $kind, $categories, $prepared ) {
		return ( $kind, $categories, $prepared ) unless $type eq 'bar' && $kind eq 'category';
		foreach my $entry (@$prepared) {
			my $count = $entry->{xs}->@*;
			next if $count <= $width;
			my @kept = $count - $width .. $count - 1;
			$entry->{$_} = [ $entry->{$_}->@[@kept] ] foreach grep { $entry->{$_} } qw(ys lows highs);
			$entry->{xs} = [ 0 .. $#kept ];
		}
		my $shown = List::Util::min( scalar @$categories, $width );
		return ( $kind, [ @$categories[ @$categories - $shown .. $#$categories ] ], $prepared );
	}
	method value_axis_edges :override () { return 1 }
	method draws_baseline   :override () { return 0 }

	method _checked_zero ($value) {
		return defined $value ? boolean( $self, zero => $value ) : undef;
	}

	# The value axis for a type and its ends; dies (changing nothing) for
	# ends that are no numbers. Areas and bars include zero unless told
	# otherwise, lines never.
	method _set_value_axis ( $kind, $low, $high, $from_zero ) {
		$self->y_axis( { visible => 0, grid => 0, zero => $from_zero // ( $kind eq 'line' ? 0 : 1 ), ( defined $low ? ( min => $low ) : () ), ( defined $high ? ( max => $high ) : () ) } );
		return;
	}

	# A sparkline is one row high, and as wide as its parent lets it be.
	method natural_size :override () {
		return ( sizing_grow(), 1 );
	}

	method values (@new) {
		return [ $self->series(SERIES)->{data}->@* ] unless @new;
		$self->set_data( SERIES, $new[0] );
		return $self->values;
	}

	# Adds values at the end; with max_points, the oldest go.
	method add_values (@new) {
		$self->add_points( SERIES, @new );
		return $self;
	}

	method type (@new) {
		return $type unless @new;
		one_of( $self, type => $new[0], @TYPES );
		$self->check_series_type( SERIES, $new[0] );
		$self->_set_value_axis( $new[0], $min, $max, $zero );
		$self->set_series( SERIES, type => $new[0] );
		$type = $new[0];
		return $type;
	}

	method color (@new) {
		return $color unless @new;
		$self->set_series( SERIES, color => $new[0] );
		$color = $new[0];
		return $color;
	}

	method min (@new) {
		return $min unless @new;
		$self->_set_value_axis( $type, $new[0], $max, $zero );
		$min = $new[0];
		return $min;
	}

	method max (@new) {
		return $max unless @new;
		$self->_set_value_axis( $type, $min, $new[0], $zero );
		$max = $new[0];
		return $max;
	}

	method zero (@new) {
		return $zero unless @new;
		my $from_zero = $self->_checked_zero( $new[0] );
		$self->_set_value_axis( $type, $min, $max, $from_zero );
		$zero = $from_zero;
		return $zero;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, type => 'scalar', color => 'color', min => 'scalar', max => 'scalar', zero => 'boolean', values => \&_parse_values );
	}

	# values 3 5 2 8
	method _parse_values ($kid) {
		my @values = map { $_->as_perl } $kid->args->@*;
		croak ref($self) . ": layout property 'values' takes numbers" if $kid->props->@* || $kid->children->@*;
		$self->values( \@values );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Sparkline - A small chart without axes, one row high

=head1 SYNOPSIS

	use Clay::XS qw(sizing_fixed);
	use Term::Fabulous::Widget::Sparkline;

	my $load = Term::Fabulous::Widget::Sparkline->new(
		type       => 'line',          # line, area or bar
		values     => \@last_minute,
		min        => 0,
		max        => 100,
		max_points => 60,
		color      => '#61afef',
		layout     => { sizing => { width => sizing_fixed(16) } },
	);

	$load->add_values($percent);       # every second; the oldest value goes

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-sparkline.svg" alt="Four server rows, each with its load as a line, an area and a bar sparkline of sixteen columns next to the current value"></p>

=end html

F<examples/widgets/sparkline.pl> shows the three types side by side and
adds a value to each every second.

=head1 DESCRIPTION

A sparkline is a chart the size of a word: one row high, as wide as the
layout gives it, with no axes, labels or legend, for a trend next
to a number in a dashboard, a list or a table cell. It holds one series
of values and draws it in one of three types:

=over

=item C<line>

A line of Braille dots (a quarter of a row high), the values spread
over the whole width.

=item C<area>

The area under the line, filled with eighth blocks (an eighth of a row
high), the values spread over the whole width.

=item C<bar>

One column per value, filled with eighth blocks; when there are more
values than columns, the newest that fit.

=back

The row covers the range from the smallest to the largest value, so the
shape fills the height; C<min> and C<max> fix the range instead, so
several sparklines compare (and a bar sparkline grows from C<min>). A
line uses the whole range; areas and bars include zero unless C<zero>
says otherwise.

A Sparkline is a L<Term::Fabulous::Widget::XYChart> with one series
named C<values>, so its options apply: C<curve>, C<marker>,
C<line_style>, C<transform>, C<max_points>, C<span_gaps>, and hover,
which emphasizes nothing (there is only one series) but fires
C<SeriesHover> with the series C<values> and the index and value under
the pointer. Unless the layout sets a width or a height, it is one row
high and grows in width; a sparkline more rows high draws its shape in
all of them. A sparkline has no title unless you give it one (with
C<title>, see L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>); a title
is drawn only when the sparkline is three or more rows high, and takes
its first row.

L<Term::Fabulous::Cookbook::Charts> shows sparklines as table cells.

=head1 CONSTRUCTOR

=head2 new

	my $sparkline = Term::Fabulous::Widget::Sparkline->new(%parameters);

The parameters of L<Term::Fabulous::Widget::Chart/CONSTRUCTOR> (a
sparkline never shows a legend, whatever C<legend> says, and shows a
C<title> only when it is three or more rows high), the series options of
L<Term::Fabulous::Widget::XYChart/CONSTRUCTOR> (C<max_points>,
C<curve>, C<marker>, ...), and:

=over

=item C<type>

C<line> (the default), C<area> or C<bar>.

=item C<values>

An array reference of numbers (C<undef> for a gap). Default: none.

=item C<color>

The color of the series, in any format a canvas cell takes. Default:
C<undef>, the first color of the C<palette>.

=item C<min>, C<max>

Numbers: the fixed ends of the value range; values beyond them are cut
off. With both given, C<min> must be less than C<max>. Default:
C<undef>, from the data. An invalid value, or a C<min> not below the
C<max>, dies when it is given, with a message that names C<min> or
C<max>.

=item C<zero>

A boolean: whether the range includes 0. Default: C<undef>, which means
true for C<area> and C<bar> (they grow from 0) and false for C<line>.
With C<< zero =E<gt> 0 >>, an area or bar sparkline of values far from 0
(prices) spends the row on their changes, and its bars grow from the
smallest value.

=back

=head1 METHODS

=head2 values

	my $values = $sparkline->values;
	$sparkline->values( [ 1, 2, 3 ] );

Reads (a copy) or replaces the values.

=head2 add_values

	$sparkline->add_values( 4, 5 );

Appends values; with C<max_points>, the oldest are dropped.

=head2 type, color, min, max, zero

Read and set the parameters; an invalid value dies and changes nothing.

	$sparkline->type('bar');
	$sparkline->max(undef);    # from the data again

Everything else: L<Term::Fabulous::Widget::XYChart/METHODS>.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::Sparkline as Sparkline

	Sparkline "load" {
		type "bar"
		color "#61afef"
		min 0
		max 100
		max_points 60
		values 12 15 11 18 16
	}

C<type>, C<color>, C<min>, C<max>, C<zero> as the parameters, C<values>
with the numbers as its arguments, and the properties of
L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::LineChart>,
L<Term::Fabulous::Widget::Chart>, L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Manual::Tables/CELL WIDGETS>,
L<Term::Fabulous::Cookbook::Charts/Show sparklines in table cells (Sparkline)>,
L<Term::Fabulous::Cookbook::ChartTechniques/Print charts in a report (Static)>,
the example program F<examples/widgets/sparkline.pl>.

=cut
