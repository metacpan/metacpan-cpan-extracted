package Term::Fabulous::Range;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Range :strict(params) {
	use List::Util ();    # min and max are methods here
	use POSIX qw(floor);
	use Term::Fabulous::Check qw(boolean number optional);

	# Key name => [ unit, direction ]: steps, pages or an end of the range.
	my %MOVE_BY_KEY = (
		Left     => [ step => -1 ],
		Down     => [ step => -1 ],
		Right    => [ step =>  1 ],
		Up       => [ step =>  1 ],
		PageDown => [ page => -1 ],
		PageUp   => [ page =>  1 ],
		Home     => [ end  => -1 ],
		End      => [ end  =>  1 ],
	);

	field $owner          :param;    # the widget class the messages name
	field $min            :param :reader = 0;
	field $max            :param :reader;
	field $step           :param :reader = undef;    # undef: any value, no grid
	field $page_step      :param = undef;    # undef: a tenth of the range
	field $paging         :param = 1;    # whether PageUp and PageDown move
	field $value_format   :param :reader = undef;
	field $default_format :param = undef;    # code: ( number, range ) => text
	field $format_percent :param = 0;    # a format gets the percent (and the fraction)
	field $current;

	ADJUST :params ( :$value = undef ) {
		( $min, $max, $step ) = $self->_checked_range( defined $step, min => $min, max => $max, step => $step );
		$page_step      = $self->_checked_page_step($page_step);
		$paging         = boolean( $owner, paging => $paging );
		$value_format   = Term::Fabulous::Check::value_format( $owner, value_format => $value_format );
		$format_percent = boolean( $owner, format_percent => $format_percent );
		die "Term::Fabulous::Range: default_format must be a code reference" if defined $default_format && ref $default_format ne 'CODE';
		$current = $min;
		$self->set_value( $value // $min );
	}

	method _fail ($message) {
		die "$owner: $message";
	}

	# The range with the given parts changed, checked as a whole; a
	# stepped range keeps a step.
	method _checked_range ( $stepped, %range ) {
		my ( $low, $high ) = map { number( $owner, $_ => $range{$_} ) } qw(min max);
		$self->_fail("min ($low) must be less than max ($high)") unless $low < $high;
		return ( $low, $high, undef ) unless $stepped;
		my $increment = number( $owner, step => $range{step} );
		$self->_fail("step must be positive, got $increment") unless $increment > 0;
		return ( $low, $high, $increment );
	}

	method _checked_page_step ($size) {
		$size = optional( \&number, $owner, page_step => $size );
		$self->_fail("page_step must be positive, got $size") if defined $size && $size <= 0;
		return $size;
	}

	# ---------------------------------------------------------------------
	# The grid
	# ---------------------------------------------------------------------

	# Digits after the decimal point in the shortest form of a number:
	# 0.25 has 2, 1e-12 has 12, 1500 has 0.
	sub _decimal_places ($number) {
		my ( $mantissa, $exponent ) = sprintf( '%.15g', $number ) =~ /\A-?(\d+(?:\.\d+)?)(?:e([-+]\d+))?\z/
			or die "Term::Fabulous::Range: cannot read the decimal places of $number";
		my $places = $mantissa =~ /\.(\d+)\z/ ? length $1 : 0;
		return List::Util::max( 0, $places - ( $exponent // 0 ) );
	}

	# Digits after the decimal point that values need: enough for the step
	# and for min, so values stay on the grid and print without
	# floating-point noise.
	method decimals () {
		return List::Util::max( _decimal_places( $step // 1 ), _decimal_places($min) );
	}

	# The nearest value on the grid min, min + step, ... inside the range;
	# without a step, the number limited to the range.
	method snapped ($number) {
		my $inside = List::Util::min( List::Util::max( $number, $min ), $max );
		return $inside unless defined $step;
		my $snapped = $min + floor( ( $inside - $min ) / $step + 0.5 ) * $step;
		$snapped -= $step while $snapped > $max + $step / 1e6;
		$snapped = $min if $snapped < $min;
		return 0 + sprintf '%.*f', $self->decimals, $snapped;
	}

	# The highest value on the grid: max itself when the range is a whole
	# number of steps.
	method top_value () {
		return $self->snapped($max);
	}

	method page_step () {
		return $page_step if defined $page_step;
		my $unit = $step // ( $max - $min ) / 100;
		return List::Util::max( $unit, $unit * floor( ( $max - $min ) / $unit / 10 + 0.5 ) );
	}

	method set_page_step ($size) {
		$page_step = $self->_checked_page_step($size);
		return $self;
	}

	# ---------------------------------------------------------------------
	# The value
	# ---------------------------------------------------------------------

	method value () {
		return $current;
	}

	method fraction_of ($number) {
		return ( $number - $min ) / ( $max - $min );
	}

	method fraction () {
		return $self->fraction_of($current);
	}

	# Sets the value from the program: it must lie in the range.
	method set_value ($number) {
		$number = number( $owner, value => $number );
		$self->_fail("value must be in $min..$max, got $number") if $number < $min || $number > $max;
		$current = $self->snapped($number);
		return $current;
	}

	# Changes min, max and step together, so a new range can be set in one
	# go whatever the old one was; the value moves into it.
	method set_range (%range) {
		my @known   = defined $step ? qw(min max step) : qw(min max);
		my @unknown = grep {
			my $part = $_;
			!grep { $_ eq $part } @known
		} sort keys %range;
		$self->_fail( "set_range takes " . join( ', ', @known[ 0 .. $#known - 1 ] ) . " and $known[-1], got @unknown" ) if @unknown;
		( $min, $max, $step ) = $self->_checked_range( defined $step, min => $min, max => $max, step => $step, %range );
		$current = $self->snapped($current);
		return $self;
	}

	# Moves the value to the grid value nearest to a number, limited to
	# the range; returns 1 when the value changed, else 0. This is how the
	# user moves it: the widget fires its Change event on a change.
	method move_to ($number) {
		my $moved = $self->snapped($number);
		return 0 if $moved == $current;
		$current = $moved;
		return 1;
	}

	# Moves by a number of steps (pages: page_step); returns as move_to.
	method move_by ( $steps, $unit = 'step' ) {
		my $size = $unit eq 'page' ? $self->page_step : $step // $self->page_step / 10;
		return $self->move_to( $current + $steps * $size );
	}

	# Moves as a key asks: the arrows by a step, PageUp and PageDown by a
	# page (unless paging is off), Home and End to an end. Returns undef
	# for a key that does not move a range, else as move_to.
	method move_by_key ($name) {
		my $move = $MOVE_BY_KEY{ $name // '' } // return undef;
		my ( $unit, $direction ) = @$move;
		return undef if $unit eq 'page' && !$paging;
		return $self->move_to( $direction < 0 ? $min : $self->top_value ) if $unit eq 'end';
		return $self->move_by( $direction, $unit );
	}

	# ---------------------------------------------------------------------
	# Writing a value
	# ---------------------------------------------------------------------

	method set_value_format ($format) {
		$value_format = Term::Fabulous::Check::value_format( $owner, value_format => $format );
		return $self;
	}

	# A value as text: with the code reference (which gets the value, and
	# the fraction with format_percent), with the sprintf format (of the
	# value, or of the percent with format_percent), else the widget's
	# default, else the value with the decimals of the grid.
	method format_value ($number) {
		if ( ref $value_format eq 'CODE' ) {
			return $format_percent ? $value_format->( $number, $self->fraction_of($number) ) : $value_format->($number);
		}
		return sprintf $value_format, ( $format_percent ? 100 * $self->fraction_of($number) : $number ) if defined $value_format;
		return $default_format->( $number, $self ) if defined $default_format;
		return sprintf '%.*f', $self->decimals, $number;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Range - A value in a range, on a grid of steps

=head1 SYNOPSIS

	use Term::Fabulous::Range;

	my $range = Term::Fabulous::Range->new( owner => 'My::Dial', min => 0, max => 1, step => 0.1, value => 0.3 );

	$range->value;                  # 0.3
	$range->set_value(0.46);        # 0.5: snapped to the grid
	$range->move_by_key('Right');   # 1: the value moved to 0.6
	$range->move_by_key('End');     # 1: to 1
	$range->move_by_key('End');     # 0: it is there already
	$range->move_by_key('Tab');     # undef: not a key of a range
	$range->fraction;               # 1
	$range->format_value(0.6);      # '0.6'

	$range->set_range( min => -1 );   # the value stays on the new grid

=head1 DESCRIPTION

The value of a widget that picks a number from a range: a
L<Term::Fabulous::Widget::Slider>, a
L<Term::Fabulous::Widget::StarRating> (its half stars are a step of
0.5) and a L<Term::Fabulous::Widget::ProgressBar> (a range without a
step). It holds C<min>, C<max>, an optional C<step> and the value;
checks a range as a whole; snaps a value to the grid C<min>,
C<min + step>, ... and limits it to the range; moves the value by keys,
steps and pages; reports the fraction of the range; and writes a value
as text.

It knows nothing of widgets or events. A method that moves the value
the way a user does returns whether the value changed, and the widget
fires its C<Change> event then. Errors start with the C<owner> given to
the constructor, the widget's class.

=head1 CONSTRUCTOR

=head2 new

	my $range = Term::Fabulous::Range->new( owner => ref($self), min => $min, max => $max, step => $step, value => $value );

=over

=item C<owner>

Required. The name the error messages start with.

=item C<min>, C<max>

Finite numbers, C<min> below C<max>. Default C<min>: 0; C<max> is
required.

=item C<step>

A positive number or C<undef> (the default): with a step, values lie
on the grid C<min>, C<min + step>, ... up to the last grid value at or
below C<max>; without one, a value is any number in the range.

=item C<value>

The value, in the range. Default: C<min>. Snapped to the grid.

=item C<page_step>

How far C<PageUp> and C<PageDown> move: a positive number, or C<undef>
(the default) for a tenth of the range, rounded to whole steps and at
least one step.

=item C<paging>

A boolean. Default: 1. When false, C<PageUp> and C<PageDown> are not
keys of the range (L</move_by_key> returns C<undef> for them).

=item C<value_format>

C<undef> (the default), a C<sprintf> format string or a code
reference, as L<Term::Fabulous::Check/value_format> checks it; see
L</format_value>.

=item C<default_format>

A code reference that writes a value when C<value_format> is C<undef>;
it gets the value and the range. Default: none, the value with
L</decimals> digits after the point.

=item C<format_percent>

A boolean. Default: 0. When true, a C<sprintf> C<value_format> gets the
value's percentage of the range and a code reference gets the value
and its fraction, as a L<Term::Fabulous::Widget::ProgressBar> documents.

=back

Invalid values die: C<OWNER: min (5) must be less than max (5)>,
C<OWNER: step must be positive, got 0>, C<OWNER: value must be in 0..10, got 12>,
and the messages of L<Term::Fabulous::Check>.

=head1 METHODS

=head2 min, max, step

The range. Change it with L</set_range>.

=head2 set_range

	$range->set_range( min => 200, max => 300 );

Changes C<min>, C<max> and C<step> together and checks the result as a
whole, so a new range can be set in one go whatever the old one was.
The value moves into the new range and onto its grid. Unknown parts
die (C<OWNER: set_range takes min, max and step, got low>; a range
without a step takes only C<min> and C<max>). Returns the range.

=head2 value

The value.

=head2 set_value

	$range->set_value(42);

Sets the value as the program does: dies for a number outside the range,
snaps it to the grid and returns it.

=head2 move_to

	my $changed = $range->move_to($number);

Moves the value as the user does: to the grid value nearest to the
number, limited to the range. Returns 1 when the value changed, else 0.

=head2 move_by

	my $changed = $range->move_by(-1);            # a step down
	my $changed = $range->move_by( 1, 'page' );   # a page up

Moves by a number of steps (or pages) with L</move_to>. A range without
a step moves by a tenth of a page.

=head2 move_by_key

	my $changed = $range->move_by_key( $event->main_key_name );

Moves as a key asks: C<Left> and C<Down> a step down, C<Right> and
C<Up> a step up, C<PageDown> and C<PageUp> a page (see C<paging>),
C<Home> to C<min> and C<End> to the highest grid value. Returns
C<undef> for any other key, else what L</move_to> returns.

=head2 fraction, fraction_of

	my $share = $range->fraction;             # of the value
	my $share = $range->fraction_of($number);

Where a number lies in the range, from 0 at C<min> to 1 at C<max>.

=head2 snapped

	my $on_grid = $range->snapped($number);

The grid value nearest to a number, limited to the range; without a
step, the number limited to the range.

=head2 top_value

The highest grid value: C<max> when the range is a whole number of
steps.

=head2 decimals

The digits after the decimal point that the grid needs: enough for the
step and for C<min> (C<0.25> has 2, C<1e-12> has 12). Snapped values are
rounded to them, so they print without floating-point noise.

=head2 page_step, set_page_step

	my $page = $range->page_step;
	$range->set_page_step(25);
	$range->set_page_step(undef);    # a tenth of the range again

=head2 value_format, set_value_format

The format given (see C<value_format> above), and a writer that checks
it.

=head2 format_value

	my $text = $range->format_value($number);

A value as text: with a code reference C<value_format>, what it returns
for the value (and its fraction, with C<format_percent>); with a format
string, C<sprintf> of the value (or of its percentage); else the
C<default_format>; else the value with L</decimals> digits.

=head1 SEE ALSO

L<Term::Fabulous::Role::HasRange>, L<Term::Fabulous::Widget::Slider>,
L<Term::Fabulous::Widget::StarRating>,
L<Term::Fabulous::Widget::ProgressBar>.

=cut
