package Term::Fabulous::Widget::Table::Value;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(is_blank number_of date_epoch date_interval compare_values natural_compare);

use Feature::Compat::Try;
use Scalar::Util qw(blessed looks_like_number);
use Time::Local 1.30 qw(timelocal_posix timegm_posix);

# The column types: how a raw value is turned into something that orders.
my %IS_TYPE = map { $_ => 1 } qw(string number date);

sub is_blank ($value) {
	return !defined $value || ( !ref $value && $value eq '' ) ? 1 : 0;
}

# A finite number, or undef.
sub number_of ($value) {
	return undef if is_blank($value) || ref $value || !looks_like_number($value);
	my $number = $value + 0;
	return $number == $number && $number - $number == 0 ? $number : undef;
}

# The span of time a date string names: [ first second, first second
# after it ). Its granularity is the last part given: "2024" is a year,
# "2024-05" a month, "2024-05-03" a day, "2024-05-03 14:30" a minute.
# Local time, or UTC with a trailing Z. Undef for anything else.
sub date_interval ($text) {    ## no critic (Subroutines::RequireFinalReturn) PPI does not parse try/catch
	return undef unless defined $text && !ref $text;
	my ( $year, $month, $day, $hour, $minute, $second, $utc ) = $text =~ m{
		\A \s* ([0-9]{4})
		(?: - ([0-9]{1,2})
			(?: - ([0-9]{1,2})
				(?: [ T] ([0-9]{1,2}) : ([0-9]{2}) (?: : ([0-9]{2}) )? )?
			)?
		)?
		\s* (Z)? \s* \z
	}x or return undef;
	return undef if defined $utc && !defined $hour;

	my @start    = ( $second // 0, $minute // 0, $hour // 0, $day // 1, ( $month // 1 ) - 1, $year - 1900 );
	my $to_epoch = defined $utc ? \&timegm_posix : \&timelocal_posix;
	try {
		my $first = $to_epoch->(@start);
		return undef unless _names_a_real_day( $first, \@start, defined $utc );
		my $after
			= defined $second ? $first + 1
			: defined $minute ? $first + 60
			: defined $day    ? $to_epoch->( 0, 0, 0, _next_day( @start[ 3, 4, 5 ] ) )
			: defined $month  ? $to_epoch->( 0, 0, 0, 1, ( $start[4] + 1 ) % 12, $start[5] + ( $start[4] == 11 ? 1 : 0 ) )
			:                   $to_epoch->( 0, 0, 0, 1, 0, $start[5] + 1 );
		return [ $first, $after ];
	}
	catch ($error) {
		return undef;
	}
}

# Time::Local accepts 31 April as 1 May; a date that does not exist is no
# date.
sub _names_a_real_day ( $epoch, $parts, $utc ) {
	my @back = $utc ? gmtime $epoch : localtime $epoch;
	return $back[3] == $parts->[3] && $back[4] == $parts->[4] && $back[5] == $parts->[5] ? 1 : 0;
}

# ( day, month, year ) of the day after a calendar day, in Time::Local's
# numbering; counted in UTC at noon, so no clock change gets in the way.
sub _next_day ( $day, $month, $year ) {
	my @next = gmtime( timegm_posix( 0, 0, 12, $day, $month, $year ) + 86400 );
	return @next[ 3, 4, 5 ];
}

# The epoch seconds of a date value: a number (already epoch seconds), an
# object with an epoch method (DateTime, Time::Piece, Time::Moment), or a
# date string as date_interval reads it (its first second). Undef for
# anything else.
sub date_epoch ($value) {
	return undef if is_blank($value);
	return $value->epoch + 0 if blessed $value && $value->can('epoch');
	my $number = number_of($value);
	return $number if defined $number;
	my $interval = date_interval($value) // return undef;
	return $interval->[0];
}

# Orders text the way people count: digit runs compare as numbers, so
# "file9" comes before "file10". Case-insensitive.
sub natural_compare ( $left, $right ) {
	my @left  = split /([0-9]+)/, fc "$left";
	my @right = split /([0-9]+)/, fc "$right";
	while ( @left && @right ) {
		my ( $mine, $theirs ) = ( shift @left, shift @right );
		my $order
			= ( $mine =~ /\A[0-9]+\z/ && $theirs =~ /\A[0-9]+\z/ )
			? ( $mine <=> $theirs || length $mine <=> length $theirs )
			: $mine cmp $theirs;
		return $order if $order;
	}
	return @left <=> @right;
}

# Orders two raw values of a column type; blank values and values that
# are not of the type come last, in either direction of the sort (the
# caller reverses only the result for known values).
sub compare_values ( $type, $left, $right ) {
	die "Term::Fabulous::Widget::Table::Value: unknown column type '$type'" unless $IS_TYPE{$type};
	return fc("$left") cmp fc("$right") if $type eq 'string';
	my $of = $type eq 'number' ? \&number_of : \&date_epoch;
	return $of->($left) <=> $of->($right);
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Value - Read numbers and dates from table values

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table::Value qw(date_epoch date_interval number_of);

	my $epoch = date_epoch('2024-05-03 14:30');    # local time
	my $same  = date_epoch(1714739400);            # epoch seconds stay as they are
	my ( $from, $until ) = @{ date_interval('2024-05') };    # all of May 2024
	my $price = number_of('12.50');                # 12.5; undef for 'n/a'

=head1 DESCRIPTION

The functions L<Term::Fabulous::Widget::Table> uses to read the values of
C<number> and C<date> columns when it sorts and filters them. They are
exported on request. Use them in comparators and filters of your own to
read values the same way.

=head1 FUNCTIONS

=head2 is_blank

	is_blank($value)    # 1 for undef and '', else 0

=head2 number_of

The value as a finite number, or C<undef> when it is blank, a
reference, not a number (C<looks_like_number>), infinite or NaN.

=head2 date_interval

	my $span = date_interval('2024-05-03');    # [ first second, first second of the next day ]

The span of time a date string names, as an array reference
C<[ $first, $after ]> of epoch seconds: C<$first> is the first second
of the span, C<$after> the first second after it. The span is as long
as the last part the string gives:

=for highlighter language=text

	2024                   the year 2024
	2024-05                May 2024
	2024-05-03             that day
	2024-05-03 14:30       that minute (also 2024-05-03T14:30)
	2024-05-03 14:30:15    that second

Months, days and hours may have one digit. The string is read as local
time (the time zone of the program, C<TZ>), unless it ends with C<Z>
after a time (C<2024-05-03T14:30Z>), which means UTC. Spaces around it
are allowed. Returns C<undef> for anything else, including dates that do
not exist (C<2024-02-30>).

=head2 date_epoch

The epoch seconds of a date value, or C<undef>:

=over

=item *

a number is taken as epoch seconds, also a string of digits: C<'2024'>
is 2024 seconds after the epoch, not the year (write C<'2024-01-01'>
for the year);

=item *

an object with an C<epoch> method (L<DateTime>, L<Time::Piece>,
L<Time::Moment>) gives what that method returns;

=item *

a string gives the first second of its L</date_interval>.

=back

=head2 compare_values

=for highlighter language=perl

	my $order = compare_values( 'number', $left, $right );    # -1, 0 or 1

Orders two values of a column type: C<string> (case-insensitive,
L<perlfunc/fc>), C<number> (by L</number_of>) or C<date> (by
L</date_epoch>). Both values must be readable as the type; the table
sorts blank and unreadable values after all others before it calls
this. An unknown type dies.

=head2 natural_compare

	my @sorted = sort { natural_compare( $a, $b ) } qw(file10 File9 file1);    # file1 File9 file10

Orders text the way people count: runs of digits compare as numbers,
so C<file9> comes before C<file10>; the rest compares
case-insensitively. Returns -1, 0 or 1.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Table::Filter>,
L<Term::Fabulous::Manual::Tables/Dates and numbers>,
L<Term::Fabulous::Manual::TableRows/How values are compared>,
L<Term::Fabulous::Cookbook::TableRows/Filter rows from Perl (numbers, dates, text, raw or shown values)>.

=cut
