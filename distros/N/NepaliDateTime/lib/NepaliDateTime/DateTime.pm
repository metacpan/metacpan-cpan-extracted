package NepaliDateTime::DateTime;

use strict;
use warnings;
use utf8;
use Carp qw(croak);
use POSIX qw(floor);

use parent -norequire, 'NepaliDateTime::Date';
use NepaliDateTime::Data qw();

our $VERSION = '0.02';

=encoding utf8

=head1 NAME

NepaliDateTime::DateTime - Bikram Sambat date + time object

=head1 SYNOPSIS

    use NepaliDateTime::DateTime;

    # Now in Nepal Standard Time
    my $now = NepaliDateTime::DateTime->now();

    # Construct
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);

    # From Unix timestamp
    my $dt2 = NepaliDateTime::DateTime->from_timestamp(time());

    # From AD datetime
    my $dt3 = NepaliDateTime::DateTime->from_ad_datetime(2024, 7, 15, 9, 0, 0);

    # Accessors
    printf "%02d:%02d:%02d\n", $dt->hour, $dt->minute, $dt->second;
    print  $dt->microsecond, "\n";

    # Formatting
    print $dt->isoformat(), "\n";              # 2081-03-15T14:30:00+05:45
    print $dt->strftime('%Y-%m-%d %H:%M:%S');
    print $dt->strftime_np('%K-%n-%D %h:%l:%s');  # all Devanagari

    # Arithmetic
    my $dt4 = $dt->add_seconds(3600);
    my $dt5 = $dt->add_minutes(90);
    my $dt6 = $dt + 1;   # add 1 day

    # Conversion
    my ($y,$m,$d,$H,$M,$S) = $dt->to_ad_datetime();
    my $epoch = $dt->to_timestamp();

    # Date part
    my $date = $dt->date();

=head1 DESCRIPTION

NepaliDateTime::DateTime extends L<NepaliDateTime::Date> with time
components (hour, minute, second, microsecond) and Nepal Standard Time
(UTC+05:45) awareness.

=cut

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head1 CONSTRUCTOR

=head2 new($year, $month, $day, $hour=0, $minute=0, $second=0, $microsecond=0)

Creates a new BS datetime.  Time defaults to midnight.

=cut

sub new {
    my ($class, $year, $month, $day, $hour, $minute, $second, $microsecond) = @_;
    $hour        //= 0;
    $minute      //= 0;
    $second      //= 0;
    $microsecond //= 0;
    _check_time_fields($hour, $minute, $second, $microsecond);
    my $self = $class->SUPER::new($year, $month, $day);
    $self->{hour}        = $hour;
    $self->{minute}      = $minute;
    $self->{second}      = $second;
    $self->{microsecond} = $microsecond;
    return $self;
}

sub _check_time_fields {
    my ($h, $m, $s, $us) = @_;
    croak "hour must be 0..23, got $h"            unless $h  >= 0 && $h  <= 23;
    croak "minute must be 0..59, got $m"          unless $m  >= 0 && $m  <= 59;
    croak "second must be 0..59, got $s"          unless $s  >= 0 && $s  <= 59;
    croak "microsecond must be 0..999999, got $us" unless $us >= 0 && $us <= 999999;
}

# ---------------------------------------------------------------------------
# Class methods
# ---------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 now()

Returns the current Nepal Standard Time as a NepaliDateTime::DateTime.

=cut

sub now {
    my ($class) = @_;
    return $class->from_timestamp(time());
}

=head2 utcnow()

Returns the current UTC time as a NepaliDateTime::DateTime (with UTC date
converted to BS, time kept as UTC).

=cut

sub utcnow {
    my ($class) = @_;
    my @gm = gmtime(time());
    my $bs_date = NepaliDateTime::Date->from_ad($gm[5]+1900, $gm[4]+1, $gm[3]);
    return $class->new($bs_date->year, $bs_date->month, $bs_date->day,
                       $gm[2], $gm[1], $gm[0], 0);
}

=head2 from_timestamp($epoch, %opts)

Construct from a Unix timestamp. Converts to Nepal Standard Time by default.

    my $dt = NepaliDateTime::DateTime->from_timestamp(time());

Options:
    utc => 1    Treat as UTC (do not add Nepal offset)

=cut

sub from_timestamp {
    my ($class, $epoch, %opts) = @_;
    my $offset = $opts{utc} ? 0 : $NepaliDateTime::Data::NEPAL_UTC_OFFSET;
    my $t = $epoch + $offset;
    my @gm = gmtime($t);
    my ($ad_y, $ad_m, $ad_d) = ($gm[5]+1900, $gm[4]+1, $gm[3]);
    my ($h, $min, $s)        = ($gm[2], $gm[1], $gm[0]);
    # microseconds from fractional part
    my $us = int(($epoch - int($epoch)) * 1_000_000);
    $us = 0 if $us < 0;
    my $bs_date = NepaliDateTime::Date->from_ad($ad_y, $ad_m, $ad_d);
    return $class->new($bs_date->year, $bs_date->month, $bs_date->day, $h, $min, $s, $us);
}

=head2 from_ad_datetime($year, $month, $day, $hour=0, $minute=0, $second=0, $microsecond=0)

Convert an AD datetime to a BS NepaliDateTime::DateTime.

    my $dt = NepaliDateTime::DateTime->from_ad_datetime(2024, 7, 15, 14, 30, 0);

=cut

sub from_ad_datetime {
    my ($class, $y, $m, $d, $h, $min, $s, $us) = @_;
    $h   //= 0; $min //= 0; $s //= 0; $us //= 0;
    my $bs = NepaliDateTime::Date->from_ad($y, $m, $d);
    return $class->new($bs->year, $bs->month, $bs->day, $h, $min, $s, $us);
}

=head2 combine($date, $hour, $minute, $second, $microsecond)

Combine a NepaliDateTime::Date with time components.

=cut

sub combine {
    my ($class, $date, $hour, $min, $sec, $us) = @_;
    croak "date must be a NepaliDateTime::Date" unless ref $date && $date->isa('NepaliDateTime::Date');
    return $class->new($date->year, $date->month, $date->day,
                       $hour//0, $min//0, $sec//0, $us//0);
}

=head2 strptime($string, $format)

Parse a BS datetime string.

    my $dt = NepaliDateTime::DateTime->strptime('2081-03-15 14:30:00', '%Y-%m-%d %H:%M:%S');

=cut

sub strptime {
    my ($class, $str, $fmt) = @_;
    my %p = NepaliDateTime::Date::_do_strptime($str, $fmt);
    my $y  = $p{Y} // croak "strptime: year not found";
    my $m  = $p{m} // croak "strptime: month not found";
    my $d  = $p{d} // croak "strptime: day not found";
    my $h  = $p{H} // 0;
    my $mi = $p{M2} // 0;
    my $s  = $p{S} // 0;
    my $us = 0;
    if (defined $p{f}) {
        my $fs = $p{f};
        $fs .= '0' x (6 - length($fs));
        $us = $fs + 0;
    }
    return $class->new($y, $m, $d, $h, $mi, $s, $us);
}

=head2 min()

Minimum supported datetime (BS 1975-01-01 00:00:00).

=cut

sub min { NepaliDateTime::DateTime->new($NepaliDateTime::Data::MINYEAR, 1, 1, 0, 0, 0, 0) }

=head2 max()

Maximum supported datetime (BS 2100-12-30 23:59:59.999999).

=cut

sub max {
    my $y   = $NepaliDateTime::Data::MAXYEAR;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$y}[12];
    NepaliDateTime::DateTime->new($y, 12, $dim, 23, 59, 59, 999999);
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

=head1 ACCESSORS

=head2 hour() / minute() / second() / microsecond()

=cut

sub hour        { $_[0]{hour}        }
sub minute      { $_[0]{minute}      }
sub second      { $_[0]{second}      }
sub microsecond { $_[0]{microsecond} }

=head2 date()

Returns the date part as a NepaliDateTime::Date object.

=cut

sub date {
    my ($self) = @_;
    return NepaliDateTime::Date->new($self->{year}, $self->{month}, $self->{day});
}

=head2 time_string()

Returns the time as C<"HH:MM:SS"> or C<"HH:MM:SS.ffffff"> if microseconds
are non-zero.

=cut

sub time_string {
    my ($self) = @_;
    my $s = sprintf('%02d:%02d:%02d', $self->{hour}, $self->{minute}, $self->{second});
    $s .= sprintf('.%06d', $self->{microsecond}) if $self->{microsecond};
    return $s;
}

# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

=head1 CONVERSION

=head2 to_ad_datetime()

Returns C<($year, $month, $day, $hour, $minute, $second, $microsecond)> in
Gregorian (AD) calendar.

=cut

sub to_ad_datetime {
    my ($self) = @_;
    my ($y, $m, $d) = $self->to_ad();
    return ($y, $m, $d, $self->{hour}, $self->{minute}, $self->{second}, $self->{microsecond});
}

=head2 to_timestamp()

Returns the Unix timestamp (seconds since 1970-01-01 00:00:00 UTC) as a float.
Uses Nepal Standard Time (UTC+05:45).

=cut

sub to_timestamp {
    my ($self) = @_;
    my ($y, $m, $d) = $self->to_ad();
    # Days since Unix epoch
    my $unix_jdn = NepaliDateTime::Date::_ad_to_jdn(1970, 1, 1);
    my $this_jdn = NepaliDateTime::Date::_ad_to_jdn($y, $m, $d);
    my $days     = $this_jdn - $unix_jdn;
    my $secs     = $days * 86400
                 + $self->{hour}   * 3600
                 + $self->{minute} * 60
                 + $self->{second}
                 - $NepaliDateTime::Data::NEPAL_UTC_OFFSET;
    return $secs + $self->{microsecond} / 1_000_000;
}

=head2 utcoffset_string()

Returns the UTC offset string, e.g. C<"+05:45">.

=cut

sub utcoffset_string { '+05:45' }

=head2 tzname()

Returns C<"NST"> (Nepal Standard Time).

=cut

sub tzname { 'NST' }

# ---------------------------------------------------------------------------
# Arithmetic
# ---------------------------------------------------------------------------

=head1 ARITHMETIC

All add_* methods return a new NepaliDateTime::DateTime.

=head2 add_seconds($n)

=cut

sub add_seconds {
    my ($self, $n) = @_;
    my $total = $self->{second} + $n;
    my $carry_min = floor($total / 60);
    my $new_sec   = $total - $carry_min * 60;
    $new_sec = int($new_sec);

    my $total_min = $self->{minute} + $carry_min;
    my $carry_hr  = floor($total_min / 60);
    my $new_min   = $total_min - $carry_hr * 60;
    $new_min = int($new_min);

    my $total_hr  = $self->{hour} + $carry_hr;
    my $carry_day = floor($total_hr / 24);
    my $new_hr    = $total_hr - $carry_day * 24;
    $new_hr = int($new_hr);

    my $new_date = $self->date()->add_days($carry_day);
    return NepaliDateTime::DateTime->new(
        $new_date->year, $new_date->month, $new_date->day,
        $new_hr, $new_min, $new_sec, $self->{microsecond}
    );
}

=head2 add_minutes($n)

=cut

sub add_minutes { $_[0]->add_seconds($_[1] * 60) }

=head2 add_hours($n)

=cut

sub add_hours { $_[0]->add_seconds($_[1] * 3600) }

=head2 add_days($n)

=cut

sub add_days {
    my ($self, $n) = @_;
    my $new_date = $self->date()->add_days($n);
    return NepaliDateTime::DateTime->new(
        $new_date->year, $new_date->month, $new_date->day,
        $self->{hour}, $self->{minute}, $self->{second}, $self->{microsecond}
    );
}

=head2 replace(%fields)

Returns a copy with specified fields replaced. Valid keys:
C<year>, C<month>, C<day>, C<hour>, C<minute>, C<second>, C<microsecond>.

=cut

sub replace {
    my ($self, %args) = @_;
    return NepaliDateTime::DateTime->new(
        $args{year}        // $self->{year},
        $args{month}       // $self->{month},
        $args{day}         // $self->{day},
        $args{hour}        // $self->{hour},
        $args{minute}      // $self->{minute},
        $args{second}      // $self->{second},
        $args{microsecond} // $self->{microsecond},
    );
}

# ---------------------------------------------------------------------------
# Operators
# ---------------------------------------------------------------------------

use overload
    '+'   => \&_op_add,
    '-'   => \&_op_sub,
    '=='  => \&_op_eq,
    '!='  => \&_op_ne,
    '<'   => \&_op_lt,
    '<='  => \&_op_le,
    '>'   => \&_op_gt,
    '>='  => \&_op_ge,
    '<=>' => \&_op_cmp,
    '""'  => \&isoformat,
    fallback => 1;

sub _total_secs {
    my ($self) = @_;
    return $self->toordinal() * 86400
         + $self->{hour}   * 3600
         + $self->{minute} * 60
         + $self->{second};
}

sub _op_add {
    my ($self, $other, $swap) = @_;
    return $self->add_days($other) unless ref $other;
    croak "unsupported operand for +";
}

sub _op_sub {
    my ($self, $other, $swap) = @_;
    if (ref $other && $other->isa('NepaliDateTime::DateTime')) {
        my $diff = ($self->_total_secs - $other->_total_secs)
                 + ($self->{microsecond} - $other->{microsecond}) / 1_000_000;
        return $swap ? -$diff : $diff;
    }
    if (ref $other && $other->isa('NepaliDateTime::Date')) {
        # subtract days
        return $self->add_days(-$other->toordinal()) if $swap;
        croak "cannot subtract a datetime from a plain date";
    }
    # integer days
    croak "unsupported operand for -" if ref $other;
    return $self->add_days($swap ? $other : -$other);
}

sub _cmp_key { ($_[0]->_total_secs, $_[0]{microsecond}) }
sub _op_eq  { my @a = $_[0]->_cmp_key; my @b = $_[1]->_cmp_key; $a[0]==$b[0] && $a[1]==$b[1] }
sub _op_ne  { !_op_eq(@_) }
sub _op_lt  { my @a = $_[0]->_cmp_key; my @b = $_[1]->_cmp_key; $a[0]<$b[0] || ($a[0]==$b[0] && $a[1]<$b[1]) }
sub _op_le  { $_[0] == $_[1] || $_[0] < $_[1] }
sub _op_gt  { !$_[0]->_op_le($_[1]) }
sub _op_ge  { !$_[0]->_op_lt($_[1]) }
sub _op_cmp {
    my @a = $_[0]->_cmp_key; my @b = $_[1]->_cmp_key;
    $a[0] <=> $b[0] || $a[1] <=> $b[1];
}

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

=head1 FORMATTING

=head2 isoformat($sep)

Returns ISO-8601 string: C<"YYYY-MM-DDThh:mm:ss+05:45"> (or with microseconds
if non-zero).  C<$sep> defaults to C<'T'>.

=cut

sub isoformat {
    my ($self, $sep) = @_;
    $sep //= 'T';
    my $dt = sprintf('%04d-%02d-%02d%s%02d:%02d:%02d',
        $self->{year}, $self->{month}, $self->{day},
        $sep,
        $self->{hour}, $self->{minute}, $self->{second});
    $dt .= sprintf('.%06d', $self->{microsecond}) if $self->{microsecond};
    $dt .= '+05:45';
    return $dt;
}

=head2 strftime($format)

Same directives as L<NepaliDateTime::Date/strftime>, with time directives
(C<%H>, C<%M>, C<%S>, C<%f>, C<%I>, C<%p>) filled with the actual time.

=cut

sub strftime {
    my ($self, $fmt) = @_;
    return NepaliDateTime::Date::_do_strftime($self, $fmt);
}

=head2 strftime_np($format)

Convenience alias: same as C<strftime> but reminds callers to use Devanagari
format codes (C<%K>, C<%n>, C<%D>, C<%h>, C<%l>, C<%s>).

=cut

sub strftime_np { goto &strftime }

=head2 ctime()

Returns ctime-style string: C<"Wed Asa 15 14:30:00 2081">.

=cut

sub ctime {
    my ($self) = @_;
    return sprintf('%s %s %2d %02d:%02d:%02d %04d',
        $NepaliDateTime::Data::WDAY_ABBR[$self->weekday()],
        $NepaliDateTime::Data::MONTH_ABBR[$self->{month}],
        $self->{day},
        $self->{hour}, $self->{minute}, $self->{second},
        $self->{year},
    );
}

=head2 format_devanagari()

Full Devanagari datetime string.

=cut

sub format_devanagari {
    my ($self) = @_;
    my $date_part = $self->NepaliDateTime::Date::format_devanagari();
    my $h  = NepaliDateTime::Date::_to_np(sprintf('%02d', $self->{hour}));
    my $m  = NepaliDateTime::Date::_to_np(sprintf('%02d', $self->{minute}));
    my $s  = NepaliDateTime::Date::_to_np(sprintf('%02d', $self->{second}));
    return "$date_part $h:$m:$s";
}

=head2 clone()

Returns a copy of this datetime object.

=cut

sub clone {
    my ($self) = @_;
    return NepaliDateTime::DateTime->new(
        $self->{year}, $self->{month}, $self->{day},
        $self->{hour}, $self->{minute}, $self->{second}, $self->{microsecond}
    );
}

1;

=head1 SEE ALSO

L<NepaliDateTime::Date>

=cut
