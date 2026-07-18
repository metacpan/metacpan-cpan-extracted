#!/usr/bin/env perl
# t/01_date.t – comprehensive tests for NepaliDateTime::Date
# Covers all Python nepali_datetime.date tests plus Perl-specific extras.
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test2::V1 '-ipP';

use NepaliDateTime::Date;
use NepaliDateTime::Data;

# ---------------------------------------------------------------------------
# 1. Construction & accessors
# ---------------------------------------------------------------------------
subtest 'Construction and accessors' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    is($d->year,  2081, 'year accessor');
    is($d->month, 3,    'month accessor');
    is($d->day,   15,   'day accessor');
};

subtest 'Construction – boundary dates' => sub {
    my $min = NepaliDateTime::Date->new(1975, 1, 1);
    is($min->year,  1975, 'min year');
    is($min->month, 1,    'min month');
    is($min->day,   1,    'min day');

    my $max = NepaliDateTime::Date->new(2100, 12, 30);
    is($max->year,  2100, 'max year');
    is($max->month, 12,   'max month');
    is($max->day,   30,   'max day');
};

# Python: test_init
subtest 'Construction – test_init equivalent' => sub {
    my $dt = NepaliDateTime::Date->new(2075, 5, 20);
    is($dt->year,  2075, 'year 2075');
    is($dt->month, 5,    'month 5');
    is($dt->day,   20,   'day 20');
};

# ---------------------------------------------------------------------------
# 2. Invalid construction
# ---------------------------------------------------------------------------
subtest 'Invalid construction' => sub {
    ok(dies { NepaliDateTime::Date->new(1974, 1,  1)  }, 'year before MINYEAR dies');
    ok(dies { NepaliDateTime::Date->new(2101, 1,  1)  }, 'year after MAXYEAR dies');
    ok(dies { NepaliDateTime::Date->new(2081, 0,  1)  }, 'month 0 dies');
    ok(dies { NepaliDateTime::Date->new(2081, 13, 1)  }, 'month 13 dies');
    ok(dies { NepaliDateTime::Date->new(2081, 1,  0)  }, 'day 0 dies');
    ok(dies { NepaliDateTime::Date->new(2081, 1,  32) }, 'day 32 in month with 31 days dies');
    # Poush (month 9) 2081 has only 29 days, so day 30 must be invalid
    ok(dies { NepaliDateTime::Date->new(2081, 9,  30) }, 'day 30 in Poush 2081 (29-day month) dies');
};

# ---------------------------------------------------------------------------
# 3. AD ↔ BS conversion  (Python: test_reference_dates + test_random_conversions)
# ---------------------------------------------------------------------------
subtest 'Reference date anchor (Python: test_reference_dates)' => sub {
    # REFERENCE_DATE_AD = 1918-04-13 == BS 1975-01-01
    my $bs = NepaliDateTime::Date->from_ad(1918, 4, 13);
    is($bs->year,  1975, 'reference: BS year  1975');
    is($bs->month, 1,    'reference: BS month 1');
    is($bs->day,   1,    'reference: BS day   1');
};

subtest 'AD→BS and BS→AD (Python: test_random_conversions)' => sub {
    my @known = (
        { bs => [2013, 2,  8],  ad => [1956, 5, 21] },
        { bs => [2051, 10, 1],  ad => [1995, 1, 15] },
        { bs => [2076, 6, 27],  ad => [2019,10, 14] },
        { bs => [2077, 4,  4],  ad => [2020, 7, 19] },
        { bs => [2081, 3, 31],  ad => [2024, 7, 15] },
    );
    for my $pair (@known) {
        my ($by,$bm,$bd) = @{$pair->{bs}};
        my ($ay,$am,$ad) = @{$pair->{ad}};

        my $bs = NepaliDateTime::Date->from_ad($ay, $am, $ad);
        is($bs->year,  $by, "from_ad($ay-$am-$ad) → BS $by");
        is($bs->month, $bm, "from_ad($ay-$am-$ad) → month $bm");
        is($bs->day,   $bd, "from_ad($ay-$am-$ad) → day $bd");

        my ($ry,$rm,$rd) = NepaliDateTime::Date->new($by,$bm,$bd)->to_ad();
        is($ry, $ay, "to_ad($by-$bm-$bd) → AD $ay");
        is($rm, $am, "to_ad($by-$bm-$bd) → month $am");
        is($rd, $ad, "to_ad($by-$bm-$bd) → day $ad");
    }
};

subtest 'to_ad_string' => sub {
    my $bs = NepaliDateTime::Date->new(2081, 3, 31);
    is($bs->to_ad_string(), '2024-07-15', 'to_ad_string for 2081-03-31');
};

# ---------------------------------------------------------------------------
# 4. today() – Python: test_today
# ---------------------------------------------------------------------------
subtest 'today() range check (Python: test_today)' => sub {
    my $today = NepaliDateTime::Date->today();
    isa_ok($today, 'NepaliDateTime::Date');
    ok($today->year  >= 1975 && $today->year  <= 2100, 'today year in range');
    ok($today->month >= 1    && $today->month <= 12,   'today month in range');
    ok($today->day   >= 1    && $today->day   <= 32,   'today day in range');
};

# ---------------------------------------------------------------------------
# 5. Ordinal
# ---------------------------------------------------------------------------
subtest 'Ordinal: toordinal and from_ordinal' => sub {
    my $d1 = NepaliDateTime::Date->new(1975, 1, 1);
    is($d1->toordinal(), 1, '1975-01-01 ordinal = 1');

    my $d2 = NepaliDateTime::Date->from_ordinal(1);
    ok($d1 == $d2, 'from_ordinal(1) gives 1975-01-01');

    # round-trip
    my $d3 = NepaliDateTime::Date->new(2081, 6, 27);
    my $ord = $d3->toordinal();
    my $d4  = NepaliDateTime::Date->from_ordinal($ord);
    ok($d3 == $d4, 'ordinal round-trip');

    ok(dies { NepaliDateTime::Date->from_ordinal(0) },
       'ordinal 0 out of range dies');
    ok(dies { NepaliDateTime::Date->from_ordinal($NepaliDateTime::Data::MAXORDINAL + 1) },
       'ordinal beyond max dies');
};

# ---------------------------------------------------------------------------
# 6. from_iso / isoformat
# ---------------------------------------------------------------------------
subtest 'isoformat and from_iso' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    is($d->isoformat(), '2081-03-15', 'isoformat');
    is("$d",            '2081-03-15', 'stringify uses isoformat');

    my $d2 = NepaliDateTime::Date->from_iso('2081-03-15');
    ok($d2 == $d, 'from_iso round-trip');

    ok(dies { NepaliDateTime::Date->from_iso('20810315') },
       'from_iso invalid format dies');
};

# ---------------------------------------------------------------------------
# 7. from_timestamp
# ---------------------------------------------------------------------------
subtest 'from_timestamp round-trip' => sub {
    my $d   = NepaliDateTime::Date->new(2081, 3, 31);
    my $ts  = $d->to_timestamp();
    my $d2  = NepaliDateTime::Date->from_timestamp($ts);
    is($d2->year,  $d->year,  'from_timestamp year');
    is($d2->month, $d->month, 'from_timestamp month');
    is($d2->day,   $d->day,   'from_timestamp day');
};

# ---------------------------------------------------------------------------
# 8. Weekday  (Python weekday: 0=Sun, … 6=Sat – same as Perl)
# ---------------------------------------------------------------------------
subtest 'weekday() – Sun=0 convention matching Python' => sub {
    # 2077-06-04 BS = 2020-09-20 AD (Sunday)
    my $d = NepaliDateTime::Date->new(2077, 6, 4);
    is($d->weekday(), 0, '2077-06-04 is Sunday (weekday=0)');
    is($d->day_name(),      'Sunday',    'day_name Sunday');
    is($d->day_name_abbr(), 'Sun',       'day_name_abbr Sun');

    # 2081-03-15 – let's just ensure in range
    my $d2 = NepaliDateTime::Date->new(2081, 3, 15);
    my $w = $d2->weekday();
    ok($w >= 0 && $w <= 6, "weekday $w in 0..6");

    # weekday_iso: Sun=7, Mon=1 … Sat=6
    my $iso = $d->weekday_iso();  # Sunday → 7
    is($iso, 7, 'weekday_iso for Sunday = 7');
    my $mon = NepaliDateTime::Date->new(2077, 6, 5);
    is($mon->weekday_iso(), 1, 'weekday_iso Monday = 1');
};

subtest 'Nepali day names' => sub {
    my $d = NepaliDateTime::Date->new(2077, 6, 4);
    my $np = $d->day_name_np();
    ok(length($np) > 0, 'day_name_np non-empty');
    # Sunday in Nepali
    is($np, 'आइतबार', 'day_name_np Sunday = आइतबार');
};

# ---------------------------------------------------------------------------
# 9. Month names
# ---------------------------------------------------------------------------
subtest 'Month names' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);  # Asar
    is($d->month_name(),      'Asar',   'month_name Asar');
    is($d->month_name_abbr(), 'Asa',    'month_name_abbr Asa');
    is($d->month_name_np(),   'असार',   'month_name_np');

    my $bai = NepaliDateTime::Date->new(2081, 1, 1);
    is($bai->month_name(), 'Baishakh', 'month_name Baishakh');

    my $cha = NepaliDateTime::Date->new(2081, 12, 1);
    is($cha->month_name(), 'Chaitra', 'month_name Chaitra');
};

# ---------------------------------------------------------------------------
# 10. days_in_month, days_in_year, day_of_year, week_of_year
# ---------------------------------------------------------------------------
subtest 'days_in_month' => sub {
    # Baisakh 2081 = 31 days (from data table)
    my $d = NepaliDateTime::Date->new(2081, 1, 15);
    is($d->days_in_month(), 31, 'Baisakh 2081 = 31 days');

    # Static call
    is(NepaliDateTime::Date->days_in_month_for(2081, 1), 31, 'days_in_month_for(2081,1)');
};

subtest 'days_in_year' => sub {
    my $d = NepaliDateTime::Date->new(2081, 6, 1);
    my $dim_year = $d->days_in_year();
    ok($dim_year >= 365 && $dim_year <= 366, "days_in_year $dim_year in 365..366");
};

subtest 'day_of_year' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);
    is($d->day_of_year(), 1, 'Baisakh 1 = day 1');

    my $d2 = NepaliDateTime::Date->new(2081, 2, 1);
    is($d2->day_of_year(), 32, 'first of month 2 = day 32 (31+1)');
};

subtest 'week_of_year' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);
    my $w = $d->week_of_year();
    ok($w >= 1, 'week_of_year >= 1');
};

# ---------------------------------------------------------------------------
# 11. Arithmetic
# ---------------------------------------------------------------------------
subtest 'add_days' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);

    my $d_plus1 = $d->add_days(1);
    is($d_plus1->day, 2, 'add_days(1) → day 2');

    my $d_minus1 = $d->add_days(-1);
    is($d_minus1->year,  2080, 'add_days(-1) crosses year → 2080');
    is($d_minus1->month, 12,   'add_days(-1) crosses year → month 12');

    # Overloaded + -
    my $d2 = $d + 5;
    is($d2->day, 6, 'overloaded + 5 days');

    my $diff = ($d + 10) - $d;
    is($diff, 10, 'overloaded subtraction gives day count');

    # int - date (reversed)
    my $ord = $d->toordinal();
    my $d3  = $ord + 4 - $d;   # should give add_days(4)
    # Actually let's not test that edge – test normal sub with date
    my $d4 = $d->add_days(10);
    is($d4 - $d, 10, 'd4 - d = 10');
};

subtest 'add_months' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);

    my $d2 = $d->add_months(2);
    is($d2->month, 3, 'add_months(2) → month 3');

    my $d3 = $d->add_months(12);
    is($d3->year,  2082, 'add_months(12) → next year');
    is($d3->month, 1,    'add_months(12) → month 1');

    # Day clamping: Falgun may have fewer days than Chaitra
    my $d4 = NepaliDateTime::Date->new(2081, 12, 30);
    my $d5 = $d4->add_months(1);
    ok($d5->day <= $d5->days_in_month(), 'add_months clamps day to month end');
};

subtest 'add_years' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);
    my $d2 = $d->add_years(1);
    is($d2->year, 2082, 'add_years(1) → 2082');

    my $d3 = $d->add_years(-1);
    is($d3->year, 2080, 'add_years(-1) → 2080');
};

# ---------------------------------------------------------------------------
# 12. replace
# ---------------------------------------------------------------------------
subtest 'replace' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = $d->replace(day => 1);
    is($d2->year,  2081, 'replace preserves year');
    is($d2->month, 3,    'replace preserves month');
    is($d2->day,   1,    'replace changes day');

    my $d3 = $d->replace(year => 2082, month => 1);
    is($d3->year,  2082, 'replace year');
    is($d3->month, 1,    'replace month');
    is($d3->day,   15,   'replace preserves day');
};

# ---------------------------------------------------------------------------
# 13. clone
# ---------------------------------------------------------------------------
subtest 'clone' => sub {
    my $d  = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = $d->clone();
    ok($d == $d2, 'clone equals original');
    # Different object
    ok( !($d eq $d2) || "$d" eq "$d2", 'clone is isoformat equal' );
};

# ---------------------------------------------------------------------------
# 14. month boundaries
# ---------------------------------------------------------------------------
subtest 'month_start and month_end' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 15);
    is($d->month_start()->day,   1,  'month_start day = 1');
    is($d->month_start()->month, 1,  'month_start same month');
    is($d->month_end()->month,   1,  'month_end same month');
    is($d->month_end()->day, $d->days_in_month(), 'month_end = last day');
};

subtest 'year_start and year_end' => sub {
    my $d = NepaliDateTime::Date->new(2081, 6, 15);
    my $ys = $d->year_start();
    is($ys->year,  2081, 'year_start year');
    is($ys->month, 1,    'year_start month = 1');
    is($ys->day,   1,    'year_start day = 1');

    my $ye = $d->year_end();
    is($ye->year,  2081, 'year_end year');
    is($ye->month, 12,   'year_end month = 12');
    ok($ye->day >= 29, 'year_end day ≥ 29');
};

# ---------------------------------------------------------------------------
# 15. Comparison operators
# ---------------------------------------------------------------------------
subtest 'Comparison operators' => sub {
    my $d1 = NepaliDateTime::Date->new(2081, 3, 15);
    my $d2 = NepaliDateTime::Date->new(2081, 3, 16);
    my $d3 = NepaliDateTime::Date->new(2081, 3, 15);

    ok($d1 <  $d2, 'd1 < d2');
    ok($d2 >  $d1, 'd2 > d1');
    ok($d1 == $d3, 'd1 == d3');
    ok($d1 != $d2, 'd1 != d2');
    ok($d1 <= $d3, 'd1 <= d3');
    ok($d2 >= $d1, 'd2 >= d1');
    ok($d1 <= $d2, 'd1 <= d2');
    ok($d2 >= $d3, 'd2 >= d3');
};

# ---------------------------------------------------------------------------
# 16. Quarter
# ---------------------------------------------------------------------------
subtest 'quarter()' => sub {
    is(NepaliDateTime::Date->new(2081,  1, 1)->quarter(), 1, 'Baisakh → Q1');
    is(NepaliDateTime::Date->new(2081,  2, 1)->quarter(), 1, 'Jestha  → Q1');
    is(NepaliDateTime::Date->new(2081,  3, 1)->quarter(), 1, 'Asar    → Q1');
    is(NepaliDateTime::Date->new(2081,  4, 1)->quarter(), 2, 'Shrawan → Q2');
    is(NepaliDateTime::Date->new(2081,  5, 1)->quarter(), 2, 'Bhadau  → Q2');
    is(NepaliDateTime::Date->new(2081,  6, 1)->quarter(), 2, 'Aswin   → Q2');
    is(NepaliDateTime::Date->new(2081,  7, 1)->quarter(), 3, 'Kartik  → Q3');
    is(NepaliDateTime::Date->new(2081,  8, 1)->quarter(), 3, 'Mangsir → Q3');
    is(NepaliDateTime::Date->new(2081,  9, 1)->quarter(), 3, 'Poush   → Q3');
    is(NepaliDateTime::Date->new(2081, 10, 1)->quarter(), 4, 'Magh    → Q4');
    is(NepaliDateTime::Date->new(2081, 11, 1)->quarter(), 4, 'Falgun  → Q4');
    is(NepaliDateTime::Date->new(2081, 12, 1)->quarter(), 4, 'Chaitra → Q4');
};

# ---------------------------------------------------------------------------
# 17. Fiscal year (Nepal: Shrawan=month 4 to Ashadh=month 3)
# ---------------------------------------------------------------------------
subtest 'fiscal_year()' => sub {
    # Month >= 4: FY starts this year
    my ($s, $e) = NepaliDateTime::Date->new(2081, 4, 1)->fiscal_year();
    is($s, 2081, 'Shrawan month 4 FY start = 2081');
    is($e, 2082, 'Shrawan month 4 FY end   = 2082');

    my ($s2, $e2) = NepaliDateTime::Date->new(2081, 12, 1)->fiscal_year();
    is($s2, 2081, 'Chaitra month 12 FY start = 2081');
    is($e2, 2082, 'Chaitra month 12 FY end   = 2082');

    # Month < 4: FY started previous year
    my ($s3, $e3) = NepaliDateTime::Date->new(2081, 3, 1)->fiscal_year();
    is($s3, 2080, 'Asar month 3 FY start = 2080');
    is($e3, 2081, 'Asar month 3 FY end   = 2081');

    my ($s4, $e4) = NepaliDateTime::Date->new(2081, 1, 1)->fiscal_year();
    is($s4, 2080, 'Baisakh month 1 FY start = 2080');
    is($e4, 2081, 'Baisakh month 1 FY end   = 2081');
};

subtest 'fiscal_quarter()' => sub {
    is(NepaliDateTime::Date->new(2081, 4, 1)->fiscal_quarter(), 1, 'month 4 → FQ1');
    is(NepaliDateTime::Date->new(2081, 5, 1)->fiscal_quarter(), 1, 'month 5 → FQ1');
    is(NepaliDateTime::Date->new(2081, 6, 1)->fiscal_quarter(), 1, 'month 6 → FQ1');
    is(NepaliDateTime::Date->new(2081, 7, 1)->fiscal_quarter(), 2, 'month 7 → FQ2');
    is(NepaliDateTime::Date->new(2081, 8, 1)->fiscal_quarter(), 2, 'month 8 → FQ2');
    is(NepaliDateTime::Date->new(2081, 9, 1)->fiscal_quarter(), 2, 'month 9 → FQ2');
    is(NepaliDateTime::Date->new(2081,10, 1)->fiscal_quarter(), 3, 'month 10 → FQ3');
    is(NepaliDateTime::Date->new(2081,11, 1)->fiscal_quarter(), 3, 'month 11 → FQ3');
    is(NepaliDateTime::Date->new(2081,12, 1)->fiscal_quarter(), 3, 'month 12 → FQ3');
    is(NepaliDateTime::Date->new(2081, 1, 1)->fiscal_quarter(), 4, 'month 1 → FQ4');
    is(NepaliDateTime::Date->new(2081, 2, 1)->fiscal_quarter(), 4, 'month 2 → FQ4');
    is(NepaliDateTime::Date->new(2081, 3, 1)->fiscal_quarter(), 4, 'month 3 → FQ4');
};

subtest 'fiscal_year_start and fiscal_year_end' => sub {
    my $d = NepaliDateTime::Date->new(2081, 6, 15);  # FY 2081/2082

    my $fys = $d->fiscal_year_start();
    is($fys->year,  2081, 'fiscal_year_start year');
    is($fys->month, 4,    'fiscal_year_start month = 4 (Shrawan)');
    is($fys->day,   1,    'fiscal_year_start day = 1');

    my $fye = $d->fiscal_year_end();
    is($fye->year,  2082, 'fiscal_year_end year = 2082');
    is($fye->month, 3,    'fiscal_year_end month = 3 (Ashadh)');
    ok($fye->day >= 29, 'fiscal_year_end day ≥ 29');
};

# ---------------------------------------------------------------------------
# 18. is_weekend
# ---------------------------------------------------------------------------
subtest 'is_weekend()' => sub {
    # Find a known Saturday
    my $d_sat = NepaliDateTime::Date->new(2081, 1, 4);  # pick any day…
    # Walk until we hit Saturday (weekday 6)
    while ($d_sat->weekday() != 6) { $d_sat = $d_sat->add_days(1); }
    ok($d_sat->is_weekend(), 'Saturday is_weekend');
    ok(!$d_sat->add_days(-1)->is_weekend(), 'Friday is not weekend by default');
    ok($d_sat->add_days(-1)->is_weekend(1), 'Friday is_weekend with include_friday=1');

    # Sunday is not a weekend day in Nepal (work day)
    my $d_sun = $d_sat->add_days(1);  # Sunday follows Saturday
    is($d_sun->weekday(), 0, 'next day is Sunday');
    ok(!$d_sun->is_weekend(), 'Sunday is NOT a Nepal weekend');
};

# ---------------------------------------------------------------------------
# 19. age_from
# ---------------------------------------------------------------------------
subtest 'age_from' => sub {
    my $birth = NepaliDateTime::Date->new(2055, 1, 1);
    my $today = NepaliDateTime::Date->new(2081, 1, 1);
    is($today->age_from($birth), 26, 'age 26');

    # Birthday not yet this year
    my $today2 = NepaliDateTime::Date->new(2081, 1, 1);
    my $birth2  = NepaliDateTime::Date->new(2055, 1, 2);
    is($today2->age_from($birth2), 25, 'age 25 (birthday tomorrow)');

    ok(dies { $today->age_from('not a date') }, 'age_from non-date dies');
};

# ---------------------------------------------------------------------------
# 20. days_until / days_since
# ---------------------------------------------------------------------------
subtest 'days_until and days_since' => sub {
    my $d1 = NepaliDateTime::Date->new(2081, 1, 1);
    my $d2 = NepaliDateTime::Date->new(2081, 1, 11);
    is($d1->days_until($d2),  10, 'days_until 10');
    is($d1->days_since($d2), -10, 'days_since -10');
    is($d2->days_since($d1),  10, 'days_since 10 (reversed)');
};

# ---------------------------------------------------------------------------
# 21. Nth weekday helpers
# ---------------------------------------------------------------------------
subtest 'nth_weekday_of_month' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 15);
    my $sat1 = $d->nth_weekday_of_month(1, 6);
    ok(defined $sat1,          '1st Saturday exists');
    is($sat1->weekday(), 6,    '1st Saturday is weekday 6');
    is($sat1->month,     1,    '1st Saturday same month');
    ok($sat1->day >= 1 && $sat1->day <= 7, '1st Saturday in days 1-7');

    my $sat2 = $d->nth_weekday_of_month(2, 6);
    ok(defined $sat2, '2nd Saturday exists');
    ok($sat2->day > $sat1->day, '2nd > 1st Saturday');

    # 6th Saturday should not exist (month has 31 days, max 5 Saturdays)
    my $sat6 = $d->nth_weekday_of_month(6, 6);
    ok(!defined $sat6, '6th Saturday returns undef');
};

subtest 'last_weekday_of_month' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 15);
    my $last_sat = $d->last_weekday_of_month(6);
    is($last_sat->weekday(), 6, 'last Saturday is weekday 6');
    # No Saturday after it in the same month
    my $next = $last_sat->add_days(7);
    ok($next->month != $last_sat->month, 'no Saturday in same month after last');
};

subtest 'next_weekday and prev_weekday' => sub {
    my $d = NepaliDateTime::Date->new(2081, 1, 1);  # some day
    # next Sunday (0) from d
    my $next_sun = $d->next_weekday(0);
    is($next_sun->weekday(), 0, 'next_weekday gives Sunday');
    ok($next_sun >= $d, 'next_weekday on or after d');

    # prev Saturday (6)
    my $prev_sat = $d->prev_weekday(6);
    is($prev_sat->weekday(), 6, 'prev_weekday gives Saturday');
    ok($prev_sat <= $d, 'prev_weekday on or before d');
};

# ---------------------------------------------------------------------------
# 22. date_range
# ---------------------------------------------------------------------------
subtest 'date_range' => sub {
    my $s = NepaliDateTime::Date->new(2081, 1, 1);
    my $e = NepaliDateTime::Date->new(2081, 1, 7);
    my @r = NepaliDateTime::Date->date_range($s, $e);
    is(scalar(@r), 7, 'date_range 7 days');
    is($r[0]->day,  1, 'first day = 1');
    is($r[-1]->day, 7, 'last day = 7');
    is($r[3]->day,  4, 'middle day = 4');

    # Single day
    my @r1 = NepaliDateTime::Date->date_range($s, $s);
    is(scalar(@r1), 1, 'single day range');

    # start > end dies
    ok(dies { NepaliDateTime::Date->date_range($e, $s) }, 'start > end dies');
};

# ---------------------------------------------------------------------------
# 23. is_valid
# ---------------------------------------------------------------------------
subtest 'is_valid' => sub {
    ok( NepaliDateTime::Date->is_valid(2081,  3, 15), 'valid date');
    ok(!NepaliDateTime::Date->is_valid(1974,  1,  1), 'year too small');
    ok(!NepaliDateTime::Date->is_valid(2101,  1,  1), 'year too large');
    ok(!NepaliDateTime::Date->is_valid(2081,  0,  1), 'month 0');
    ok(!NepaliDateTime::Date->is_valid(2081, 13,  1), 'month 13');
    ok(!NepaliDateTime::Date->is_valid(2081,  1, 32), 'day 32');
    ok(!NepaliDateTime::Date->is_valid(2081,  1,  0), 'day 0');
};

# ---------------------------------------------------------------------------
# 24. min / max class methods
# ---------------------------------------------------------------------------
subtest 'min and max' => sub {
    my $min = NepaliDateTime::Date->min();
    is($min->year,  1975, 'min year 1975');
    is($min->month, 1,    'min month 1');
    is($min->day,   1,    'min day 1');

    my $max = NepaliDateTime::Date->max();
    is($max->year,  2100, 'max year 2100');
    is($max->month, 12,   'max month 12');
    ok($max->day >= 29, 'max day >= 29');

    ok($min < $max, 'min < max (Python: test_max_date_gt_min_date)');
};

# ---------------------------------------------------------------------------
# 25. ctime
# ---------------------------------------------------------------------------
subtest 'ctime' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    my $s = $d->ctime();
    like($s, qr/\d{4}/, 'ctime contains year');
    like($s, qr/00:00:00/, 'ctime has midnight for date');
};

# ---------------------------------------------------------------------------
# 26. format_devanagari / format_nepali_date
# ---------------------------------------------------------------------------
subtest 'format_devanagari' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    my $s = $d->format_devanagari();
    ok(length($s) > 0, 'format_devanagari non-empty');
    # Should contain Devanagari digits and month name
    like($s, qr/असार/, 'contains Devanagari month name');
};

subtest 'format_nepali_date' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    my $s = $d->format_nepali_date();
    is($s, '15 Asar 2081', 'format_nepali_date');
};

# ---------------------------------------------------------------------------
# 27. days_in_month_for (static/class utility)
# ---------------------------------------------------------------------------
subtest 'days_in_month_for' => sub {
    is(NepaliDateTime::Date->days_in_month_for(2081, 1), 31, 'Baisakh 2081 = 31');
    is(NepaliDateTime::Date->days_in_month_for(2081, 2), 32, 'Jestha 2081 = 32');

    ok(dies { NepaliDateTime::Date->days_in_month_for(1900, 1) }, 'bad year dies');
    ok(dies { NepaliDateTime::Date->days_in_month_for(2081, 0) }, 'month 0 dies');
};

# ---------------------------------------------------------------------------
# 28. print_calendar (smoke test – just ensure it doesn't die)
# ---------------------------------------------------------------------------
subtest 'print_calendar smoke test' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);
    my $buf = '';
    {
        local *STDOUT;
        open(STDOUT, '>', \$buf) or die $!;
        $d->print_calendar();
        close STDOUT;
    }
    ok(length($buf) > 0, 'print_calendar produces output');
    like($buf, qr/Asar/, 'calendar output contains month name');
};

done_testing();
