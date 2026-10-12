package Term::Fabulous::Chart::Format;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(number_formatter time_formatter format_value format_values decimals_of check_number_format check_time_format);

use Carp qw(croak);
use POSIX qw(floor strftime);
use Scalar::Util qw(looks_like_number);

my @SI_PREFIXES    = ( [ 1e12, 'T' ], [ 1e9, 'G' ], [ 1e6, 'M' ], [ 1e3, 'k' ] );
my %NUMBER_FORMATS = map { $_ => 1 } qw(auto si integer percent);

# The decimals a number needs to be written to six significant digits,
# up to 10.
sub decimals_of ($number) {
	foreach my $decimals ( 0 .. 10 ) {
		my $scaled = abs($number) * 10**$decimals;
		return $decimals if abs( $scaled - int( $scaled + 0.5 ) ) < 1e-6 * ( $scaled || 1 );
	}
	return 10;
}

sub _fixed ( $value, $decimals ) {
	my $text = sprintf '%.*f', $decimals, $value;
	$text =~ s/\A-(?=0(?:\.0*)?\z)//;    # no "-0"
	return $text;
}

# 12000 as "12k": the largest prefix the value reaches.
sub _si ( $value, $decimals_of_unit ) {
	my $magnitude = abs $value;
	foreach my $prefix (@SI_PREFIXES) {
		my ( $unit, $symbol ) = @$prefix;
		next if $magnitude < $unit;
		return _fixed( $value / $unit, $decimals_of_unit->($unit) ) . $symbol;
	}
	return _fixed( $value, $decimals_of_unit->(1) );
}

sub check_number_format ( $owner, $name, $format ) {
	return $format if !defined $format || ref $format eq 'CODE';
	croak "$owner: $name must be auto, si, integer, percent, a sprintf format with one % conversion or a code reference, got " . ( ref $format ? ref($format) . ' reference' : "'$format'" )
		if ref $format || !( $NUMBER_FORMATS{$format} || $format =~ /%/ );
	return $format;
}

# A function that writes the tick labels of a numeric axis whose ticks are
# $step apart and reach $largest (in magnitude): the format of the axis
# (auto, si, integer, percent, a sprintf format or a code reference
# called with the value).
sub number_formatter ( $format, $step, $largest ) {
	$format //= 'auto';
	return $format if ref $format eq 'CODE';
	return sub ($value) { sprintf $format, $value }
		if $format =~ /%/;

	my $step_decimals = decimals_of( $step || 1 );
	return sub ($value) { _fixed( $value, 0 ) }
		if $format eq 'integer';
	return sub ($value) { _fixed( $value * 100, decimals_of( ( $step || 1 ) * 100 ) ) . '%' }
		if $format eq 'percent';

	my $decimals_of_unit = sub ($unit) { decimals_of( ( $step || 1 ) / $unit ) };
	return sub ($value) { _si( $value, $decimals_of_unit ) }
		if $format eq 'si' || abs($largest) >= 1e4;
	return sub ($value) { _fixed( $value, $step_decimals ) };
}

# A value shown on its own (a bar's label, a legend entry): as many
# decimals as it has, at most two (three significant digits below 1), and
# large values with an SI prefix.
sub format_value ( $value, $format = undef ) {
	return '' unless defined $value;
	return $format->($value) if ref $format eq 'CODE';
	return sprintf $format, $value if defined $format && $format =~ /%/;
	return _fixed( $value * 100, abs( $value * 100 ) < 10 ? 1 : 0 ) . '%' if defined $format && $format eq 'percent';
	return _fixed( $value,       0 ) if defined $format                                      && $format eq 'integer';
	my $magnitude = abs $value;
	if ( $magnitude >= 1e6 || ( defined $format && $format eq 'si' && $magnitude >= 1e3 ) ) {
		my $text = _si( $value, sub ($unit) { $magnitude / $unit >= 100 ? 0 : 1 } );
		$text =~ s/\.0(?=[kMGT]\z)//;
		return $text;
	}
	my $decimals = $magnitude >= 100 ? 1 : $magnitude >= 1 ? 2 : $magnitude == 0 ? 0 : 2 - floor( log($magnitude) / log(10) );
	$decimals = 6 if $decimals > 6;
	my $text = _fixed( $value, $decimals );
	$text =~ s/(\.\d*?)0+\z/$1/;
	$text =~ s/\.\z//;
	return $text;
}

# Values shown together (the labels of bars): as format_value writes
# them, but all with the decimals the one with most decimals has.
sub format_values ( $values, $format = undef ) {
	my @texts = map { format_value( $_, $format ) } @$values;
	return @texts if defined $format || grep { /[^0-9.\-]/ } @texts;
	my $decimals = 0;
	foreach my $text (@texts) {
		$decimals = length $1 if $text =~ /\.([0-9]+)\z/ && length $1 > $decimals;
	}
	return map { _fixed( $_, $decimals ) } @$values;
}

sub check_time_format ( $owner, $name, $format ) {
	return $format if !defined $format || ref $format eq 'CODE';
	croak "$owner: $name must be a strftime format or a code reference, got " . ( ref $format ? ref($format) . ' reference' : "'$format'" )
		if ref $format || $format !~ /%/;
	return $format;
}

# A function that writes epoch seconds with a strftime format (or calls a
# code reference with the epoch); local time unless $utc.
sub time_formatter ( $format, $utc ) {
	return $format if ref $format eq 'CODE';
	return sub ($epoch) { strftime( $format, $utc ? gmtime $epoch : localtime $epoch ) };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Format - Number and date labels of charts

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Format qw(number_formatter format_value time_formatter);

	my $label = number_formatter( 'auto', 0.25, 2 );    # ticks 0.25 apart up to 2
	say $label->(1.5);                                  # 1.50
	say number_formatter( 'auto', 5000, 40000 )->(25000);    # 25k
	say number_formatter( 'percent', 0.1, 1 )->(0.3);        # 30%
	say format_value(1234.5678);                             # 1234.6
	say time_formatter( '%H:%M', 1 )->(0);                   # 00:00

=head1 DESCRIPTION

The chart widgets write their tick labels, value labels and legend values
with these functions. An axis takes its C<format> from the axis hash (see
L<Term::Fabulous::Widget::XYChart/AXES>):

=over

=item C<auto> (the default)

As many decimals as the distance between two ticks needs, so all labels of
an axis have the same number of decimals (C<0.0>, C<0.5>, C<1.0>). When a
tick reaches 10000, the labels use SI prefixes (C<10k>, C<2.5M>).

=item C<si>

Always with SI prefixes: k (thousand), M (million), G and T.

=item C<integer>

Whole numbers.

=item C<percent>

The value times 100 with a percent sign: C<0.25> is C<25%>. Use it for
fractions, such as the axis of a C<percent> stack or a C<normalize>d
series.

=item a sprintf format

Anything with a C<%>, such as C<'%.1f °C'> or C<'$%d'>, is a
L<perlfunc/sprintf> format called with the value.

=item a code reference

Called with the value; returns the label.

=back

Time axes take a L<POSIX/strftime> format, such as C<'%H:%M'> or
C<'%Y-%m-%d'>, or a code reference called with the epoch seconds.

=head1 FUNCTIONS

=head2 number_formatter

	my $format = number_formatter( $format, $step, $largest );

A function that writes the label of one tick, for ticks C<$step> apart
whose largest magnitude is C<$largest>. C<$format> is one of the formats
above (C<undef> is C<auto>); the decimals follow C<$step>, so all labels
of an axis get the same number of decimals. A code reference is
returned as it is.

=head2 format_value

	my $text = format_value( $value, $format );

A single value, as a bar's value label or a hover label shows it. Without
C<$format>: one decimal from 100 on, two from 1 to 100, three
significant digits below 1 (at most six decimals), trailing zeros
removed, and SI prefixes from a million on (C<2.5M>). With a
C<$format> as above, that format; C<si> uses prefixes from a thousand
on, C<percent> writes one decimal below 10%. C<undef> gives the empty
string.

	say format_value(0.012345);            # 0.0123
	say format_value(2_500_000);           # 2.5M
	say format_value( 0.05, 'percent' );    # 5.0%

=head2 format_values

	my @texts = format_values( \@values, $format );

Several values shown together, such as the labels of the bars of a
chart: written like C<format_value> writes them, but all with as many
decimals as the one that needs most (C<48.0> beside C<51.2>), unless a
C<$format> is given or a value has an SI prefix.

=head2 time_formatter

	my $format = time_formatter( $strftime_format, $utc );
	say $format->($epoch);

A function that writes epoch seconds with a L<POSIX/strftime> format,
in local time, or in UTC when C<$utc> is true. A code reference is
returned as it is.

=head2 decimals_of

The decimals needed to write a number to six significant digits: 0 for
C<20>, 2 for C<0.25>, 6 for C<1/3>; at most 10.

=head2 check_number_format, check_time_format

	check_number_format( $owner, $name, $format );

Die unless C<$format> is a valid number (or time) format, with C<$owner>
and C<$name> at the start of the message; return it. C<undef> and code
references are always valid.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Scale>, L<Term::Fabulous::Widget::XYChart>,
L<Term::Fabulous::Widget::XYChart/Axis keys>,
L<Term::Fabulous::Cookbook::Charts/Draw a line chart with labels and points (LineChart)>,
L<Term::Fabulous::Cookbook::ChartTechniques/Plot values over time (time axis, from and to, a dashed forecast)>.

=cut
