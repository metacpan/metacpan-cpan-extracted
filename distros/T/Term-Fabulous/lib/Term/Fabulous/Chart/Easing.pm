package Term::Fabulous::Chart::Easing;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(easing easing_names is_easing_name);

use Carp qw(croak);

use constant PI => 4 * atan2( 1, 1 );

# The "in" form of each family; "out" and "in-out" are derived from it,
# except where the classic formulas differ (back, elastic, bounce).
my %IN = (
	sine    => sub ($t) { 1 - cos( $t * PI / 2 ) },
	quad    => sub ($t) { $t**2 },
	cubic   => sub ($t) { $t**3 },
	quart   => sub ($t) { $t**4 },
	quint   => sub ($t) { $t**5 },
	expo    => sub ($t) { $t <= 0 ? 0 : 2**( 10 * $t - 10 ) },
	circ    => sub ($t) { 1 - sqrt( 1 - $t**2 ) },
	back    => sub ($t) { 2.70158 * $t**3 - 1.70158 * $t**2 },
	elastic => sub ($t) {
		return $t if $t <= 0 || $t >= 1;
		return -( 2**( 10 * $t - 10 ) ) * sin( ( $t * 10 - 10.75 ) * ( 2 * PI ) / 3 );
	},
	bounce => sub ($t) { 1 - _bounce_out( 1 - $t ) },
);

sub _bounce_out ($t) {
	my ( $n, $d ) = ( 7.5625, 2.75 );
	return $n * $t**2 if $t < 1 / $d;
	return $n * ( $t - 1.5 / $d )**2 + 0.75 if $t < 2 / $d;
	return $n * ( $t - 2.25 / $d )**2 + 0.9375 if $t < 2.5 / $d;
	return $n * ( $t - 2.625 / $d )**2 + 0.984375;
}

sub _out ($in) {
	return sub ($t) { 1 - $in->( 1 - $t ) };
}

sub _in_out ($in) {
	return sub ($t) { $t < 0.5 ? $in->( 2 * $t ) / 2 : 1 - $in->( 2 - 2 * $t ) / 2 };
}

my %EASING = ( linear => sub ($t) { $t } );
foreach my $family ( keys %IN ) {
	$EASING{"ease-in-$family"}     = $IN{$family};
	$EASING{"ease-out-$family"}    = _out( $IN{$family} );
	$EASING{"ease-in-out-$family"} = _in_out( $IN{$family} );
}

sub easing_names () {
	my @names = sort keys %EASING;
	return @names;
}

sub is_easing_name ($name) {
	return defined $name && !ref $name && exists $EASING{$name} ? 1 : 0;
}

sub easing ($name) {
	return $EASING{ $name // '' } // croak "Term::Fabulous::Chart::Easing: unknown easing '" . ( $name // 'undef' ) . "' (known: " . join( ', ', easing_names() ) . ")";
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Easing - Easing functions for the curves of
charts

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Easing qw(easing easing_names);
	use Term::Fabulous::Widget::LineChart;

	my $ease = easing('ease-in-out-cubic');
	say $ease->(0.25);    # 0.0625

	# In a chart: every segment between two points follows the curve.
	my $chart = Term::Fabulous::Widget::LineChart->new(
		curve  => 'ease-in-out-sine',
		series => [ { name => 'Steps', data => [ 1, 4, 2, 5 ] } ],
	);

=head1 DESCRIPTION

An easing function maps the way from one point to the next (C<t> from 0
to 1) to the share of the change made so far. A chart whose C<curve> is
an easing name draws each segment of a line or area along that function:
C<linear> is a straight line, C<ease-in-out-sine> a gentle S between
every two points, C<ease-out-bounce> a bounce at the end of every
segment. Every curve passes
through the data points themselves, so the values stay exact; the shape
between them is decoration. For smooth lines that stay faithful to the
data, prefer the C<monotone> curve of L<Term::Fabulous::Chart::Curve>.

The functions are the classic set (as on easings.net): for each of the
families C<sine>, C<quad>, C<cubic>, C<quart>, C<quint>, C<expo>,
C<circ>, C<back>, C<elastic> and C<bounce> there is C<ease-in-FAMILY>
(slow start), C<ease-out-FAMILY> (slow end) and C<ease-in-out-FAMILY>
(slow at both ends), plus C<linear>. C<back> and C<elastic> overshoot:
their curves leave the range between two points for a moment.
That makes 31 names, such as C<ease-in-quad>, C<ease-out-expo> and
C<ease-in-out-elastic>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/cookbook-chart-curves.svg" alt="Six small charts of the same seven points connected linear, step, monotone, catmull-rom, ease-in-out-sine and ease-out-bounce"></p>

=end html

The last two charts in the picture use easings; the program is in
L<Term::Fabulous::Cookbook::ChartStyles/Connect points with curves and easings (curve)>.

=head1 FUNCTIONS

=head2 easing

	my $function = easing($name);

The function of a name: a code reference from C<t> (0 to 1) to the
eased C<t> (0 at 0, 1 at 1). Dies for an unknown name, with all names
in the message.

=head2 easing_names

All names, C<linear> included, sorted.

=head2 is_easing_name

1 for an easing name, else 0.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Curve>, L<Term::Fabulous::Widget::XYChart/Curves>.

=cut
