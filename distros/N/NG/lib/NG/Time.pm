package Time;
use strict;
use warnings;
use Time::HiRes ();
use POSIX       ();
use base 'Object';

sub new {
    my $pkg = shift;
    return bless {@_}, ref($pkg) || $pkg;
}

sub now {
    my @t = localtime;
    shift->new(
        year   => $t[5] + 1900,
        month  => $t[4] + 1,
        day    => $t[3],
        hour   => $t[2],
        minute => $t[1],
        second => $t[0],
    );
}

=head2 year
The C<year> accessor returns the 4-digit year for the date.
=cut

sub year {
    defined $_[0]->{year} ? $_[0]->{year} : 1970;
}

=head2 month
The C<month> accessor returns the 1-12 month of the year for the date.
=cut

sub month {
    $_[0]->{month} || 1;
}

=head2 day
The C<day> accessor returns the 1-31 day of the month for the date.
=cut

sub day {
    $_[0]->{day} || 1;
}

=head2 hour
The C<hour> accessor returns the hour component of the time as
an integer from zero to twenty-three (0-23) in line with 24-hour
time.
=cut

sub hour {
    $_[0]->{hour} || 0;
}

=head2 minute
The C<minute> accessor returns the minute component of the time
as an integer from zero to fifty-nine (0-59).
=cut

sub minute {
    $_[0]->{minute} || 0;
}

=head2 second
The C<second> accessor returns the second component of the time
as an integer from zero to fifty-nine (0-59).
=cut

sub second {
    $_[0]->{second} || 0;
}

sub microsecond {
    $_[0]->{second} || +(Time::HiRes::gettimeofday)[1];
}

sub strftime {
    my $self   = shift;
    my $format = shift;
    my @need_t;
    if ( ref( $_[0] ) eq 'Time' ) {
        @need_t = localtime( shift->to_epoch );
    }
    else {
        @need_t = @_;
    }
    POSIX::strftime( $format, @need_t );
}

sub to_epoch {
    my $self = shift;
    POSIX::mktime(
        $self->second, $self->minute, $self->hour, $self->day,
        $self->month - 1,
        $self->year - 1900
    );
}

sub from_epoch {
    my $self = shift;
    my @t    = localtime(shift);
    $self->new(
        year   => $t[5] + 1900,
        month  => $t[4] + 1,
        day    => $t[3],
        hour   => $t[2],
        minute => $t[1],
        second => $t[0],
    );
}

sub to_float {
    return Time::HiRes::time;
}
1;
