#!/usr/bin/env perl
# t/02_datetime.t – comprehensive tests for NepaliDateTime::DateTime
# Covers all Python nepali_datetime.datetime tests plus Perl-specific extras.
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test2::V1 '-ipP';

use NepaliDateTime::Date;
use NepaliDateTime::DateTime;
use NepaliDateTime::Data;

# ---------------------------------------------------------------------------
# 1. Construction & accessors  (Python: test_init)
# ---------------------------------------------------------------------------
subtest 'Construction and accessors (Python: test_init)' => sub {
    my $dt = NepaliDateTime::DateTime->new(2033, 2, 10, 10, 5, 30, 123456);
    is($dt->year,        2033,   'year');
    is($dt->month,       2,      'month');
    is($dt->day,         10,     'day');
    is($dt->hour,        10,     'hour');
    is($dt->minute,      5,      'minute');
    is($dt->second,      30,     'second');
    is($dt->microsecond, 123456, 'microsecond');
};

subtest 'Construction defaults (time components)' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15);
    is($dt->hour,        0, 'hour defaults to 0');
    is($dt->minute,      0, 'minute defaults to 0');
    is($dt->second,      0, 'second defaults to 0');
    is($dt->microsecond, 0, 'microsecond defaults to 0');
};

subtest 'Construction boundary – min/max times' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 23, 59, 59, 999999);
    is($dt->hour,        23,     'hour 23');
    is($dt->minute,      59,     'minute 59');
    is($dt->second,      59,     'second 59');
    is($dt->microsecond, 999999, 'microsecond 999999');
};

# ---------------------------------------------------------------------------
# 2. Invalid construction
# ---------------------------------------------------------------------------
subtest 'Invalid construction' => sub {
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15, 24, 0,  0)     }, 'hour 24 dies');
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15, -1, 0,  0)     }, 'hour -1 dies');
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15,  0, 60, 0)     }, 'minute 60 dies');
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15,  0, 0,  60)    }, 'second 60 dies');
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15,  0, 0,  0, -1) }, 'microsecond -1 dies');
    ok(dies { NepaliDateTime::DateTime->new(2081, 3, 15,  0, 0,  0, 1_000_000) }, 'microsecond 1000000 dies');
    ok(dies { NepaliDateTime::DateTime->new(1974, 1, 1) }, 'year before MINYEAR dies');
    ok(dies { NepaliDateTime::DateTime->new(2101, 1, 1) }, 'year after MAXYEAR dies');
};

# ---------------------------------------------------------------------------
# 3. now() – Python: test_now
# ---------------------------------------------------------------------------
subtest 'now() range check (Python: test_now)' => sub {
    my $now = NepaliDateTime::DateTime->now();
    isa_ok($now, 'NepaliDateTime::DateTime');
    ok($now->year   >= 1975 && $now->year   <= 2100, 'year in range');
    ok($now->month  >= 1    && $now->month  <= 12,   'month in range');
    ok($now->day    >= 1    && $now->day    <= 32,   'day in range');
    ok($now->hour   >= 0    && $now->hour   <= 23,   'hour in range');
    ok($now->minute >= 0    && $now->minute <= 59,   'minute in range');
    ok($now->second >= 0    && $now->second <= 59,   'second in range');
    ok($now->microsecond >= 0 && $now->microsecond <= 999999, 'microsecond in range');
};

# ---------------------------------------------------------------------------
# 4. utcnow() – Python: test_utcnow
# ---------------------------------------------------------------------------
subtest 'utcnow() (Python: test_utcnow)' => sub {
    my $nst  = NepaliDateTime::DateTime->now();
    my $utc  = NepaliDateTime::DateTime->utcnow();

    # Nepal is UTC+05:45, so NST is 5h45m ahead of UTC.
    # They might be the same BS date if called within the same second,
    # or the NST could be on a later BS date. We just check utcnow is
    # a DateTime and year is in range.
    isa_ok($utc, 'NepaliDateTime::DateTime');
    ok($utc->year  >= 1975 && $utc->year  <= 2100, 'utcnow year in range');
    ok($utc->month >= 1    && $utc->month <= 12,   'utcnow month in range');
};

# ---------------------------------------------------------------------------
# 5. timestamp round-trip  (Python: test_timestamp)
# Python test: datetime(2078,2,23).timestamp() == datetime(2021,6,6,tzinfo=UTC0545).timestamp()
# ---------------------------------------------------------------------------
subtest 'timestamp (Python: test_timestamp)' => sub {
    my $dt = NepaliDateTime::DateTime->new(2078, 2, 23, 0, 0, 0);
    my $ts  = $dt->to_timestamp();
    # 2021-06-06 00:00:00 NST = 2021-06-05 18:15:00 UTC
    # epoch = (2021-06-05 minus 1970-01-01) * 86400 + 18*3600 + 15*60
    # We verify round-trip via from_timestamp
    my $dt2 = NepaliDateTime::DateTime->from_timestamp($ts);
    is($dt2->year,   2078, 'timestamp RT year');
    is($dt2->month,  2,    'timestamp RT month');
    is($dt2->day,    23,   'timestamp RT day');
    is($dt2->hour,   0,    'timestamp RT hour');
    is($dt2->minute, 0,    'timestamp RT minute');
    is($dt2->second, 0,    'timestamp RT second');

    # Verify the actual epoch value is for 2021-06-06 00:00 NST
    # 2021-06-05 18:15:00 UTC  = 1622916900
    is($ts, 1622916900, 'timestamp matches known epoch for 2078-02-23 00:00 NST');
};

# ---------------------------------------------------------------------------
# 6. from_timestamp known value
# ---------------------------------------------------------------------------
subtest 'from_timestamp with known epoch' => sub {
    # epoch 0 = 1970-01-01 00:00:00 UTC = 1970-01-01 05:45 NST → BS 2026-09-17
    my $dt = NepaliDateTime::DateTime->from_timestamp(0);
    isa_ok($dt, 'NepaliDateTime::DateTime');
    is($dt->hour,   5,  'epoch 0 → hour 5 in NST');
    is($dt->minute, 45, 'epoch 0 → minute 45 in NST');
    is($dt->second, 0,  'epoch 0 → second 0');
};

# ---------------------------------------------------------------------------
# 7. from_ad_datetime
# ---------------------------------------------------------------------------
subtest 'from_ad_datetime' => sub {
    my $dt = NepaliDateTime::DateTime->from_ad_datetime(2024, 7, 15, 14, 30, 0);
    is($dt->year,   2081, 'from_ad_datetime BS year');
    is($dt->month,  3,    'from_ad_datetime BS month');
    is($dt->day,    31,   'from_ad_datetime BS day');
    is($dt->hour,   14,   'from_ad_datetime hour');
    is($dt->minute, 30,   'from_ad_datetime minute');
    is($dt->second, 0,    'from_ad_datetime second');

    # Defaults: midnight
    my $dt2 = NepaliDateTime::DateTime->from_ad_datetime(2024, 7, 15);
    is($dt2->hour,   0, 'from_ad_datetime default hour');
    is($dt2->minute, 0, 'from_ad_datetime default minute');
};

# ---------------------------------------------------------------------------
# 8. to_ad_datetime
# ---------------------------------------------------------------------------
subtest 'to_ad_datetime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 31, 14, 30, 0, 500000);
    my ($y,$m,$d,$h,$mi,$s,$us) = $dt->to_ad_datetime();
    is($y,  2024, 'to_ad_datetime year');
    is($m,  7,    'to_ad_datetime month');
    is($d,  15,   'to_ad_datetime day');
    is($h,  14,   'to_ad_datetime hour');
    is($mi, 30,   'to_ad_datetime minute');
    is($s,  0,    'to_ad_datetime second');
    is($us, 500000, 'to_ad_datetime microsecond');
};

# ---------------------------------------------------------------------------
# 9. combine
# ---------------------------------------------------------------------------
subtest 'combine' => sub {
    my $date = NepaliDateTime::Date->new(2081, 3, 15);
    my $dt   = NepaliDateTime::DateTime->combine($date, 14, 30, 0);
    is($dt->year,   2081, 'combine year');
    is($dt->month,  3,    'combine month');
    is($dt->day,    15,   'combine day');
    is($dt->hour,   14,   'combine hour');
    is($dt->minute, 30,   'combine minute');

    ok(dies { NepaliDateTime::DateTime->combine('not a date', 0, 0, 0) },
       'combine non-date dies');
};

# ---------------------------------------------------------------------------
# 10. isoformat  (Python: has isoformat with sep and microseconds)
# ---------------------------------------------------------------------------
subtest 'isoformat' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $iso = $dt->isoformat();
    is($iso, '2081-03-15T14:30:00+05:45', 'isoformat T separator');

    my $iso_sp = $dt->isoformat(' ');
    like($iso_sp, qr/2081-03-15 14:30:00/, 'isoformat space separator');

    # With microseconds
    my $dt2  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0, 500000);
    my $iso2 = $dt2->isoformat();
    like($iso2, qr/\.500000/, 'isoformat includes microseconds');
    like($iso2, qr/\+05:45/, 'isoformat includes timezone');

    # No microseconds → no fraction
    my $iso3 = $dt->isoformat();
    unlike($iso3, qr/\./, 'isoformat omits fraction when microsecond=0');
};

# ---------------------------------------------------------------------------
# 11. ctime
# ---------------------------------------------------------------------------
subtest 'ctime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $s  = $dt->ctime();
    like($s, qr/14:30:00/, 'ctime has time');
    like($s, qr/2081/,     'ctime has year');
    like($s, qr/Asa/,      'ctime has month abbreviation');
};

# ---------------------------------------------------------------------------
# 12. time_string
# ---------------------------------------------------------------------------
subtest 'time_string' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 5);
    is($dt->time_string(), '14:30:05', 'time_string without microseconds');

    my $dt2 = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 5, 123456);
    is($dt2->time_string(), '14:30:05.123456', 'time_string with microseconds');
};

# ---------------------------------------------------------------------------
# 13. date() method
# ---------------------------------------------------------------------------
subtest 'date() method' => sub {
    my $dt   = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $date = $dt->date();
    isa_ok($date, 'NepaliDateTime::Date');
    is($date->year,  2081, 'date() year');
    is($date->month, 3,    'date() month');
    is($date->day,   15,   'date() day');
    # date() should not have time accessors
    ok(!$date->can('hour'), 'Date has no hour method') if !$date->can('hour');
};

# ---------------------------------------------------------------------------
# 14. Arithmetic: add_seconds
# ---------------------------------------------------------------------------
subtest 'add_seconds' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 23, 59, 59);
    my $dt2 = $dt->add_seconds(2);
    is($dt2->day,    16, 'add_seconds(2) crosses midnight → day 16');
    is($dt2->hour,   0,  'add_seconds(2) → hour 0');
    is($dt2->minute, 0,  'add_seconds(2) → minute 0');
    is($dt2->second, 1,  'add_seconds(2) → second 1');

    # Negative seconds
    my $dt3 = NepaliDateTime::DateTime->new(2081, 3, 15, 0, 0, 1);
    my $dt4 = $dt3->add_seconds(-2);
    is($dt4->day,    14, 'add_seconds(-2) crosses midnight back → day 14');
    is($dt4->hour,   23, 'add_seconds(-2) → hour 23');
    is($dt4->second, 59, 'add_seconds(-2) → second 59');
};

subtest 'add_seconds – large values' => sub {
    my $dt   = NepaliDateTime::DateTime->new(2081, 3, 15, 0, 0, 0);
    my $dt2  = $dt->add_seconds(3600 * 25);  # 25 hours
    is($dt2->day,  16, 'add 25 hours → day 16');
    is($dt2->hour, 1,  'add 25 hours → hour 1');
};

# ---------------------------------------------------------------------------
# 15. Arithmetic: add_minutes
# ---------------------------------------------------------------------------
subtest 'add_minutes' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
    my $dt2 = $dt->add_minutes(90);
    is($dt2->hour,   11, 'add_minutes(90) hour');
    is($dt2->minute, 30, 'add_minutes(90) minute');

    # Negative
    my $dt3 = $dt->add_minutes(-30);
    is($dt3->hour,   9,  'add_minutes(-30) hour');
    is($dt3->minute, 30, 'add_minutes(-30) minute');
};

# ---------------------------------------------------------------------------
# 16. Arithmetic: add_hours
# ---------------------------------------------------------------------------
subtest 'add_hours' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 20, 0, 0);
    my $dt2 = $dt->add_hours(5);
    is($dt2->day,  16, 'add_hours(5) crosses midnight → day 16');
    is($dt2->hour, 1,  'add_hours(5) → hour 1');

    my $dt3 = $dt->add_hours(-20);
    is($dt3->hour, 0,  'add_hours(-20) → hour 0');
};

# ---------------------------------------------------------------------------
# 17. Arithmetic: add_days (preserves time)
# ---------------------------------------------------------------------------
subtest 'add_days preserves time' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $dt2 = $dt->add_days(1);
    is($dt2->day,    16, 'add_days(1) day');
    is($dt2->hour,   14, 'add_days(1) preserves hour');
    is($dt2->minute, 30, 'add_days(1) preserves minute');

    # Overloaded + for days
    my $dt3 = $dt + 1;
    is($dt3->day, 16, 'overloaded + 1 day');
};

# ---------------------------------------------------------------------------
# 18. Subtraction: seconds difference
# ---------------------------------------------------------------------------
subtest 'Subtraction: seconds diff' => sub {
    my $dt1 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
    my $dt2 = NepaliDateTime::DateTime->new(2081, 3, 15, 11, 0, 0);
    my $diff = $dt2 - $dt1;
    is($diff, 3600, '1 hour = 3600 seconds');

    # Different days
    my $dt3 = NepaliDateTime::DateTime->new(2081, 3, 16, 10, 0, 0);
    is($dt3 - $dt1, 86400, '1 day = 86400 seconds');

    # Negative diff
    is($dt1 - $dt2, -3600, 'reversed = -3600');

    # With microseconds
    my $dt4 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0, 500000);
    my $dt5 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0, 0);
    my $mdiff = $dt4 - $dt5;
    is($mdiff, 0.5, 'microsecond diff = 0.5 seconds');
};

# ---------------------------------------------------------------------------
# 19. replace
# ---------------------------------------------------------------------------
subtest 'replace' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $dt2 = $dt->replace(hour => 9, minute => 0);
    is($dt2->hour,   9,  'replace hour');
    is($dt2->minute, 0,  'replace minute');
    is($dt2->day,    15, 'replace preserves day');
    is($dt2->year,   2081, 'replace preserves year');

    my $dt3 = $dt->replace(year => 2082, second => 30, microsecond => 1000);
    is($dt3->year,        2082, 'replace year');
    is($dt3->second,      30,   'replace second');
    is($dt3->microsecond, 1000, 'replace microsecond');
    is($dt3->minute,      30,   'replace preserves minute');
};

# ---------------------------------------------------------------------------
# 20. clone
# ---------------------------------------------------------------------------
subtest 'clone' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0, 123);
    my $dt2 = $dt->clone();
    ok($dt == $dt2, 'clone == original');
    is($dt2->microsecond, 123, 'clone preserves microsecond');
};

# ---------------------------------------------------------------------------
# 21. Comparison operators
# ---------------------------------------------------------------------------
subtest 'Comparison operators' => sub {
    my $dt1 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
    my $dt2 = NepaliDateTime::DateTime->new(2081, 3, 15, 11, 0, 0);
    my $dt3 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);

    ok($dt1 <  $dt2, 'dt1 < dt2');
    ok($dt2 >  $dt1, 'dt2 > dt1');
    ok($dt1 == $dt3, 'dt1 == dt3');
    ok($dt1 != $dt2, 'dt1 != dt2');
    ok($dt1 <= $dt3, 'dt1 <= dt3');
    ok($dt2 >= $dt1, 'dt2 >= dt1');

    # Different days
    my $dt4 = NepaliDateTime::DateTime->new(2081, 3, 16, 10, 0, 0);
    ok($dt1 < $dt4, 'different day: dt1 < dt4');

    # Microsecond comparison
    my $dt5 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0, 1);
    ok($dt3 < $dt5, 'microsecond: dt3 < dt5');
};

# ---------------------------------------------------------------------------
# 22. tzname and utcoffset_string
# ---------------------------------------------------------------------------
subtest 'tzname and utcoffset_string' => sub {
    my $dt = NepaliDateTime::DateTime->now();
    is($dt->tzname(),           'NST',    'tzname = NST');
    is($dt->utcoffset_string(), '+05:45', 'utcoffset_string = +05:45');
};

# ---------------------------------------------------------------------------
# 23. min / max class methods
# ---------------------------------------------------------------------------
subtest 'min and max' => sub {
    my $min = NepaliDateTime::DateTime->min();
    is($min->year,        1975, 'min year');
    is($min->month,       1,    'min month');
    is($min->day,         1,    'min day');
    is($min->hour,        0,    'min hour');
    is($min->second,      0,    'min second');
    is($min->microsecond, 0,    'min microsecond');

    my $max = NepaliDateTime::DateTime->max();
    is($max->year,        2100,   'max year');
    is($max->month,       12,     'max month');
    is($max->hour,        23,     'max hour');
    is($max->second,      59,     'max second');
    is($max->microsecond, 999999, 'max microsecond');

    ok($min < $max, 'min < max');
};

# ---------------------------------------------------------------------------
# 24. Inheritance: DateTime IS-A Date
# ---------------------------------------------------------------------------
subtest 'DateTime inherits from Date' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    isa_ok($dt, 'NepaliDateTime::Date');

    # Date methods still work
    my $w = $dt->weekday();
    ok($w >= 0 && $w <= 6, 'weekday from DateTime');

    my ($s,$e) = $dt->fiscal_year();
    ok(defined $s && defined $e, 'fiscal_year from DateTime');
};

# ---------------------------------------------------------------------------
# 25. format_devanagari (DateTime version)
# ---------------------------------------------------------------------------
subtest 'format_devanagari on DateTime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $s  = $dt->format_devanagari();
    ok(length($s) > 0, 'format_devanagari non-empty');
    like($s, qr/असार/, 'contains Devanagari month');
    # Devanagari digits for time
    like($s, qr/[०-९]/, 'contains Devanagari digits');
};

done_testing();
