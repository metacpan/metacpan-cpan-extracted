#!perl
use v5.26;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use I18N::Langinfo qw(
	langinfo

	ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7

    ABMON_1 ABMON_2 ABMON_3 ABMON_4  ABMON_5  ABMON_6
    ABMON_7 ABMON_8 ABMON_9 ABMON_10 ABMON_11 ABMON_12

    DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7

    MON_1 MON_2 MON_3 MON_4 MON_5 MON_6
    MON_7 MON_8 MON_9 MON_10 MON_11 MON_12

    D_FMT T_FMT
    AM_STR PM_STR
    );
use POSIX;
use String::Sprintf;

my %formats = (
	a   => \&abbreviated_day_name,
	A   => \&full_day_name,
	b   => \&abbreviated_month_name,
	B   => \&full_month_name,
	c   => \&preferred_representation,
	C   => \&century_number,
	d   => \&day_of_month_decimal_leading_zero,
	D   => \&american,
	e   => \&day_of_month_decimal_leading_space,
	F   => \&iso8601,
	G   => \&week_based_year_with_century,
	g   => \&week_based_year_without_century,
	h   => \&full_month_name,
	H   => \&hour24_decimal_leading_zero,
	I   => \&hour12_decimal_leading_zero,
	j   => \&day_of_year_decimal,
	k   => \&hour24_decimal_leading_blank,
	l   => \&hour12_decimal_leading_blank,
	'm' => \&month_decimal,
	M   => \&minute_decimal,
	n   => sub { "\n" },
	O   => sub {},
	p   => \&am_pm,
	P   => sub { lc &am_pm },
	r   => \&am_pm_time,
	R   => \&time_24_hour_no_seconds,
	's' => \&seconds_since_epoch,
	S   => \&seconds_decimal,
	t   => sub { "\t" },
	T   => \&time_24_hour_with_seconds,
	u   => \&day_of_week_one_decimal,
	U   => \&week_number,
	V   => \&iso_8601_week_number,
	w   => \&day_of_week_zero_decimal,
	W   => \&week_number_decimal,
	x   => \&preferred_date_without_time_representation,
	X   => \&preferred_time_without_date_representation,
	'y' => \&year_decimal_without_century,
	Y   => \&year_decimal_with_century,
	z   => \&time_zone_numeric,
	Z   => \&time_zone_name,
	'+' => \&date1_format,  # doesn't work because it doesn't match + yet
	'%' => sub { '%' },
	'*' => sub { warn "Invalid specifier <$_[-1]>\n" },
	);
my $formatter = String::Sprintf->formatter( %formats );

# %a
sub abbreviated_day_name ( $w, $v, $V, $l ) {
	(
		map { langinfo($_) }
		(ABDAY_1, ABDAY_2, ABDAY_3, ABDAY_4, ABDAY_5, ABDAY_6, ABDAY_7)
	)[ &day_of_week_zero_decimal ]
	}

# %A
sub full_day_name ( $w, $v, $V, $l ) {
	(
		map { langinfo($_) }
		(DAY_1, DAY_2, DAY_3, DAY_4, DAY_5, DAY_6, DAY_7)
	)[ &day_of_week_zero_decimal ]
	}

# %b
sub abbreviated_month_name ( $w, $v, $V, $l ) {
	(
		map { langinfo($_) }
		(
		ABMON_1, ABMON_2, ABMON_3, ABMON_4,  ABMON_5,  ABMON_6,
		ABMON_7, ABMON_8, ABMON_9, ABMON_10, ABMON_11, ABMON_12
		)
	)[ &month_decimal - 1 ]
	}

# %B
sub full_month_name ( $w, $v, $V, $l ) {
	(
		map { langinfo($_) }
		(
		MON_1, MON_2, MON_3, MON_4,  MON_5,  MON_6,
		MON_7, MON_8, MON_9, MON_10, MON_11, MON_12
		)
	)[ &month_decimal - 1 ]
	}

# %c
sub preferred_representation ( $w, $v, $V, $l ) {
	# eventually make this localized
	sprintf( '%s %s %2d %2d:%2d:$2d %4d',
		&abbreviated_day_name,
		&abbreviated_month_name,
		&day_of_month_decimal_leading_space,
		&hour24_decimal_leading_zero,
		&minute_decimal,
		&seconds_decimal,
		&year_decimal_with_century,
		);
	}

# %C
sub century_number ( $w, $v, $V, $l ) { $V->[0]->year % 100 }

# %d
sub day_of_month_decimal_leading_zero ( $w, $v, $V, $l ) { sprintf "%02d", $V->[0]->day_of_month }

# %D
sub american ( $w, $v, $V, $l ) {
	join( '/',
		&month_decimal,
		&day_of_month_decimal_leading_zero,
		&year_decimal_without_century,
		);
	}

# %e
sub day_of_month_decimal_leading_space ( $w, $v, $V, $l ) {
	my $h = $V->[0]->hour;
	$h %= 12 if $h > 12;
	sprintf "%02d", $h;
	}

# %F
sub iso8601 ( $w, $v, $V, $l ) {
	join( 'T',
		join( '-',
			&year_decimal_with_century,
			&month_decimal,
			&day_of_month_decimal_leading_zero
			),
		join( ':',
			&hour24_decimal_leading_zero,
			&minute_decimal,
			&seconds_decimal
			)
		);
	}

# %G

sub week_based_year_with_century ( $w, $v, $V, $l ) {
	warn "%$l is not yet implemented\n";
	return;
	}

# %g
sub week_based_year_without_century ( $w, $v, $V, $l ) {
	warn "%$l is not yet implemented\n";
	return;
	}

# %H
sub hour24_decimal_leading_zero ( $w, $v, $V, $l ) { sprintf "%02d", $V->[0]->hour }

# %I
sub hour12_decimal_leading_zero ( $w, $v, $V, $l ) {
	my $h = $V->[0]->hour;
	$h %= 12 if $h > 12;
	sprintf "%02d", $h;
	}

# %j
sub day_of_year_decimal ( $w, $v, $V, $l ) { $V->[0]->day_of_year }

# %k
sub hour24_decimal_leading_blank ( $w, $v, $V, $l ) {
	sprintf '%2s', $V->[0]->hour;
	}

# %l
sub hour12_decimal_leading_blank ( $w, $v, $V, $l ) {
	my $s = $V->[0]->hour;
	$s %= 12 if $s > 12;
	sprintf '%2s', $s;
	}

# %m
sub month_decimal ( $w, $v, $V, $l ) { sprintf '%02d', $V->[0]->month }

# %M
sub minute_decimal ( $w, $v, $V, $l ) { sprintf '%02d', $V->[0]->minute }

# %p
sub am_pm ( $w, $v, $V, $l ) { $V->[0]->hour > 11 ? langinfo( PM_STR ) : langinfo( AM_STR ) }

# %r
sub am_pm_time ( $w, $v, $V, $l ) {
	join( ':',
		&hour12_decimal_leading_zero,
		&minute_decimal,
		&seconds_decimal,
		) . ' ' . &am_pm;
	}

# %R
sub time_24_hour_no_seconds ( $w, $v, $V, $l ) {
	sprintf '%02d:%02d', map { $V->[0]->$_() } qw(hour minute)
	}

# %s
sub seconds_since_epoch ( $w, $v, $V, $l ) { $V->[0]->epoch }

# %S
sub seconds_decimal ( $w, $v, $V, $l ) { sprintf '%02d', $V->[0]->second }

# %T
sub time_24_hour_with_seconds ( $w, $v, $V, $l ) {
	sprintf '%02d:%02d:%02d', map { $V->[0]->$_() } qw(hour minute second)
	}

# %u
sub day_of_week_one_decimal ( $w, $v, $V, $l ) { $V->[0]->day_of_week }

# %U
sub week_number ( $w, $v, $V, $l ) { &week_number_decimal }

# %V 2020-01-02T21:34:34+00:00
sub iso_8601_week_number ( $w, $v, $V, $l ) { &week_number_decimal }

# %w
sub day_of_week_zero_decimal ( $w, $v, $V, $l ) { $V->[0]->day_of_week - 1 }

# %W
sub week_number_decimal ( $w, $v, $V, $l ) { $V->[0]->week - 1 }

# %x
sub preferred_date_without_time_representation ( $w, $v, $V, $l ) {
	$formatter->sprintf( langinfo( D_FMT ), $V->[0] );
	}

# %X
sub preferred_time_without_date_representation ( $w, $v, $V, $l ) {
	$formatter->sprintf( langinfo( T_FMT ), $V->[0] );
	}

# %y
sub year_decimal_without_century ( $w, $v, $V, $l ) { $V->[0]->year % 100 }

# %Y
sub year_decimal_with_century ( $w, $v, $V, $l ) { $V->[0]->year }

# %z
# https://stackoverflow.com/a/47428274/2766176
sub time_zone_numeric ( $w, $v, $V, $l ) {
	my @local = localtime;
	my @gmtime = gmtime;

	my $hour_diff = $local[2] - $gmtime[2];
	my $min_diff  = $local[1] - $gmtime[1];

	my $total_diff = $hour_diff * 60 + $min_diff;
	my $hour = int($total_diff / 60);
	my $min = abs($total_diff - $hour * 60);

	sprintf("%+03d:%02d", $hour, $min);
	}

# %Z
sub time_zone_name ( $w, $v, $V, $l ) {
	( POSIX::tzname() )[ (localtime)[8] ];
	}

# %+  Thu Jan  2 17:01:17 EST 2020
sub date1_format ( $w, $v, $V, $l ) {
	sprintf( '%s %s %2d %2d:%2d:$2d %s %4d',
		&abbreviated_day_name,
		&abbreviated_month_name,
		&day_of_month_decimal_leading_space,
		&hour24_decimal_leading_zero,
		&minute_decimal,
		&seconds_decimal,
		&time_zone_name,
		&year_decimal_with_century,
		);
	}

use Time::Moment;

say $formatter->sprintf( $ARGV[0], Time::Moment->now );

=encoding utf8

=head1 NAME

strftime - format a time value

=head1 SYNOPSIS

	% strftime FORMAT

	% strftime %H:%M

=head1 DESCRIPTION

This is basically the C<date> command, but implemented with L<String::Sprintf>
as a demonstration. Rather than work with a list of arguments, this
knows how to use a single value to fill in many specifiers. Each subroutine
gets a list of all the arguments to C<sprintf> and each merely uses the
first value.

=head2 The strftime specifiers

From the I<strftime(3)> manpage:

   %a     The abbreviated name of the day of the week according to the
		  current locale.  (Calculated from tm_wday.)

   %A     The full name of the day of the week according to the current
		  locale.  (Calculated from tm_wday.)

   %b     The abbreviated month name according to the current locale.
		  (Calculated from tm_mon.)

   %B     The full month name according to the current locale.
		  (Calculated from tm_mon.)

   %c     The preferred date and time representation for the current
		  locale.

   %C     The century number (year/100) as a 2-digit integer. (SU)
		  (Calculated from tm_year.)

   %d     The day of the month as a decimal number (range 01 to 31).
		  (Calculated from tm_mday.)

   %D     Equivalent to %m/%d/%y.  (Yecch—for Americans only.  Americans
		  should note that in other countries %d/%m/%y is rather common.
		  This means that in international context this format is
		  ambiguous and should not be used.) (SU)

   %e     Like %d, the day of the month as a decimal number, but a
		  leading zero is replaced by a space. (SU) (Calculated from
		  tm_mday.)

   %E     Modifier: use alternative format, see below. (SU)

   %F     Equivalent to %Y-%m-%d (the ISO 8601 date format). (C99)

   %G     The ISO 8601 week-based year (see NOTES) with century as a
		  decimal number.  The 4-digit year corresponding to the ISO
		  week number (see %V).  This has the same format and value as
		  %Y, except that if the ISO week number belongs to the previous
		  or next year, that year is used instead. (TZ) (Calculated from
		  tm_year, tm_yday, and tm_wday.)

   %g     Like %G, but without century, that is, with a 2-digit year
		  (00–99). (TZ) (Calculated from tm_year, tm_yday, and tm_wday.)

   %h     Equivalent to %b.  (SU)

   %H     The hour as a decimal number using a 24-hour clock (range 00
		  to 23).  (Calculated from tm_hour.)

   %I     The hour as a decimal number using a 12-hour clock (range 01
		  to 12).  (Calculated from tm_hour.)

   %j     The day of the year as a decimal number (range 001 to 366).
		  (Calculated from tm_yday.)

   %k     The hour (24-hour clock) as a decimal number (range 0 to 23);
		  single digits are preceded by a blank.  (See also %H.)
		  (Calculated from tm_hour.)  (TZ)

   %l     The hour (12-hour clock) as a decimal number (range 1 to 12);
		  single digits are preceded by a blank.  (See also %I.)
		  (Calculated from tm_hour.)  (TZ)

   %m     The month as a decimal number (range 01 to 12).  (Calculated
		  from tm_mon.)

   %M     The minute as a decimal number (range 00 to 59).  (Calculated
		  from tm_min.)

   %n     A newline character. (SU)

   %O     Modifier: use alternative format, see below. (SU)

   %p     Either "AM" or "PM" according to the given time value, or the
		  corresponding strings for the current locale.  Noon is treated
		  as "PM" and midnight as "AM".  (Calculated from tm_hour.)

   %P     Like %p but in lowercase: "am" or "pm" or a corresponding
		  string for the current locale.  (Calculated from tm_hour.)
		  (GNU)

   %r     The time in a.m. or p.m. notation.  In the POSIX locale this
		  is equivalent to %I:%M:%S %p.  (SU)

   %R     The time in 24-hour notation (%H:%M).  (SU) For a version
		  including the seconds, see %T below.

   %s     The number of seconds since the Epoch, 1970-01-01 00:00:00
		  +0000 (UTC). (TZ) (Calculated from mktime(tm).)

   %S     The second as a decimal number (range 00 to 60).  (The range
		  is up to 60 to allow for occasional leap seconds.)
		  (Calculated from tm_sec.)

   %t     A tab character. (SU)

   %T     The time in 24-hour notation (%H:%M:%S).  (SU)

   %u     The day of the week as a decimal, range 1 to 7, Monday being
		  1.  See also %w.  (Calculated from tm_wday.)  (SU)

   %U     The week number of the current year as a decimal number, range
		  00 to 53, starting with the first Sunday as the first day of
		  week 01.  See also %V and %W.  (Calculated from tm_yday and
		  tm_wday.)

   %V     The ISO 8601 week number (see NOTES) of the current year as a
		  decimal number, range 01 to 53, where week 1 is the first week
		  that has at least 4 days in the new year.  See also %U and %W.
		  (Calculated from tm_year, tm_yday, and tm_wday.)  (SU)

   %w     The day of the week as a decimal, range 0 to 6, Sunday being
		  0.  See also %u.  (Calculated from tm_wday.)

   %W     The week number of the current year as a decimal number, range
		  00 to 53, starting with the first Monday as the first day of
		  week 01.  (Calculated from tm_yday and tm_wday.)

   %x     The preferred date representation for the current locale
		  without the time.

   %X     The preferred time representation for the current locale
		  without the date.

   %y     The year as a decimal number without a century (range 00 to
		  99).  (Calculated from tm_year)

   %Y     The year as a decimal number including the century.
		  (Calculated from tm_year)

   %z     The +hhmm or -hhmm numeric timezone (that is, the hour and
		  minute offset from UTC). (SU)

   %Z     The timezone name or abbreviation.

   %+     The date and time in date(1) format. (TZ) (Not supported in
		  glibc2.)

   %%     A literal '%' character.

=head1 COPYRIGHT

Copyright © 2020, brian d foy, all rights reserved.

=head1 LICENSE

You can use this code under the terms of the Artistic License 2.

=cut
