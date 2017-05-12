#! /usr/bin/env perl

use strict;
use warnings;

use POSIX qw(strftime);
use Test::More tests => 317;
use Time::Local qw(timegm);

use Pinwheel::Model::Date;


# Constructor
{
    my ($d, $t1, $t2);

    $d = Pinwheel::Model::Date->new(1000000000);
    is(ref($d), 'Pinwheel::Model::Date');
    $d = Pinwheel::Model::Date::now();
    is(ref($d), 'Pinwheel::Model::Date');
    $d = Pinwheel::Model::Date::now(0);
    is(ref($d), 'Pinwheel::Model::Date');
    $d = Pinwheel::Model::Date::now(1);
    is(ref($d), 'Pinwheel::Model::Date');
    $d = Pinwheel::Model::Date::date(2007, 1, 2);
    is(ref($d), 'Pinwheel::Model::Date');
    $d = Pinwheel::Model::Date::parse("2007-01-02");
    is(ref($d), 'Pinwheel::Model::Date');

    $d = Pinwheel::Model::Date->new(1000000000);
    is($d->year, 2001);
    is($d->month, 9);
    is($d->day, 9);

    $t1 = strftime('%Y-%m-%d', (localtime));
    $d = Pinwheel::Model::Date::now();
    $t2 = strftime('%Y-%m-%d', (localtime));
    cmp_ok($t1, 'le', $d->iso8601);
    cmp_ok($t2, 'ge', $d->iso8601);

    $t1 = strftime('%Y-%m-%d', (gmtime));
    $d = Pinwheel::Model::Date::now(1);
    $t2 = strftime('%Y-%m-%d', (gmtime));
    cmp_ok($t1, 'le', $d->iso8601);
    cmp_ok($t2, 'ge', $d->iso8601);

    $t1 = strftime('%Y-%m-%d', (localtime));
    $d = Pinwheel::Model::Date::now(0);
    $t2 = strftime('%Y-%m-%d', (localtime));
    cmp_ok($t1, 'le', $d->iso8601);
    cmp_ok($t2, 'ge', $d->iso8601);

    $d = Pinwheel::Model::Date::date(2001);
    is($d->year, 2001);
    is($d->month, 1);
    is($d->day, 1);

    $d = Pinwheel::Model::Date::date(2001, 5);
    is($d->year, 2001);
    is($d->month, 5);
    is($d->day, 1);

    $d = Pinwheel::Model::Date::date(2001, 2, 3);
    is($d->year, 2001);
    is($d->month, 2);
    is($d->day, 3);
    
    $d = Pinwheel::Model::Date::parse("2001");
    is($d->year, 2001);
    is($d->month, 1);
    is($d->day, 1);
    
    $d = Pinwheel::Model::Date::parse("2001-05");
    is($d->year, 2001);
    is($d->month, 5);
    is($d->day, 1);

    $d = Pinwheel::Model::Date::parse("2001-02-03");
    is($d->year, 2001);
    is($d->month, 2);
    is($d->day, 3);
    
    is(Pinwheel::Model::Date::parse("20001"), undef);
    is(Pinwheel::Model::Date::parse("2008x"), undef);
    is(Pinwheel::Model::Date::parse("2008/06"), undef);
    is(Pinwheel::Model::Date::parse("2008--06"), undef);
    is(Pinwheel::Model::Date::parse("2008-06-1"), undef);
}

# Date attributes
{
    my $d;

    $d = Pinwheel::Model::Date::date(2007, 6, 1);
    is($d->year, 2007);
    is($d->month, 6);
    is($d->day, 1);
    is($d->wday, 5);
    is($d->yday, 151);
}

# BBC calendar
{
    my ($fn, $d);

    $fn = sub {
        my $d = Pinwheel::Model::Date::date(@_);
        return [$d->bbc_year, $d->bbc_week];
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
    $d = Pinwheel::Model::Date::date(2007, 1, 1);
    is($d->bbc_year, 2007);
    is($d->bbc_week, 1);
    $d->{s} = 0;
    is($d->bbc_year, 2007);
    is($d->bbc_week, 1);
    # Same again, but accessing bbc_week first
    $d = Pinwheel::Model::Date::date(2007, 1, 1);
    is($d->bbc_week, 1);
    is($d->bbc_year, 2007);
    $d->{s} = 0;
    is($d->bbc_week, 1);
    is($d->bbc_year, 2007);

    # Test from_bbc_week
    $d = Pinwheel::Model::Date::from_bbc_week(2007, 1);
    is($d->bbc_year, 2007);
    is($d->bbc_week, 1);
    is($d->year, 2006);
    is($d->month, 12);
    is($d->day, 30);
    $d = Pinwheel::Model::Date::from_bbc_week(2002, 53);
    is($d->bbc_year, 2002);
    is($d->bbc_week, 53);
}

# ISO week date
{
    my ($fn, $d);

    $fn = sub {
        my $d = Pinwheel::Model::Date::date(@_);
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
    $d = Pinwheel::Model::Date::date(2007, 1, 1);
    is($d->iso_year, 2007);
    is($d->iso_week, 1);
    $d->{s} = 0;
    is($d->iso_year, 2007);
    is($d->iso_week, 1);
    # Same again, but accessing bbc_week first
    $d = Pinwheel::Model::Date::date(2007, 1, 1);
    is($d->iso_week, 1);
    is($d->iso_year, 2007);
    $d->{s} = 0;
    is($d->iso_week, 1);
    is($d->iso_year, 2007);

    # Test from_iso_week
    $d = Pinwheel::Model::Date::from_iso_week(2007, 1);
    is($d->iso_year, 2007);
    is($d->iso_week, 1);
    is($d->iso8601, '2007-01-01');
    $d = Pinwheel::Model::Date::from_iso_week(2004, 53);
    is($d->iso_year, 2004);
    is($d->iso_week, 53);
    is($d->iso8601, '2004-12-27');
}

# ISO weekday numbering
{
    my ($d);

    $d = Pinwheel::Model::Date::date(2008, 8, 10);
    is($d->iso_weekday, 7);
    $d = Pinwheel::Model::Date::date(2008, 8, 11);
    is($d->iso_weekday, 1);
    $d = Pinwheel::Model::Date::date(2008, 8, 12);
    is($d->iso_weekday, 2);
    $d = Pinwheel::Model::Date::date(2008, 8, 13);
    is($d->iso_weekday, 3);
    $d = Pinwheel::Model::Date::date(2008, 8, 14);
    is($d->iso_weekday, 4);
    $d = Pinwheel::Model::Date::date(2008, 8, 15);
    is($d->iso_weekday, 5);
    $d = Pinwheel::Model::Date::date(2008, 8, 16);
    is($d->iso_weekday, 6);
    $d = Pinwheel::Model::Date::date(2008, 8, 17);
    is($d->iso_weekday, 7);
    $d = Pinwheel::Model::Date::date(2008, 8, 18);
    is($d->iso_weekday, 1);
}

# Days in month
{
    my (@days, $d);

    @days = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    $d = Pinwheel::Model::Date::date(2000, 1, 2);
    foreach (0 ... 11) {
        next if $_ == 1;
        $d->{t}[4] = $_;
        is($d->days_in_month, $days[$_]);
    }

    $d->{t}[4] = 1;
    $d->{t}[5] = 2000 - 1900;
    is($d->days_in_month, 29);
    $d->{t}[5] = 2001 - 1900;
    is($d->days_in_month, 28);
    $d->{t}[5] = 2096 - 1900;
    is($d->days_in_month, 29);
    $d->{t}[5] = 2100 - 1900;
    is($d->days_in_month, 28);
}

# Simple formatting
{
    my (@months, @days, $d, $n);

    @months = qw(
        January February March April May June July
        August September October November December
    );
    @days = qw(
        Sunday Monday Tuesday Wednesday Thursday Friday Saturday
    );

    foreach (1 .. 12) {
        $d = Pinwheel::Model::Date::date(2007, $_, 1);
        is($d->month_name, $months[$_ - 1]);
        is($d->short_month_name, substr($months[$_ - 1], 0, 3));
    }
    foreach (1 .. 7) {
        $d = Pinwheel::Model::Date::date(2007, 4, $_);
        is($d->day_name, $days[$_ - 1]);
        is($d->short_day_name, substr($days[$_ - 1], 0, 3));
    }

    foreach (1 .. 31) {
        $d = Pinwheel::Model::Date::date(2007, 1, $_);
        $n = $_ % 10;
        if ($_ >= 10 && $_ < 20) {
            is($d->day_suffix, 'th');
            is($d->day_ordinal, $_ . 'th');
        } elsif ($n == 1) {
            is($d->day_suffix, 'st');
            is($d->day_ordinal, $_ . 'st');
        } elsif ($n == 2) {
            is($d->day_suffix, 'nd');
            is($d->day_ordinal, $_ . 'nd');
        } elsif ($n == 3) {
            is($d->day_suffix, 'rd');
            is($d->day_ordinal, $_ . 'rd');
        } else {
            is($d->day_suffix, 'th');
            is($d->day_ordinal, $_ . 'th');
        }
    }

    $d = Pinwheel::Model::Date::date(2007, 1, 1);
    is($d->mm, '01');
    is($d->dd, '01');
    $d = Pinwheel::Model::Date::date(2007, 12, 31);
    is($d->mm, '12');
    is($d->dd, '31');
}

# strftime
{
    my $d;

    $d = Pinwheel::Model::Date::date(2007, 6, 1);
    is($d->strftime('%Y-%m-%d'), '2007-06-01');

    $d = Pinwheel::Model::Date::date(2007, 6, 1);
    is($d->iso8601, '2007-06-01');
}

# Replace components
{
    my $d;

    $d = Pinwheel::Model::Date::date(2007, 1, 31);
    is($d->replace(month => 2)->iso8601, '2007-02-28');
    $d = Pinwheel::Model::Date::date(2004, 3, 1);
    is($d->replace(month => 2, day => 31)->iso8601, '2004-02-29');

    $d = Pinwheel::Model::Date::date(2007, 1, 31);
    is($d->replace(year => 2006)->year, 2006);
    is($d->replace(month => 10)->month, 10);
    is($d->replace(day => 4)->day, 4);

    $d = Pinwheel::Model::Date::date(2007, 6, 1);
    is($d->replace(day => 2)->iso8601, '2007-06-02');

    $d = Pinwheel::Model::Time::utc(2007, 1, 31);
    is($d->replace(month => -1)->month, 1);
    is($d->replace(month => 13)->month, 12);
    is($d->replace(month => 2)->day, 28);
    is($d->replace(day => -1)->day, 1);
    is($d->replace(day => 32)->day, 31);
}

# Offset components
{
    my $d;

    $d = Pinwheel::Model::Date::date(2007, 1, 31);
    is($d->offset(days => 1)->iso8601, '2007-02-01');
    is($d->offset(days => 29)->iso8601, '2007-03-01');
    is($d->offset(days => -31)->iso8601, '2006-12-31');
    is($d->offset(months => 12)->iso8601, '2008-01-31');
    is($d->offset(months => -1)->iso8601, '2006-12-31');
    is($d->offset(months => 1)->iso8601, '2007-02-28');
    is($d->offset(months => 3)->iso8601, '2007-04-30');
    is($d->offset(years => 1)->iso8601, '2008-01-31');

    $d = Pinwheel::Model::Date->new(1206449428);
    is($d->offset(days => 1)->iso8601, '2008-03-26');

    $d = Pinwheel::Model::Date::date(2004, 2, 29);
    is($d->offset(years => 1)->iso8601, '2005-02-28');

    $d = Pinwheel::Model::Date::date(2000, 3, 1);
    is($d->offset(days => -1)->iso8601, '2000-02-29');

    $d = Pinwheel::Model::Date::date(2007, 3, 31);
    is($d->offset(days => -1)->iso8601, '2007-03-30');

    $d = Pinwheel::Model::Date::date(2007, 3, 31);
    is($d->next_day->iso8601, '2007-04-01');
    is($d->previous_day->iso8601, '2007-03-30');
    is($d->next_week->iso8601, '2007-04-07');
    is($d->previous_week->iso8601, '2007-03-24');
    is($d->next_month->iso8601, '2007-04-30');
    is($d->previous_month->iso8601, '2007-02-28');

    $d = Pinwheel::Model::Date::date(2007, 3, 15);
    is($d->first_of_month->iso8601, '2007-03-01');
    is($d->last_of_month->iso8601, '2007-03-31');
    is($d->previous_month->last_of_month->iso8601, '2007-02-28');
}

# Output conversions
{
    my ($d, $t, $t1, $t2);

    $d = Pinwheel::Model::Date::date(2007, 6, 1);
    $t = $d->to_time;
    is($t->year, 2007);
    is($t->month, 6);
    is($t->day, 1);
    $t1 = timegm(0, 0, 0, 1, 6 - 1, 2007 - 1900);
    $t2 = timegm(0, 0, 0, 2, 6 - 1, 2007 - 1900);
    is($d->sql_param, '2007-06-01');
    cmp_ok($d->toJson, '>=', $t1);
    cmp_ok($d->toJson, '<', $t2);
    is_deeply($d->route_param, { year => 2007, month => 6, day => 1 });
}

# Difference between two dates
{
    my ($d1, $d2);

    $d1 = Pinwheel::Model::Date::date(2009, 1, 2);
    $d2 = Pinwheel::Model::Date::date(2007, 10, 4);
    is($d1->difference($d2), 456);
    is($d2->difference($d1), -456);
    is($d1->difference($d1), 0);

    # Check Daylight Saving Time changeover (23 hour day)
    $d1 = Pinwheel::Model::Date::date(2009, 3, 30);
    $d2 = Pinwheel::Model::Date::date(2009, 3, 29);
    is($d1->difference($d2), 1);
}
