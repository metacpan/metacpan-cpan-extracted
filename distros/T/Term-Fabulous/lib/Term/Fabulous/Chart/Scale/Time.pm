package Term::Fabulous::Chart::Scale::Time;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Scale;

class Term::Fabulous::Chart::Scale::Time :isa(Term::Fabulous::Chart::Scale) {
	use Carp qw(croak);
	use List::Util ();
	use POSIX qw(floor strftime);
	use Time::Local 1.30 qw(timelocal_posix timegm_posix);
	use Term::Fabulous::Chart::Format qw(time_formatter);

	use constant { MINUTE => 60, HOUR => 3600, DAY => 86400 };

	# The tick intervals, finest first: [ unit, count, approximate seconds ].
	my @INTERVALS = (
		( map { [ second => $_, $_ ] } 1, 2, 5, 10, 15, 30 ),
		( map { [ minute => $_, $_ * MINUTE ] } 1, 2, 5, 10, 15, 30 ),
		( map { [ hour   => $_, $_ * HOUR ] } 1,   2, 3, 6,  12 ),
		( map { [ day    => $_, $_ * DAY ] } 1,    2 ),
		[ week => 1, 7 * DAY ],
		( map { [ month => $_, $_ * 30.44 * DAY ] } 1,  2, 3, 6 ),
		( map { [ year  => $_, $_ * 365.25 * DAY ] } 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000 ),
	);

	field $utc :param :reader = 0;
	field $interval :param :reader;    # [ unit, count ]

	method kind () { return 'time' }

	method position ($value) {
		my ( $low, $high ) = ( $self->min, $self->max );
		return ( $value - $low ) / ( $high - $low );
	}

	method value_at ($position) {
		return $self->min + $position * ( $self->max - $self->min );
	}

	method fit :common (%options) {
		my $cells = $options{cells} // croak "$class: fit needs cells";
		croak "$class: cells must be a positive integer, got $cells" unless $cells =~ /\A[1-9][0-9]*\z/;
		my ( $fixed_low, $fixed_high ) = @options{qw(min max)};
		croak "$class: min ($fixed_low) must be before max ($fixed_high)" if defined $fixed_low && defined $fixed_high && $fixed_low >= $fixed_high;
		my $utc      = $options{utc} ? 1 : 0;
		my $measure  = $options{measure} // sub ($label) { length $label };
		my $vertical = ( $options{orientation} // 'horizontal' ) eq 'vertical';

		my ( $low, $high ) = $options{extent} ? $options{extent}->@* : ( 0, DAY );
		$low  = $fixed_low if defined $fixed_low;
		$high = $fixed_high if defined $fixed_high;
		if ( $high <= $low ) {
			( $low, $high )
				= defined $fixed_low  ? ( $low, $low + HOUR )
				: defined $fixed_high ? ( $high - HOUR, $high )
				:                       ( $low - HOUR / 2, $high + HOUR / 2 );
		}

		my $chosen;
		foreach my $interval (@INTERVALS) {
			my ( $unit, $count, $seconds ) = @$interval;
			next if ( $high - $low ) / $seconds > 500;    # far too many ticks
			my @values = _ticks( $low, $high, $unit, $count, $utc ) or next;
			my $format = defined $options{format} ? time_formatter( $options{format}, $utc ) : sub ($epoch) { _auto_label( $epoch, $unit, $utc ) };
			my @labels = map { $format->($_) } @values;
			my $widest = List::Util::max( map { $measure->($_) } @labels );
			my $apart  = ( $cells - 1 ) * $seconds / ( $high - $low );
			my $room   = $vertical ? 2 : List::Util::max( $widest + 3, 8 );
			$chosen = { unit => $unit, count => $count, values => \@values, labels => \@labels };
			last if $apart >= $room && ( @values >= 2 || $apart > $cells );
		}
		croak "$class: no tick interval fits the range $low .. $high" unless $chosen;

		my @ticks = map { { value => $chosen->{values}[$_], label => $chosen->{labels}[$_] } } 0 .. $chosen->{values}->$#*;
		return $class->new( min => $low, max => $high, cells => $cells, used => $cells, utc => $utc, interval => [ @$chosen{qw(unit count)} ], ticks => \@ticks );
	}

	# ---------------------------------------------------------------------
	# Calendar arithmetic
	# ---------------------------------------------------------------------

	sub _parts ( $epoch, $utc ) {
		my @parts = $utc ? gmtime $epoch : localtime $epoch;
		return @parts[ 0 .. 6 ];    # sec min hour mday mon year wday
	}

	sub _epoch ( $utc, $sec, $min, $hour, $mday, $mon, $year ) {
		return ( $utc ? \&timegm_posix : \&timelocal_posix )->( $sec, $min, $hour, $mday, $mon, $year );
	}

	# The calendar date $days after (y, m, d), counted at noon UTC so no
	# clock change gets in the way.
	sub _add_days ( $mday, $mon, $year, $days ) {
		my @date = gmtime( timegm_posix( 0, 0, 12, $mday, $mon, $year ) + $days * DAY );
		return @date[ 3, 4, 5 ];
	}

	# The boundary of $unit (a multiple of $count) at or before $epoch.
	sub _floor ( $epoch, $unit, $count, $utc ) {
		my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = _parts( $epoch, $utc );
		return _epoch( $utc, floor( $sec / $count ) * $count, $min,                            $hour,                            $mday,         $mon, $year ) if $unit eq 'second';
		return _epoch( $utc, 0,                               floor( $min / $count ) * $count, $hour,                            $mday,         $mon, $year ) if $unit eq 'minute';
		return _epoch( $utc, 0,                               0,                               floor( $hour / $count ) * $count, $mday,         $mon, $year ) if $unit eq 'hour';
		return _epoch( $utc, 0,                               0,                               0, 1 + floor( ( $mday - 1 ) / $count ) * $count, $mon, $year ) if $unit eq 'day';
		return _epoch( $utc, 0,                               0,                               0, _add_days( $mday, $mon, $year, -( ( $wday + 6 ) % 7 ) ) ) if $unit eq 'week';
		return _epoch( $utc, 0,                               0,                               0, 1, floor( $mon / $count ) * $count, $year ) if $unit eq 'month';
		return _epoch( $utc, 0,                               0,                               0, 1, 0,                               floor( ( $year + 1900 ) / $count ) * $count - 1900 );
	}

	# The next boundary after the boundary $epoch.
	sub _next ( $epoch, $unit, $count, $utc ) {
		my ( $sec, $min, $hour, $mday, $mon, $year ) = _parts( $epoch, $utc );
		if ( $unit eq 'second' || $unit eq 'minute' || $unit eq 'hour' ) {
			my $step = $count * ( $unit eq 'second' ? 1 : $unit eq 'minute' ? MINUTE : HOUR );

			# Across a clock change the next boundary is a little nearer or
			# farther; floor finds it.
			my $next = _floor( $epoch + $step + ( $unit eq 'hour' ? HOUR / 2 : 0 ), $unit, $count, $utc );
			return $next > $epoch ? $next : _floor( $epoch + 2 * $step, $unit, $count, $utc );
		}
		if ( $unit eq 'day' ) {
			my ( $next_mday, $next_mon, $next_year ) = _add_days( $mday, $mon, $year, $count );
			( $next_mday, $next_mon, $next_year ) = ( 1, $next_mon, $next_year ) if $next_mon != $mon && $count > 1;
			return _epoch( $utc, 0, 0, 0, $next_mday, $next_mon, $next_year );
		}
		return _epoch( $utc, 0, 0, 0, _add_days( $mday, $mon, $year, 7 ) ) if $unit eq 'week';
		if ( $unit eq 'month' ) {
			my $month = $mon + $count;
			return _epoch( $utc, 0, 0, 0, 1, $month % 12, $year + floor( $month / 12 ) );
		}
		return _epoch( $utc, 0, 0, 0, 1, 0, $year + $count );
	}

	sub _ticks ( $low, $high, $unit, $count, $utc ) {
		my @values;
		my $tick = _floor( $low, $unit, $count, $utc );
		$tick = _next( $tick, $unit, $count, $utc ) if $tick < $low;
		while ( $tick <= $high ) {
			push @values, $tick;
			$tick = _next( $tick, $unit, $count, $utc );
		}
		return @values;
	}

	# Each tick shows the largest calendar unit it starts that the
	# interval cares about: the year on January 1, the month on the first
	# of a month (or the day, when the ticks are days), the date at
	# midnight (between hours), else the time.
	sub _auto_label ( $epoch, $unit, $utc ) {
		my @parts = $utc ? gmtime $epoch : localtime $epoch;
		my ( $sec, $min, $hour, $mday, $mon ) = @parts;
		my $day_label = sub () { strftime( '%b ', @parts ) . $mday };
		return strftime( '%Y', @parts ) if $unit eq 'year' || ( !$sec && !$min && !$hour && $mday == 1 && !$mon && $unit ne 'second' );
		return strftime( '%b', @parts ) if $unit eq 'month';
		return $day_label->() if $unit eq 'day'       || $unit eq 'week';
		return strftime( '%H:%M:%S', @parts ) if $sec || $unit eq 'second';
		return $day_label->() if !$min && !$hour;
		return strftime( '%H:%M', @parts );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Scale::Time - A date and time axis

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Scale::Time;

	# Two days of data on an axis 60 columns wide, in UTC:
	my $scale = Term::Fabulous::Chart::Scale::Time->fit(
		extent => [ 1780272000, 1780444800 ],
		cells  => 60,
		utc    => 1,
	);
	say join ', ', map { $_->{label} } $scale->ticks;    # Jun 1, 12:00, Jun 2, 12:00, Jun 3

=head1 DESCRIPTION

A L<Term::Fabulous::Chart::Scale> for points in time, given as epoch
seconds. The domain is the data's first and last moment (or the C<min>
and C<max> of the axis). The ticks fall on calendar boundaries: every 1,
2, 5, 10, 15 or 30 seconds or minutes; every 1, 2, 3, 6 or 12 hours;
every day or second day; every week (on Mondays); every 1, 2, 3 or 6
months; every 1, 2, 5, 10, ... years. The finest interval whose labels
have room is chosen.

Without a C<format>, the labels follow the interval: years (C<2026>),
months (C<Feb>, and the year in January), days (C<Jun 3>), hours and
minutes (C<06:00>, and the date at midnight) or seconds (C<06:00:15>).
So an axis of hours shows on which day each night begins. A C<format> (a
L<POSIX/strftime> format or a code reference) labels every tick the same
way.

Times are local unless C<utc> is true. Ticks at local boundaries stay on
them across changes of daylight saving time.

=head1 CLASS METHODS

=head2 fit

	my $scale = Term::Fabulous::Chart::Scale::Time->fit(%options);

Takes C<cells>, C<extent>, C<min>, C<max>, C<orientation> (default
C<horizontal>), C<measure> and C<format> (a L<POSIX/strftime> format or
a code reference called with the epoch seconds) like
L<Term::Fabulous::Chart::Scale::Linear/fit>, the values in epoch
seconds, and C<utc>. C<min> must be before C<max>.

=head1 METHODS

Those of L<Term::Fabulous::Chart::Scale>, and C<utc> and C<interval>,
the tick interval as C<[ $unit, $count ]> (C<[ 'hour', 6 ]>).

=head1 SEE ALSO

L<Term::Fabulous::Chart::Scale>, L<Term::Fabulous::Widget::XYChart/Time axes>.

=cut
