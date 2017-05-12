package Pinwheel::Model::DateBase;

use strict;
use warnings;

use POSIX qw();


# Date/time values

sub year { $_[0]->{t}[5] + 1900 }
sub month { $_[0]->{t}[4] + 1 }
sub day { $_[0]->{t}[3] }
sub mm { sprintf('%02d', $_[0]->{t}[4] + 1) }
sub dd { sprintf('%02d', $_[0]->{t}[3]) }
sub wday { $_[0]->{t}[6] }
sub yday { $_[0]->{t}[7] }

sub bbc_year
{
    $_[0]->_calculate_bbc_week if (!$_[0]->{bbc_week});
    return $_[0]->{bbc_year};
}

sub bbc_week
{
    $_[0]->_calculate_bbc_week if (!$_[0]->{bbc_week});
    return $_[0]->{bbc_week};
}

sub _calculate_bbc_week
{
    my $adjust = 3 - (($_[0]->{t}[6] + 1) % 7);
    my @t = gmtime($_[0]->{s} + ($adjust * 86400));
    $_[0]->{bbc_year} = $t[5] + 1900;
    $_[0]->{bbc_week} = int($t[7] / 7) + 1;
}

sub iso_year
{
    $_[0]->_calculate_iso_week if (!$_[0]->{iso_week});
    return $_[0]->{iso_year};
}

sub iso_week
{
    $_[0]->_calculate_iso_week if (!$_[0]->{iso_week});
    return $_[0]->{iso_week};
}

sub iso_weekday
{
    return $_[0]->{t}[6] || 7;
}

sub _calculate_iso_week
{
    my $adjust = 3 - (($_[0]->{t}[6] - 1) % 7);
    my @t = gmtime($_[0]->{s} + ($adjust * 86400));
    $_[0]->{iso_year} = $t[5] + 1900;
    $_[0]->{iso_week} = int($t[7] / 7) + 1;
}

sub days_in_month
{
    my ($y, $m);

    $y = $_[0]->{t}[5] + 1900;
    $m = $_[0]->{t}[4];
    return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m] if ($m != 1);
    return (!($y % 4) && (($y % 100) || !($y % 400))) ? 29 : 28;
}


# Formatting

sub month_name
{
    return qw(
        January February March April May June July
        August September October November December
    )[$_[0]->{t}[4]];
}

sub short_month_name
{
    return qw(
        Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
    )[$_[0]->{t}[4]];
}

sub day_name
{
    return qw(
        Sunday Monday Tuesday Wednesday Thursday Friday Saturday
    )[$_[0]->{t}[6]];
}

sub short_day_name
{
    return qw(Sun Mon Tue Wed Thu Fri Sat)[$_[0]->{t}[6]];
}

sub day_suffix
{
    my $day = $_[0]->{t}[3];
    return 'th' if ($day >= 10 && $day < 20);
    return qw(th st nd rd th th th th th th)[$day % 10];
}

sub day_ordinal
{
    return $_[0]->day . $_[0]->day_suffix;
}

sub strftime
{
    return POSIX::strftime($_[1], @{$_[0]->{t}});
}


# Date/time adjustment

sub replace
{
    my ($self, %values) = @_;
    my ($ss, $mm, $hh, $d, $m, $y) = @{$self->{t}};

    $ss = $values{sec} if exists($values{sec});
    $ss = 0 if $ss < 0; $ss = 59 if $ss > 59;
    $mm = $values{min} if exists($values{min});
    $mm = 0 if $mm < 0; $mm = 59 if $mm > 59;
    $hh = $values{hour} if exists($values{hour});
    $hh = 0 if $hh < 0; $hh = 23 if $hh > 23;

    $d = $values{day} if exists($values{day});
    $m = $values{month} - 1 if exists($values{month});
    $m = 0 if $m < 0; $m = 11 if $m > 11;
    $y = exists($values{year}) ? $values{year} : $y + 1900;
    $d = _correct_day($y, $m, $d);

    return $self->_derived($y, $m, $d, $hh, $mm, $ss);
}

sub offset
{
    my ($self, %deltas) = @_;
    my ($i, $ss, $mm, $hh, $d, $m, $y) = (undef, @{$self->{t}});

    if (exists($deltas{days})) {
        $i = $self->{s} + ((12 - $hh) * 3600) + ($deltas{days} * 86400);
        ($d, $m, $y) = (gmtime $i)[3 .. 5];
    }
    if (exists($deltas{months})) {
        $i = $m + $deltas{months};
        $m = $i % 12;
        $y += ($i - $m) / 12;
    }
    $y += 1900;
    $y += $deltas{years} if exists($deltas{years});
    $d = _correct_day($y, $m, $d);
    return $self->_derived($y, $m, $d, $hh, $mm, $ss);
}

sub next_day
{
    return $_[0]->offset(days => 1);
}

sub previous_day
{
    return $_[0]->offset(days => -1);
}

sub next_week
{
    return $_[0]->offset(days => 7);
}

sub previous_week
{
    return $_[0]->offset(days => -7);
}

sub next_month
{
    return $_[0]->offset(months => 1);
}

sub previous_month
{
    return $_[0]->offset(months => -1);
}

sub last_of_month
{
    return $_[0]->replace(day => 31);
}

sub first_of_month
{
    return $_[0]->replace(day => 1);
}

sub _correct_day
{
    my ($y, $m, $d) = @_;
    my $i;

    return 1 if $d < 1;

    $i = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m];
    if ($d > $i) {
        # XXX No year divisible by 100 and not 400 with a 32-bit time_t
        $i++ if ($m == 1 && !($y % 4) && (($y % 100) || !($y % 400)));
        $d = $i if $d > $i;
    }
    return $d;
}


1;

__DATA__

=head1 NAME 

Pinwheel::Model::DateBase - base class for date/time data types

=head1 SYNOPSIS

    # $dt = Pinwheel::Model::Date ....
    # or
    # $dt = Pinwheel::Model::Time ....

    $dt->year;  # e.g. 2008
    $dt->month; # month, 1..12
    $dt->day;   # day of the month, 1..31
    $dt->mm;    # month, "01".."12"
    $dt->dd;    # day of the month, "01".."31"
    $dt->wday;  # day of the week, 0(Sun)..6(Sat)
    $dt->yday;  # day of the year, 0(1 Jan)..365(31 Dec in a leap year)

    $dt->bbc_year;          # ?
    $dt->bbc_week;          # ?

    $dt->iso_year;          # ?
    $dt->iso_week;          # ?
    $dt->iso_weekday;       # day of the week, 1(Mon)..7(Sun)

    $dt->days_in_month;     # number of days in this month
    $dt->month_name;        # "January".."December"
    $dt->short_month_name;  # "Jan".."Dec"

    $dt->day_name;          # "Sunday".."Saturday"
    $dt->short_day_name;    # "Sun".."Sat"
    $dt->day_suffix;        # one of: "st" "nd" "rd" "th"
    $dt->day_ordinal;       # e.g. "1st", "2nd", ... "31st"

    $dt->strftime($format); # see "man strftime"


    # $dt->replace returns a new object (of the same type as $dt)
    # by replacing parts of $dt according to %values.  Allowed keys in %values
    # are: sec min hour day month year.
    # TODO: document validation, range checking, etc.

    $new_dt = $dt->replace(%values);

    $dt->last_of_month;  # $dt->replace(day => 31)
    $dt->first_of_month; # $dt->replace(day => 1)


    # $dt->offset returns a new object (of the same type as $dt)
    # by adjusting $dt according to %deltas.  Allowed keys in %deltas are:
    # days, months, years.
    # TODO: document how 'months' works, and what about leap days in 'years'

    $new_dt = $dt->offset(%deltas);

    $dt->next_day;       # $dt->offset(days => +1)
    $dt->previous_day;   # $dt->offset(days => -1)
    $dt->next_week;      # $dt->offset(days => +7)
    $dt->previous_week;  # $dt->offset(days => -7)
    $dt->next_month;     # $dt->offset(months => +1)
    $dt->previous_month; # $dt->offset(months => -1)

=head1 SEE ALSO

L<Pinwheel::Model::Date>, L<Pinwheel::Model::Time>

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut
