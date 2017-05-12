#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 330;

use Pinwheel::Model::Time;


# Constructor
{
    my $t;

    $t = Pinwheel::Model::Time->new();
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time->new(1000000000);
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time->new(1000000000, 0);
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time->new(1000000000, 1);
    is(ref($t), 'Pinwheel::Model::Time');

    $t = Pinwheel::Model::Time::now();
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time::now(0);
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time::now(1);
    is(ref($t), 'Pinwheel::Model::Time');

    $t = Pinwheel::Model::Time::now_0seconds();
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time::now_0seconds(0);
    is(ref($t), 'Pinwheel::Model::Time');
    $t = Pinwheel::Model::Time::now_0seconds(1);
    is(ref($t), 'Pinwheel::Model::Time');

    $t = Pinwheel::Model::Time::utc(2007);
    is(ref($t), 'Pinwheel::Model::Time');
    is($t->timestamp, 1167609600);
    $t = Pinwheel::Model::Time::utc(2007, 1, 1);
    is(ref($t), 'Pinwheel::Model::Time');
    is($t->timestamp, 1167609600);
    $t = Pinwheel::Model::Time::local(2007, 1, 1);
    is(ref($t), 'Pinwheel::Model::Time');
    is($t->timestamp, 1167609600);
    $t = Pinwheel::Model::Time::local(2007, 1, 1, 12, 30, 45);
    is(ref($t), 'Pinwheel::Model::Time');
    is($t->timestamp, 1167654645);
}

# UTC/localtime switching
{
    my ($t1, $t2);

    $t1 = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    $t2 = Pinwheel::Model::Time::utc(2007, 6, 1, 11, 30, 45);
    is($t1->timestamp, $t2->timestamp);

    $t1 = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    $t2 = $t1->getutc();
    is($t1->timestamp, $t2->timestamp);
    $t1 = $t1->getutc();
    is($t1, $t2);

    $t1 = Pinwheel::Model::Time::utc(2007, 6, 1, 23, 30, 45);
    $t2 = $t1->getlocal();
    is($t1->timestamp, $t2->timestamp);
    is($t2->iso8601, '2007-06-02T00:30:45+01:00');
    $t1 = $t1->getlocal();
    is($t1, $t2);

    $t1 = Pinwheel::Model::Time::utc(2007, 1, 1, 12, 30, 45);
    $t2 = $t1->getutc();
    is($t1, $t2);
    $t1 = Pinwheel::Model::Time::local(2007, 1, 1, 12, 30, 45);
    $t2 = $t1->getlocal();
    is($t1, $t2);

    $t1 = Pinwheel::Model::Time::local(2007, 1, 1, 12, 30, 45);
    is($t1, $t1->getutc()->getlocal());
    $t1 = Pinwheel::Model::Time::utc(2007, 1, 1, 12, 30, 45);
    is($t1, $t1->getlocal()->getutc());
}

# Time/date attributes
{
    my $t;

    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    is($t->year, 2007);
    is($t->month, 6);
    is($t->day, 1);
    is($t->wday, 5);
    is($t->yday, 151);
    is($t->hour, 12);
    is($t->min, 30);
    is($t->sec, 45);

    $t = $t->getutc();
    is($t->year, 2007);
    is($t->month, 6);
    is($t->day, 1);
    is($t->wday, 5);
    is($t->yday, 151);
    is($t->hour, 11);
    is($t->min, 30);
    is($t->sec, 45);
}

# Timestamps
{
    my $t;

    $t = Pinwheel::Model::Time::utc(1970, 1, 1, 0, 0, 0);
    is($t->timestamp, 0);
    $t = Pinwheel::Model::Time::local(2009, 2, 13, 23, 31, 30);
    is($t->timestamp, 1234567890);
}

# BBC calendar
{
    my ($fn, $t);

    $fn = sub {
        my $t = Pinwheel::Model::Time::utc(@_);
        return [$t->bbc_year, $t->bbc_week];
    };

    is_deeply(&$fn(2007,  1,  6), [2007,  2]);
    is_deeply(&$fn(2007,  1,  5), [2007,  1]);
    is_deeply(&$fn(2006, 12, 30), [2007,  1]);
    is_deeply(&$fn(2006, 12, 29), [2006, 52]);

    is_deeply(&$fn(2006,  1,  7), [2006,  2]);
    is_deeply(&$fn(2006,  1,  6), [2006,  1]);
    is_deeply(&$fn(2005, 12, 31), [2006,  1]);
    is_deeply(&$fn(2005, 12, 30), [2005, 52]);

    is_deeply(&$fn(2005,  1,  8), [2005,  2]);
    is_deeply(&$fn(2005,  1,  7), [2005,  1]);
    is_deeply(&$fn(2005,  1,  1), [2005,  1]);
    is_deeply(&$fn(2004, 12, 31), [2004, 52]);

    is_deeply(&$fn(2004,  1, 10), [2004,  2]);
    is_deeply(&$fn(2004,  1,  9), [2004,  1]);
    is_deeply(&$fn(2004,  1,  3), [2004,  1]);
    is_deeply(&$fn(2004,  1,  2), [2003, 52]);

    is_deeply(&$fn(2003,  1, 11), [2003,  2]);
    is_deeply(&$fn(2003,  1, 10), [2003,  1]);
    is_deeply(&$fn(2003,  1,  4), [2003,  1]);
    is_deeply(&$fn(2003,  1,  3), [2002, 53]);

    is_deeply(&$fn(2002,  1,  5), [2002,  2]);
    is_deeply(&$fn(2002,  1,  4), [2002,  1]);
    is_deeply(&$fn(2001, 12, 29), [2002,  1]);
    is_deeply(&$fn(2001, 12, 28), [2001, 52]);

    is_deeply(&$fn(2001,  1,  6), [2001,  2]);
    is_deeply(&$fn(2001,  1,  5), [2001,  1]);
    is_deeply(&$fn(2000, 12, 30), [2001,  1]);
    is_deeply(&$fn(2000, 12, 29), [2000, 52]);

    is_deeply(&$fn(2000,  1,  8), [2000,  2]);
    is_deeply(&$fn(2000,  1,  7), [2000,  1]);
    is_deeply(&$fn(2000,  1,  1), [2000,  1]);
    is_deeply(&$fn(1999, 12, 31), [1999, 52]);

    is_deeply(&$fn(1999,  1,  9), [1999,  2]);
    is_deeply(&$fn(1999,  1,  8), [1999,  1]);
    is_deeply(&$fn(1999,  1,  2), [1999,  1]);
    is_deeply(&$fn(1999,  1,  1), [1998, 52]);

    # Test caching by poking a different epoch value into the object
    $t = Pinwheel::Model::Time::utc(2007, 1, 1);
    is($t->bbc_year, 2007);
    is($t->bbc_week, 1);
    $t->{s} = 0;
    is($t->bbc_year, 2007);
    is($t->bbc_week, 1);
    # Same again, but accessing bbc_week first
    $t = Pinwheel::Model::Time::utc(2007, 1, 1);
    is($t->bbc_week, 1);
    is($t->bbc_year, 2007);
    $t->{s} = 0;
    is($t->bbc_week, 1);
    is($t->bbc_year, 2007);
}

# ISO week date
{
    my ($fn, $d);

    $fn = sub {
        my $d = Pinwheel::Model::Time::utc(@_);
        return [$d->iso_year, $d->iso_week];
    };

    is_deeply(&$fn(2007,  1,  8), [2007,  2]);
    is_deeply(&$fn(2007,  1,  7), [2007,  1]);
    is_deeply(&$fn(2007,  1,  1), [2007,  1]);
    is_deeply(&$fn(2006, 12, 31), [2006, 52]);

    is_deeply(&$fn(2006,  1,  9), [2006,  2]);
    is_deeply(&$fn(2006,  1,  8), [2006,  1]);
    is_deeply(&$fn(2006,  1,  2), [2006,  1]);
    is_deeply(&$fn(2006,  1,  1), [2005, 52]);

    is_deeply(&$fn(2005,  1, 10), [2005,  2]);
    is_deeply(&$fn(2005,  1,  9), [2005,  1]);
    is_deeply(&$fn(2005,  1,  3), [2005,  1]);
    is_deeply(&$fn(2005,  1,  2), [2004, 53]);

    is_deeply(&$fn(2004,  1,  5), [2004,  2]);
    is_deeply(&$fn(2004,  1,  4), [2004,  1]);
    is_deeply(&$fn(2003, 12, 29), [2004,  1]);
    is_deeply(&$fn(2003, 12, 28), [2003, 52]);

    is_deeply(&$fn(2003,  1,  6), [2003,  2]);
    is_deeply(&$fn(2003,  1,  5), [2003,  1]);
    is_deeply(&$fn(2002, 12, 30), [2003,  1]);
    is_deeply(&$fn(2002, 12, 29), [2002, 52]);

    is_deeply(&$fn(2002,  1,  7), [2002,  2]);
    is_deeply(&$fn(2002,  1,  6), [2002,  1]);
    is_deeply(&$fn(2001, 12, 31), [2002,  1]);
    is_deeply(&$fn(2001, 12, 30), [2001, 52]);

    is_deeply(&$fn(2001,  1,  8), [2001,  2]);
    is_deeply(&$fn(2001,  1,  7), [2001,  1]);
    is_deeply(&$fn(2001,  1,  1), [2001,  1]);
    is_deeply(&$fn(2000, 12, 31), [2000, 52]);

    is_deeply(&$fn(2000,  1, 10), [2000,  2]);
    is_deeply(&$fn(2000,  1,  9), [2000,  1]);
    is_deeply(&$fn(2000,  1,  3), [2000,  1]);
    is_deeply(&$fn(2000,  1,  2), [1999, 52]);

    is_deeply(&$fn(1999,  1, 11), [1999,  2]);
    is_deeply(&$fn(1999,  1, 10), [1999,  1]);
    is_deeply(&$fn(1999,  1,  4), [1999,  1]);
    is_deeply(&$fn(1999,  1,  3), [1998, 53]);

    # Test caching by poking a different epoch value into the object
    $d = Pinwheel::Model::Time::utc(2007, 1, 1);
    is($d->iso_year, 2007);
    is($d->iso_week, 1);
    $d->{s} = 0;
    is($d->iso_year, 2007);
    is($d->iso_week, 1);
    # Same again, but accessing bbc_week first
    $d = Pinwheel::Model::Time::utc(2007, 1, 1);
    is($d->iso_week, 1);
    is($d->iso_year, 2007);
    $d->{s} = 0;
    is($d->iso_week, 1);
    is($d->iso_year, 2007);
}

# ISO weekday numbering
{
    my ($t);

    $t = Pinwheel::Model::Time::utc(2008, 8, 10);
    is($t->iso_weekday, 7);
    $t = Pinwheel::Model::Time::utc(2008, 8, 11);
    is($t->iso_weekday, 1);
    $t = Pinwheel::Model::Time::utc(2008, 8, 12);
    is($t->iso_weekday, 2);
    $t = Pinwheel::Model::Time::utc(2008, 8, 13);
    is($t->iso_weekday, 3);
    $t = Pinwheel::Model::Time::utc(2008, 8, 14);
    is($t->iso_weekday, 4);
    $t = Pinwheel::Model::Time::utc(2008, 8, 15);
    is($t->iso_weekday, 5);
    $t = Pinwheel::Model::Time::utc(2008, 8, 16);
    is($t->iso_weekday, 6);
    $t = Pinwheel::Model::Time::utc(2008, 8, 17);
    is($t->iso_weekday, 7);
    $t = Pinwheel::Model::Time::utc(2008, 8, 18);
    is($t->iso_weekday, 1);
}

# Days in month
{
    my (@days, $t);

    @days = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    $t = Pinwheel::Model::Time::local(2000, 1, 2);
    foreach (0 ... 11) {
        next if $_ == 1;
        $t->{t}[4] = $_;
        is($t->days_in_month, $days[$_]);
    }

    $t->{t}[4] = 1;
    $t->{t}[5] = 2000 - 1900;
    is($t->days_in_month, 29);
    $t->{t}[5] = 2001 - 1900;
    is($t->days_in_month, 28);
    $t->{t}[5] = 2096 - 1900;
    is($t->days_in_month, 29);
    $t->{t}[5] = 2100 - 1900;
    is($t->days_in_month, 28);
}

# Simple formatting
{
    my (@months, @days, $t, $n);

    @months = qw(
        January February March April May June July
        August September October November December
    );
    @days = qw(
        Sunday Monday Tuesday Wednesday Thursday Friday Saturday
    );

    foreach (1 .. 12) {
        $t = Pinwheel::Model::Time::local(2007, $_, 1, 12, 30, 45);
        is($t->month_name, $months[$_ - 1]);
        is($t->short_month_name, substr($months[$_ - 1], 0, 3));
    }
    foreach (1 .. 7) {
        $t = Pinwheel::Model::Time::local(2007, 4, $_, 12, 30, 45);
        is($t->day_name, $days[$_ - 1]);
        is($t->short_day_name, substr($days[$_ - 1], 0, 3));
    }

    foreach (1 .. 31) {
        $t = Pinwheel::Model::Time::local(2007, 1, $_, 12, 30, 45);
        $n = $_ % 10;
        if ($_ >= 10 && $_ < 20) {
            is($t->day_suffix, 'th');
            is($t->day_ordinal, $_ . 'th');
        } elsif ($n == 1) {
            is($t->day_suffix, 'st');
            is($t->day_ordinal, $_ . 'st');
        } elsif ($n == 2) {
            is($t->day_suffix, 'nd');
            is($t->day_ordinal, $_ . 'nd');
        } elsif ($n == 3) {
            is($t->day_suffix, 'rd');
            is($t->day_ordinal, $_ . 'rd');
        } else {
            is($t->day_suffix, 'th');
            is($t->day_ordinal, $_ . 'th');
        }
    }

    $t = Pinwheel::Model::Time::local(2007, 1, 1);
    is($t->mm, '01');
    is($t->dd, '01');
    $t = Pinwheel::Model::Time::local(2007, 12, 31);
    is($t->mm, '12');
    is($t->dd, '31');

    $t = Pinwheel::Model::Time::local(2007, 1, 1, 12, 30, 45);
    is($t->hh_mm, '12:30');
    is($t->hh_mm_ss, '12:30:45');
    $t = Pinwheel::Model::Time::local(2007, 1, 1, 1, 2, 3);
    is($t->hh_mm, '01:02');
    is($t->hh_mm_ss, '01:02:03');

    $t = Pinwheel::Model::Time::local(2007, 1, 1, 12, 30, 45);
    is($t->rfc822, 'Mon, 01 Jan 2007 12:30:45 GMT');
    $t = Pinwheel::Model::Time::local(2007, 12, 31, 1, 2, 3);
    is($t->rfc822, 'Mon, 31 Dec 2007 01:02:03 GMT');
    $t = Pinwheel::Model::Time::local(2007, 4, 1, 12, 30, 45);
    is($t->rfc822, 'Sun, 01 Apr 2007 11:30:45 GMT');
    is($t->getutc->rfc822, 'Sun, 01 Apr 2007 11:30:45 GMT');
}

# strftime
{
    my $t;

    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    is($t->strftime('%Y-%m-%d %H:%M:%S'), '2007-06-01 12:30:45');
    $t = Pinwheel::Model::Time::utc(2007, 6, 1, 12, 30, 45);
    is($t->strftime('%Y-%m-%d %H:%M:%S'), '2007-06-01 12:30:45');

    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 0);
    is($t->iso8601, '2007-06-01T12:30:00+01:00');
    is($t->getutc()->iso8601, '2007-06-01T11:30:00Z');
    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    is($t->iso8601, '2007-06-01T12:30:45+01:00');
    is($t->getutc()->iso8601, '2007-06-01T11:30:45Z');
    is($t->iso8601_ical, '20070601T123045');
    is($t->getutc()->iso8601_ical, '20070601T113045Z');
}

# Replace components
{
    my $t;

    $t = Pinwheel::Model::Time::utc(2007, 1, 31, 12, 30, 0);
    is($t->replace(month => 2)->iso8601, '2007-02-28T12:30:00Z');
    $t = Pinwheel::Model::Time::utc(2004, 3, 1, 12, 30, 0);
    is($t->replace(month => 2, day => 31)->iso8601, '2004-02-29T12:30:00Z');

    $t = Pinwheel::Model::Time::utc(2007, 1, 31, 12, 30, 45);
    is($t->replace(year => 2006)->year, 2006);
    is($t->replace(month => 10)->month, 10);
    is($t->replace(day => 4)->day, 4);
    is($t->replace(hour => 8)->hour, 8);
    is($t->replace(min => 20)->min, 20);
    is($t->replace(sec => 47)->sec, 47);

    $t = Pinwheel::Model::Time::local(2007, 6, 1);
    is($t->replace(day => 2)->iso8601, '2007-06-02T00:00:00+01:00');

    $t = Pinwheel::Model::Time::utc(2007, 1, 31, 12, 30, 45);
    is($t->replace(month => -1)->month, 1);
    is($t->replace(month => 13)->month, 12);
    is($t->replace(month => 2)->day, 28);
    is($t->replace(day => -1)->day, 1);
    is($t->replace(day => 32)->day, 31);

    $t = Pinwheel::Model::Time::utc(2007, 1, 31, 12, 30, 45);
    is($t->replace(hour => -1)->hour, 0);
    is($t->replace(hour => 24)->hour, 23);
    is($t->replace(min => -1)->min, 0);
    is($t->replace(min => 60)->min, 59);
    is($t->replace(sec => -1)->sec, 0);
    is($t->replace(sec => 60)->sec, 59);
}

# Offset components
{
    my $t;

    $t = Pinwheel::Model::Time::utc(2007, 1, 31, 12, 30, 45);
    is($t->offset(days => 1)->iso8601, '2007-02-01T12:30:45Z');
    is($t->offset(days => 29)->iso8601, '2007-03-01T12:30:45Z');
    is($t->offset(days => -31)->iso8601, '2006-12-31T12:30:45Z');
    is($t->offset(months => 12)->iso8601, '2008-01-31T12:30:45Z');
    is($t->offset(months => -1)->iso8601, '2006-12-31T12:30:45Z');
    is($t->offset(months => 1)->iso8601, '2007-02-28T12:30:45Z');
    is($t->offset(months => 3)->iso8601, '2007-04-30T12:30:45Z');
    is($t->offset(years => 1)->iso8601, '2008-01-31T12:30:45Z');

    $t = Pinwheel::Model::Time::utc(2004, 2, 29, 12, 30, 45);
    is($t->offset(years => 1)->iso8601, '2005-02-28T12:30:45Z');

    $t = Pinwheel::Model::Time::utc(2000, 3, 1, 12, 30, 45);
    is($t->offset(days => -1)->iso8601, '2000-02-29T12:30:45Z');

    $t = Pinwheel::Model::Time::local(2007, 3, 31, 12, 30, 45);
    is($t->offset(days => -1)->iso8601, '2007-03-30T12:30:45+01:00');

    $t = Pinwheel::Model::Time::local(2007, 3, 31, 12, 30, 45);
    is($t->next_day->iso8601, '2007-04-01T12:30:45+01:00');
    is($t->previous_day->iso8601, '2007-03-30T12:30:45+01:00');
    is($t->next_week->iso8601, '2007-04-07T12:30:45+01:00');
    is($t->previous_week->iso8601, '2007-03-24T12:30:45Z');
    is($t->next_month->iso8601, '2007-04-30T12:30:45+01:00');
    is($t->previous_month->iso8601, '2007-02-28T12:30:45Z');

    $t = Pinwheel::Model::Time::local(2007, 3, 15, 12, 30, 45);
    is($t->first_of_month->iso8601, '2007-03-01T12:30:45Z');
    is($t->last_of_month->iso8601, '2007-03-31T12:30:45+01:00');
    is($t->previous_month->last_of_month->iso8601, '2007-02-28T12:30:45Z');
}

# Add a number of seconds to the time
{
    my ($t1, $t2);

    $t1 = Pinwheel::Model::Time->new(1000000000, 1);
    $t2 = $t1->add(42);
    is($t2->timestamp, 1000000042);
    is($t2->getutc(), $t2);

    $t1 = Pinwheel::Model::Time->new(1000000000, 0);
    $t2 = $t1->add(42);
    is($t2->timestamp, 1000000042);
    is($t2->getlocal(), $t2);
}

# Output conversions
{
    my ($t, $d);

    $t = Pinwheel::Model::Time::utc(2007, 6, 1, 12, 30, 45);
    is($t->sql_param, '2007-06-01 12:30:45');
    is($t->toJson, $t->timestamp);
    is($t->route_param, $t->timestamp);

    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    is($t->sql_param, '2007-06-01 11:30:45');
    is($t->toJson, $t->timestamp);
    is($t->route_param, $t->timestamp);

    $t = Pinwheel::Model::Time::local(2007, 6, 1, 12, 30, 45);
    $d = $t->to_date;
    is(ref($d), 'Pinwheel::Model::Date');
    is($d->iso8601, '2007-06-01');
}
