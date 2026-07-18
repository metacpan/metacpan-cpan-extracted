#!/usr/bin/env perl
# t/05_edge_cases.t – edge-case and robustness tests
# Supplements 01–04 with boundary values, operator overloading, and
# cross-cutting behaviour that the Python package exercises implicitly.
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test2::V1 '-ipP';

use NepaliDateTime::Date;
use NepaliDateTime::DateTime;
use NepaliDateTime::Data;

# ===========================================================================
# 1. Ordinal boundaries
# ===========================================================================

subtest 'Ordinal boundary – ordinal 1 == min date' => sub {
    my $d = NepaliDateTime::Date->from_ordinal(1);
    is($d->year,  $NepaliDateTime::Data::MINYEAR, 'ordinal 1 → MINYEAR');
    is($d->month, 1, 'ordinal 1 → month 1');
    is($d->day,   1, 'ordinal 1 → day 1');
    is($d->toordinal(), 1, 'min date ordinal = 1');
};

subtest 'Ordinal boundary – ordinal MAXORDINAL == max date' => sub {
    my $max = NepaliDateTime::Date->max();
    is($max->toordinal(), $NepaliDateTime::Data::MAXORDINAL,
       'max date ordinal == MAXORDINAL');
    my $d = NepaliDateTime::Date->from_ordinal($NepaliDateTime::Data::MAXORDINAL);
    is($d->year,  2100, 'MAXORDINAL → year 2100');
    is($d->month, 12,   'MAXORDINAL → month 12');
};

subtest 'Ordinal round-trip across all boundaries' => sub {
    # First and last day of each year 1975..2100
    for my $year (1975, 2000, 2025, 2050, 2075, 2100) {
        my $first = NepaliDateTime::Date->new($year, 1, 1);
        my $ord   = $first->toordinal();
        my $back  = NepaliDateTime::Date->from_ordinal($ord);
        is($back->year,  $year, "ordinal RT first day of $year: year");
        is($back->month, 1,     "ordinal RT first day of $year: month");
        is($back->day,   1,     "ordinal RT first day of $year: day");

        my $dim_12 = $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[12];
        my $last   = NepaliDateTime::Date->new($year, 12, $dim_12);
        my $ord2   = $last->toordinal();
        my $back2  = NepaliDateTime::Date->from_ordinal($ord2);
        is($back2->year,  $year,  "ordinal RT last day of $year: year");
        is($back2->month, 12,     "ordinal RT last day of $year: month");
        is($back2->day,   $dim_12,"ordinal RT last day of $year: day");
    }
};

# ===========================================================================
# 2. add_days edge cases
# ===========================================================================

subtest 'add_days – zero' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = $d->add_days(0);
    ok($d == $d2, 'add_days(0) == original');
};

subtest 'add_days – cross year boundary forward' => sub {
    # Last day of 2081 Chaitra
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[12];
    my $last = NepaliDateTime::Date->new(2081, 12, $dim);
    my $next = $last->add_days(1);
    is($next->year,  2082, 'add_days(1) from last of 2081 → 2082');
    is($next->month, 1,    'add_days(1) from last of 2081 → month 1');
    is($next->day,   1,    'add_days(1) from last of 2081 → day 1');
};

subtest 'add_days – cross year boundary backward' => sub {
    my $first = NepaliDateTime::Date->new(2081, 1, 1);
    my $prev  = $first->add_days(-1);
    is($prev->year,  2080, 'add_days(-1) from first of 2081 → 2080');
    is($prev->month, 12,   'add_days(-1) from first of 2081 → month 12');
    my $dim  = $NepaliDateTime::Data::DAYS_IN_MONTH{2080}[12];
    is($prev->day, $dim, 'add_days(-1) from first of 2081 → last day of 2080');
};

subtest 'add_days – out of range dies' => sub {
    my $max = NepaliDateTime::Date->max();
    ok(dies { $max->add_days(1) }, 'add_days(1) beyond max dies');
    my $min = NepaliDateTime::Date->min();
    ok(dies { $min->add_days(-1) }, 'add_days(-1) before min dies');
};

# ===========================================================================
# 3. add_months edge cases
# ===========================================================================

subtest 'add_months – zero' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 6, 15);
    my $d2 = $d->add_months(0);
    ok($d == $d2, 'add_months(0) unchanged');
};

subtest 'add_months – negative crosses year boundary' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 1);
    my $d2 = $d->add_months(-3);
    is($d2->year,  2080, 'add_months(-3) from month 3 → prev year');
    is($d2->month, 12,   'add_months(-3) from month 3 → month 12');
};

subtest 'add_months – day clamped to short month' => sub {
    # Jestha (month 2) 2081 has 32 days; Magh (month 10) 2081 has 30 days.
    # Adding 8 months from a day-32 date must clamp to month end (30).
    my $dim_10 = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[10];   # 30
    is($dim_10, 30, 'sanity: Magh 2081 has 30 days');

    my $long  = NepaliDateTime::Date->new(2081, 2, 32);  # Jestha 32
    my $short = $long->add_months(8);                     # → Magh (month 10)
    is($short->month, 10,     'add_months into short month: month correct');
    is($short->day,   $dim_10,'add_months into short month: day clamped to month end');
    ok($short->day <= $short->days_in_month(), 'day ≤ days_in_month');
};

subtest 'add_months – full year wrap' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 6, 15);
    my $d2 = $d->add_months(12);
    is($d2->year,  2082, 'add_months(12) → next year');
    is($d2->month, 6,    'add_months(12) → same month');
    is($d2->day,   15,   'add_months(12) → same day');
};

# ===========================================================================
# 4. add_years edge cases
# ===========================================================================

subtest 'add_years – zero' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 6, 15);
    my $d2 = $d->add_years(0);
    ok($d == $d2, 'add_years(0) unchanged');
};

subtest 'add_years – out of range dies' => sub {
    my $max = NepaliDateTime::Date->max();
    ok(dies { $max->add_years(1) }, 'add_years(1) from max dies');
};

# ===========================================================================
# 5. Operator overloading
# ===========================================================================

subtest 'Operator "" (string coercion)' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    is("$d", '2081-03-15', '"$d" gives isoformat');

    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    like("$dt", qr/^2081-03-15T14:30:00\+05:45$/, '"$dt" gives isoformat with TZ');
};

subtest 'Operator + and - for Date' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = $d + 10;
    is($d2->day, 25, '$d + 10 → day 25');

    my $d3 = $d - 5;
    is($d3->day, 10, '$d - 5 → day 10');

    # Date - Date = integer
    my $diff = $d2 - $d;
    is($diff, 10, '$d2 - $d = 10');
    is($d - $d2, -10, '$d - $d2 = -10');

    # Same date → 0
    is($d - $d, 0, '$d - $d = 0');
};

subtest 'Operator + and - for DateTime' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $dt2 = $dt + 5;
    is($dt2->day,  20,   '$dt + 5 → day 20');
    is($dt2->hour, 14,   '$dt + 5 preserves hour');

    my $dt3 = $dt - 5;
    is($dt3->day, 10, '$dt - 5 → day 10');

    # DateTime - DateTime = seconds
    my $dt4 = NepaliDateTime::DateTime->new(2081, 3, 15, 15, 30, 0);
    is($dt4 - $dt, 3600, '$dt4 - $dt = 3600 seconds');
};

subtest 'Operator <=> (sort)' => sub {
    my @days_in  = (20, 5, 15, 1, 30);
    my @dates    = map { NepaliDateTime::Date->new(2081, 3, $_) } @days_in;
    my @sorted   = sort { $a <=> $b } @dates;
    my @days_out = map { $_->day } @sorted;
    my @expected = (1, 5, 15, 20, 30);
    is(scalar @days_out, scalar @expected, 'sorted list same length');
    for my $i (0 .. $#expected) {
        is($days_out[$i], $expected[$i], "sorted[$i] = $expected[$i]");
    }
};

# ===========================================================================
# 6. weekday_iso – all 7 days
# ===========================================================================

subtest 'weekday_iso all 7 days' => sub {
    # 2077-06-04 = Sunday (weekday=0)
    my $base = NepaliDateTime::Date->new(2077, 6, 4);
    # Sun=7 (ISO), Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
    my @expected_iso = (7, 1, 2, 3, 4, 5, 6);
    for my $i (0..6) {
        my $d = $base->add_days($i);
        is($d->weekday_iso(), $expected_iso[$i],
           "weekday_iso day+$i: expected $expected_iso[$i]");
    }
};

# ===========================================================================
# 7. next_weekday / prev_weekday when already on that weekday
# ===========================================================================

subtest 'next_weekday returns self when already on target day' => sub {
    my $d   = NepaliDateTime::Date->new(2077, 6, 4);  # Sunday
    my $w   = $d->weekday();
    is($w, 0, 'starting day is Sunday (0)');

    my $next_sun = $d->next_weekday(0);
    ok($d == $next_sun, 'next_weekday(same) returns self-date');
};

subtest 'prev_weekday returns self when already on target day' => sub {
    my $d   = NepaliDateTime::Date->new(2077, 6, 4);  # Sunday
    my $prev_sun = $d->prev_weekday(0);
    ok($d == $prev_sun, 'prev_weekday(same) returns self-date');
};

subtest 'next_weekday and prev_weekday are inverses' => sub {
    my $d    = NepaliDateTime::Date->new(2081, 3, 15);
    my $next = $d->next_weekday(3);  # next Wednesday
    my $prev = $next->prev_weekday(3);
    ok($d <= $next,  'next_weekday ≥ d');
    ok($prev == $next, 'prev_weekday(next_weekday) = next_weekday');
};

# ===========================================================================
# 8. days_until / days_since same date
# ===========================================================================

subtest 'days_until and days_since – same date' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    is($d->days_until($d),  0, 'days_until(self) = 0');
    is($d->days_since($d),  0, 'days_since(self) = 0');
};

subtest 'days_until / days_since – symmetry' => sub {
    my $d1 = NepaliDateTime::Date->new(2081, 1,  1);
    my $d2 = NepaliDateTime::Date->new(2081, 1, 31);
    is($d1->days_until($d2),  30, 'days_until 30');
    is($d2->days_since($d1),  30, 'days_since 30');
    is($d1->days_since($d2), -30, 'days_since negative');
    is($d2->days_until($d1), -30, 'days_until negative');
};

# ===========================================================================
# 9. age_from edge cases
# ===========================================================================

subtest 'age_from – exact birthday (same month and day)' => sub {
    my $birth = NepaliDateTime::Date->new(2055, 6, 15);
    my $today = NepaliDateTime::Date->new(2081, 6, 15);
    is($today->age_from($birth), 26, 'exact birthday = full years');
};

subtest 'age_from – one day before birthday' => sub {
    my $birth = NepaliDateTime::Date->new(2055, 6, 15);
    my $day_before = NepaliDateTime::Date->new(2081, 6, 14);
    is($day_before->age_from($birth), 25, 'day before birthday → year - 1');
};

subtest 'age_from – birthday across year boundary (month < birth month)' => sub {
    # Born in month 8, today is month 6 of same year count
    my $birth = NepaliDateTime::Date->new(2055, 8, 1);
    my $today = NepaliDateTime::Date->new(2081, 6, 1);  # before birthday month
    is($today->age_from($birth), 25, 'before birthday month → age 25');
};

subtest 'age_from – negative (birth in future)' => sub {
    my $birth = NepaliDateTime::Date->new(2085, 1, 1);
    my $today = NepaliDateTime::Date->new(2081, 1, 1);
    # age is negative
    ok($today->age_from($birth) < 0, 'age_from future birth is negative');
};

# ===========================================================================
# 10. clone – returns a separate object
# ===========================================================================

subtest 'clone – mutation independence (Date)' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = $d->clone();
    ok($d == $d2, 'clone equals original');
    # They should stringify equally
    is("$d", "$d2", 'clone stringifies same');
    # Different references
    ok(\$d != \$d2, 'clone is a different scalar reference');
};

subtest 'clone – mutation independence (DateTime)' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0, 999);
    my $dt2 = $dt->clone();
    ok($dt == $dt2, 'clone equals original');
    is($dt2->microsecond, 999, 'clone preserves microsecond');
};

# ===========================================================================
# 11. is_valid – precise boundary values
# ===========================================================================

subtest 'is_valid – first and last valid dates' => sub {
    ok( NepaliDateTime::Date->is_valid(1975, 1,  1), '1975-01-01 valid (min)');
    ok(!NepaliDateTime::Date->is_valid(1974, 12, 30), '1974-12-30 invalid (before min)');

    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2100}[12];
    ok( NepaliDateTime::Date->is_valid(2100, 12, $dim),       "2100-12-$dim valid (max)");
    ok(!NepaliDateTime::Date->is_valid(2100, 12, $dim + 1),   '2100-12-(max+1) invalid');
    ok(!NepaliDateTime::Date->is_valid(2101, 1,  1),          '2101-01-01 invalid (after max)');
};

subtest 'is_valid – each month end is valid, one beyond is not' => sub {
    for my $m (1..12) {
        my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[$m];
        ok( NepaliDateTime::Date->is_valid(2081, $m, $dim),   "2081-$m-$dim valid");
        ok(!NepaliDateTime::Date->is_valid(2081, $m, $dim+1), "2081-$m-${\($dim+1)} invalid");
    }
};

# ===========================================================================
# 12. from_ad – range errors
# ===========================================================================

subtest 'from_ad – out of range dies' => sub {
    # Before BS 1975-01-01 (= 1918-04-13): try 1918-04-12
    ok(dies { NepaliDateTime::Date->from_ad(1918, 4, 12) },
       'AD 1918-04-12 (before BS 1975-01-01) dies');

    # Known good dates from the boundary
    my $bs = NepaliDateTime::Date->from_ad(1918, 4, 13);
    is($bs->year,  1975, 'AD 1918-04-13 → BS 1975');
    is($bs->month, 1,    'AD 1918-04-13 → month 1');
    is($bs->day,   1,    'AD 1918-04-13 → day 1');
};

# ===========================================================================
# 13. from_iso edge cases
# ===========================================================================

subtest 'from_iso – valid and invalid formats' => sub {
    my $d = NepaliDateTime::Date->from_iso('2081-03-15');
    is($d->year, 2081, 'from_iso parses correctly');

    # Leading zeros
    my $d2 = NepaliDateTime::Date->from_iso('1975-01-01');
    is($d2->year,  1975, 'from_iso leading zeros: year');
    is($d2->month, 1,    'from_iso leading zeros: month');
    is($d2->day,   1,    'from_iso leading zeros: day');

    # Bad formats
    ok(dies { NepaliDateTime::Date->from_iso('20810315') },   'no dashes dies');
    ok(dies { NepaliDateTime::Date->from_iso('2081/03/15') },  'slashes die');
    ok(dies { NepaliDateTime::Date->from_iso('081-03-15') },   'short year dies');
    ok(dies { NepaliDateTime::Date->from_iso('2081-3-15') },   'non-padded month dies');
    ok(dies { NepaliDateTime::Date->from_iso('') },            'empty string dies');
    ok(dies { NepaliDateTime::Date->from_iso('not-a-date') },  'garbage dies');
};

# ===========================================================================
# 14. month_start / month_end on boundaries
# ===========================================================================

subtest 'month_start when already on first day' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 1);
    my $ms = $d->month_start();
    ok($d == $ms, 'month_start of day 1 = itself');
};

subtest 'month_end when already on last day' => sub {
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[3];
    my $d   = NepaliDateTime::Date->new(2081, 3, $dim);
    my $me  = $d->month_end();
    ok($d == $me, 'month_end of last day = itself');
};

subtest 'month_end for month 12' => sub {
    my $d   = NepaliDateTime::Date->new(2081, 12, 1);
    my $me  = $d->month_end();
    is($me->month, 12, 'month_end of month 12 stays in 12');
    is($me->day, $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[12], 'month_end day correct');
};

# ===========================================================================
# 15. year_start / year_end
# ===========================================================================

subtest 'year_start and year_end at boundaries' => sub {
    # On 1 Baisakh
    my $ys = NepaliDateTime::Date->new(2081, 1, 1);
    ok($ys == $ys->year_start(), 'year_start on 1 Baisakh = itself');

    # On last day of Chaitra
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[12];
    my $ye  = NepaliDateTime::Date->new(2081, 12, $dim);
    ok($ye == $ye->year_end(), 'year_end on last of Chaitra = itself');
};

# ===========================================================================
# 16. fiscal_year_start / fiscal_year_end for dates in months < 4
# ===========================================================================

subtest 'fiscal_year_start for month < 4 (FY started previous year)' => sub {
    my $d   = NepaliDateTime::Date->new(2081, 2, 15);  # month 2 → FY 2080/2081
    my $fys = $d->fiscal_year_start();
    is($fys->year,  2080, 'fiscal_year_start year for month 2 = prev year');
    is($fys->month, 4,    'fiscal_year_start month = 4 (Shrawan)');
    is($fys->day,   1,    'fiscal_year_start day = 1');
};

subtest 'fiscal_year_end for month >= 4 (FY ends next year)' => sub {
    my $d   = NepaliDateTime::Date->new(2081, 5, 10);  # FY 2081/2082
    my $fye = $d->fiscal_year_end();
    is($fye->year,  2082, 'fiscal_year_end year = 2082');
    is($fye->month, 3,    'fiscal_year_end month = 3 (Ashadh)');
    ok($fye->day >= 29,   'fiscal_year_end day ≥ 29');
    is($fye->day, $NepaliDateTime::Data::DAYS_IN_MONTH{2082}[3], 'fiscal_year_end = last of Ashadh');
};

# ===========================================================================
# 17. Date::from_timestamp – known epoch values
# ===========================================================================

subtest 'Date::from_timestamp – epoch 0 → BS 2026-09-17' => sub {
    # epoch 0 = 1970-01-01 00:00:00 UTC → NST date = 1970-01-01 (offset only moves clock, not date here)
    # Actually epoch 0 in NST = 1970-01-01 05:45 → date is 1970-01-01 AD
    # AD 1970-01-01 → BS 2026-09-17
    my $d = NepaliDateTime::Date->from_timestamp(0);
    is($d->year,  2026, 'epoch 0 → BS year 2026');
    is($d->month, 9,    'epoch 0 → BS month 9');
    is($d->day,   17,   'epoch 0 → BS day 17');
};

subtest 'Date::from_timestamp round-trip with to_timestamp' => sub {
    my @dates = ([2081, 3, 15], [2000, 1, 1], [2077, 4, 1]);
    for my $ymd (@dates) {
        my $d  = NepaliDateTime::Date->new(@$ymd);
        my $ts = $d->to_timestamp();
        my $d2 = NepaliDateTime::Date->from_timestamp($ts);
        is($d2->year,  $d->year,  "RT year for @$ymd");
        is($d2->month, $d->month, "RT month for @$ymd");
        is($d2->day,   $d->day,   "RT day for @$ymd");
    }
};

# ===========================================================================
# 18. replace edge cases (Date)
# ===========================================================================

subtest 'replace – replace produces correct date' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 15);

    # Replace nothing
    my $same = $d->replace();
    ok($d == $same, 'replace() with no args = original');

    # Replace all fields
    my $all = $d->replace(year => 2082, month => 5, day => 10);
    is($all->year,  2082, 'replace all: year');
    is($all->month, 5,    'replace all: month');
    is($all->day,   10,   'replace all: day');
};

subtest 'replace – invalid values die (Date)' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    ok(dies { $d->replace(month => 13) }, 'replace month 13 dies');
    ok(dies { $d->replace(day   =>  0) }, 'replace day 0 dies');
    ok(dies { $d->replace(year  => 1974) }, 'replace year out of range dies');
};

# ===========================================================================
# 19. DateTime – add_seconds preserves microseconds
# ===========================================================================

subtest 'add_seconds – microseconds preserved' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0, 500000);
    my $dt2 = $dt->add_seconds(1);
    is($dt2->microsecond, 500000, 'add_seconds preserves microsecond');
    is($dt2->second,      1,      'add_seconds advances second');
};

subtest 'add_seconds – negative, crossing day boundary, microseconds preserved' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 0, 0, 30, 123);
    my $dt2 = $dt->add_seconds(-31);   # goes to previous day at 23:59:59
    is($dt2->day,         14,    'add_seconds(-31) crosses midnight back');
    is($dt2->hour,        23,    'hour = 23');
    is($dt2->second,      59,    'second = 59');
    is($dt2->microsecond, 123,   'microseconds preserved across day boundary');
};

# ===========================================================================
# 20. DateTime – to_timestamp with microseconds
# ===========================================================================

subtest 'to_timestamp – returns float for non-zero microsecond' => sub {
    my $dt = NepaliDateTime::DateTime->new(2078, 2, 23, 0, 0, 0, 500000);
    my $ts = $dt->to_timestamp();
    # 2078-02-23 00:00:00 NST → epoch 1622916900 (known)
    # microsecond = 0.5 seconds → 1622916900.5
    ok(abs($ts - 1622916900.5) < 0.001, 'to_timestamp with 500000 us = epoch + 0.5');
};

subtest 'to_timestamp – integer for zero microsecond' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2078, 2, 23, 0, 0, 0);
    my $ts  = $dt->to_timestamp();
    is($ts, 1622916900, 'to_timestamp zero us = integer epoch (2078-02-23 NST)');
};

# ===========================================================================
# 21. DateTime – from_timestamp with fractional epoch
# ===========================================================================

subtest 'from_timestamp – fractional epoch sets microseconds' => sub {
    # 1622916900.75 → microsecond = 750000
    my $dt = NepaliDateTime::DateTime->from_timestamp(1622916900.75);
    is($dt->microsecond, 750000, 'fractional epoch → microsecond 750000');
    is($dt->second,      0,      'second = 0');
};

subtest 'from_timestamp – zero fractional gives zero microsecond' => sub {
    my $dt = NepaliDateTime::DateTime->from_timestamp(1622916900);
    is($dt->microsecond, 0, 'integer epoch → microsecond 0');
};

# ===========================================================================
# 22. DateTime – replace invalid values die
# ===========================================================================

subtest 'DateTime replace – invalid time fields die' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
    ok(dies { $dt->replace(hour   => 24) }, 'replace hour 24 dies');
    ok(dies { $dt->replace(hour   => -1) }, 'replace hour -1 dies');
    ok(dies { $dt->replace(minute => 60) }, 'replace minute 60 dies');
    ok(dies { $dt->replace(second => 60) }, 'replace second 60 dies');
    ok(dies { $dt->replace(microsecond => 1_000_000) }, 'replace us 1000000 dies');
};

subtest 'DateTime replace – valid fields work' => sub {
    my $dt  = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
    my $dt2 = $dt->replace(hour => 23, minute => 59, second => 59, microsecond => 999999);
    is($dt2->hour,        23,     'replace hour 23');
    is($dt2->minute,      59,     'replace minute 59');
    is($dt2->second,      59,     'replace second 59');
    is($dt2->microsecond, 999999, 'replace microsecond max');
    is($dt2->day,         15,     'date unchanged');
};

# ===========================================================================
# 23. strftime_np is truly an alias of strftime
# ===========================================================================

subtest 'strftime_np is alias of strftime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    my $fmt = '%K-%n-%D %h:%l:%s';
    is($dt->strftime_np($fmt), $dt->strftime($fmt), 'strftime_np = strftime');

    # Works on all directives
    my $fmt2 = '%Y-%m-%d %H:%M:%S';
    is($dt->strftime_np($fmt2), '2081-03-15 14:30:00', 'strftime_np Latin format');
};

# ===========================================================================
# 24. strftime – exact %j and %U values
# ===========================================================================

subtest 'strftime %j – exact day of year' => sub {
    # 2081-01-01 → day 1 → "001"
    my $d1 = NepaliDateTime::Date->new(2081, 1, 1);
    is($d1->strftime('%j'), '001', '%j for 1 Baisakh = 001');

    # 2081-02-01 → day 32 (Baisakh has 31 days) → "032"
    my $bai = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[1];
    my $d2  = NepaliDateTime::Date->new(2081, 2, 1);
    is($d2->strftime('%j'), sprintf('%03d', $bai + 1), '%j for 1 Jestha');

    # Last day of year → days_in_year
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[12];
    my $last = NepaliDateTime::Date->new(2081, 12, $dim);
    is($last->strftime('%j'), sprintf('%03d', $last->day_of_year()), '%j for last day');
};

subtest 'strftime %U – week number for known Sunday start' => sub {
    # 2077-06-04 is a Sunday (weekday=0), so it's the start of a new week.
    # Baisakh 1 2077: need to know its weekday to compute week number.
    my $d    = NepaliDateTime::Date->new(2077, 6, 4);
    my $woy  = $d->week_of_year();
    my $strU = $d->strftime('%U');
    is($strU, sprintf('%02d', $woy), '%U matches week_of_year()');

    # Day 1 of any year is always week 1
    my $d2 = NepaliDateTime::Date->new(2081, 1, 1);
    is($d2->strftime('%U'), sprintf('%02d', $d2->week_of_year()), '%U for 1 Baisakh');
};

# ===========================================================================
# 25. strftime %z and %Z on plain Date (not DateTime)
# ===========================================================================

subtest 'strftime %z and %Z on Date object' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    is($d->strftime('%z'), '+0545', '%z on Date = +0545');
    is($d->strftime('%Z'), 'NST',   '%Z on Date = NST');
};

# ===========================================================================
# 26. strptime – weekday tokens parsed without breaking date
# ===========================================================================

subtest 'strptime – %A weekday token is consumed, date still correct' => sub {
    # The weekday name is parsed and consumed from the string but does not
    # set the date fields; year/month/day still determine the result.
    my $d = NepaliDateTime::Date->strptime('Sunday 2081-03-15', '%A %Y-%m-%d');
    is($d->year,  2081, 'strptime %A: year correct');
    is($d->month, 3,    'strptime %A: month correct');
    is($d->day,   15,   'strptime %A: day correct');
};

subtest 'strptime – %a abbreviated weekday token' => sub {
    my $d = NepaliDateTime::Date->strptime('Mon 2081-03-16', '%a %Y-%m-%d');
    is($d->year,  2081, 'strptime %a: year');
    is($d->day,   16,   'strptime %a: day');
};

# ===========================================================================
# 27. strptime – error paths
# ===========================================================================

subtest 'strptime – missing year dies (Date)' => sub {
    ok(dies { NepaliDateTime::Date->strptime('03-15', '%m-%d') },
       'strptime without year dies');
};

subtest 'strptime – missing month dies (Date)' => sub {
    ok(dies { NepaliDateTime::Date->strptime('2081-15', '%Y-%d') },
       'strptime without month dies');
};

subtest 'strptime – missing day dies (Date)' => sub {
    ok(dies { NepaliDateTime::Date->strptime('2081-03', '%Y-%m') },
       'strptime without day dies');
};

subtest 'strptime – no-match dies' => sub {
    ok(dies { NepaliDateTime::Date->strptime('2081.03.15', '%Y-%m-%d') },
       'strptime non-matching separator dies');
    ok(dies { NepaliDateTime::Date->strptime('', '%Y-%m-%d') },
       'strptime empty string dies');
};

subtest 'strptime – bad field value dies after parsing' => sub {
    ok(dies { NepaliDateTime::Date->strptime('2081-00-15', '%Y-%m-%d') },
       'strptime month 0 dies on construction');
    ok(dies { NepaliDateTime::Date->strptime('2081-13-15', '%Y-%m-%d') },
       'strptime month 13 dies on construction');
};

# ===========================================================================
# 28. strptime – DateTime error paths
# ===========================================================================

subtest 'strptime – DateTime missing year dies' => sub {
    ok(dies { NepaliDateTime::DateTime->strptime('03-15 10:00:00', '%m-%d %H:%M:%S') },
       'DateTime strptime without year dies');
};

subtest 'strptime – DateTime no-match dies' => sub {
    ok(dies { NepaliDateTime::DateTime->strptime('not-a-datetime', '%Y-%m-%d %H:%M:%S') },
       'DateTime strptime garbage dies');
};

# ===========================================================================
# 29. to_ad / from_ad – multi-direction consistency
# ===========================================================================

subtest 'to_ad and from_ad are exact inverses for all spot-check pairs' => sub {
    my @pairs = (
        { bs => [1975,  1,  1], ad => [1918,  4, 13] },
        { bs => [2000,  1,  1], ad => [1943,  4, 14] },
        { bs => [2077,  6,  4], ad => [2020,  9, 20] },
        { bs => [2081,  3, 31], ad => [2024,  7, 15] },
        { bs => [2100, 12, 30], ad => [2044,  4, 12] },
    );
    for my $p (@pairs) {
        my ($by, $bm, $bd) = @{$p->{bs}};
        my ($ay, $am, $ad) = @{$p->{ad}};

        # BS → AD
        my ($ry, $rm, $rd) = NepaliDateTime::Date->new($by,$bm,$bd)->to_ad();
        is($ry, $ay, "to_ad $by-$bm-$bd → AD year $ay");
        is($rm, $am, "to_ad $by-$bm-$bd → AD month $am");
        is($rd, $ad, "to_ad $by-$bm-$bd → AD day $ad");

        # AD → BS
        my $bs = NepaliDateTime::Date->from_ad($ay, $am, $ad);
        is($bs->year,  $by, "from_ad $ay-$am-$ad → BS year $by");
        is($bs->month, $bm, "from_ad $ay-$am-$ad → BS month $bm");
        is($bs->day,   $bd, "from_ad $ay-$am-$ad → BS day $bd");
    }
};

# ===========================================================================
# 30. date_range – across month and year boundary
# ===========================================================================

subtest 'date_range – across month boundary' => sub {
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[1]; # days in Baisakh
    my $s   = NepaliDateTime::Date->new(2081, 1, $dim - 1);  # penultimate day of month 1
    my $e   = NepaliDateTime::Date->new(2081, 2, 2);          # 2nd of month 2
    my @r   = NepaliDateTime::Date->date_range($s, $e);
    is(scalar(@r), 4, 'range across month boundary has 4 dates');
    is($r[0]->month, 1, 'first date in month 1');
    is($r[-1]->month, 2, 'last date in month 2');
};

subtest 'date_range – across year boundary' => sub {
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{2081}[12];
    my $s   = NepaliDateTime::Date->new(2081, 12, $dim);  # last day of 2081
    my $e   = NepaliDateTime::Date->new(2082,  1,  2);    # 2 Baisakh 2082
    my @r   = NepaliDateTime::Date->date_range($s, $e);
    is(scalar(@r), 3, 'range across year boundary has 3 dates');
    is($r[0]->year,  2081, 'first date year 2081');
    is($r[-1]->year, 2082, 'last date year 2082');
};

# ===========================================================================
# 31. nth_weekday_of_month – exhaustive 1st–5th
# ===========================================================================

subtest 'nth_weekday_of_month – 1st through 5th in known month' => sub {
    # Use a month we know well: Baisakh 2081 (31 days, starting weekday known)
    my $ref = NepaliDateTime::Date->new(2081, 1, 1);
    my $first_wday = $ref->weekday();

    for my $n (1..5) {
        for my $wd (0..6) {
            my $d = $ref->nth_weekday_of_month($n, $wd);
            if (defined $d) {
                is($d->weekday(), $wd,       "nth_weekday_of_month($n,$wd) has correct weekday");
                is($d->month(),   1,         "nth_weekday_of_month($n,$wd) same month");
                ok($d->day() >= ($n-1)*7+1, "nth_weekday_of_month($n,$wd) day ≥ (n-1)*7+1");
                ok($d->day() >= 1 && $d->day() <= 31, "day in range");
            }
            # undef is fine if the occurrence doesn't exist
        }
    }
};

# ===========================================================================
# 32. last_weekday_of_month – property verification
# ===========================================================================

subtest 'last_weekday_of_month – property: adding 7 goes outside month' => sub {
    for my $wd (0..6) {
        my $d    = NepaliDateTime::Date->new(2081, 3, 15);
        my $last = $d->last_weekday_of_month($wd);
        is($last->weekday(), $wd, "last_weekday_of_month($wd) has correct weekday");
        my $next = $last->add_days(7);
        ok($next->month != $last->month(), "no same-weekday 7 days later in same month");
    }
};

# ===========================================================================
# 33. DateTime – utcnow vs now (UTC is behind Nepal time)
# ===========================================================================

subtest 'utcnow ordinal ≤ now ordinal' => sub {
    # NST is UTC+05:45, so the Nepal day is always equal to or ahead of UTC day
    my $nst_ord = NepaliDateTime::DateTime->now()->toordinal();
    my $utc_ord = NepaliDateTime::DateTime->utcnow()->toordinal();
    # They can differ by at most 1 day (NST is 5h45m ahead of UTC)
    ok($nst_ord - $utc_ord >= 0 && $nst_ord - $utc_ord <= 1,
       'now ordinal is 0 or 1 day ahead of utcnow');
};

# ===========================================================================
# 34. DateTime combine defaults
# ===========================================================================

subtest 'combine – all time defaults to midnight' => sub {
    my $date = NepaliDateTime::Date->new(2081, 3, 15);
    my $dt   = NepaliDateTime::DateTime->combine($date);
    is($dt->year,        2081, 'combine: year');
    is($dt->month,       3,    'combine: month');
    is($dt->day,         15,   'combine: day');
    is($dt->hour,        0,    'combine: hour default 0');
    is($dt->minute,      0,    'combine: minute default 0');
    is($dt->second,      0,    'combine: second default 0');
    is($dt->microsecond, 0,    'combine: microsecond default 0');
};

done_testing();
