#!/usr/bin/env perl
# t/04_data.t – tests for NepaliDateTime::Data calendar data correctness
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test2::V1 '-ipP';

use NepaliDateTime::Data;
use NepaliDateTime::Date;

# ---------------------------------------------------------------------------
# 1. Constants
# ---------------------------------------------------------------------------
subtest 'Constants' => sub {
    is($NepaliDateTime::Data::MINYEAR, 1975, 'MINYEAR = 1975');
    is($NepaliDateTime::Data::MAXYEAR, 2100, 'MAXYEAR = 2100');
    is($NepaliDateTime::Data::NEPAL_UTC_OFFSET, 20700, 'NEPAL_UTC_OFFSET = 20700 (5h45m)');

    # Reference date AD
    is($NepaliDateTime::Data::REFERENCE_DATE_AD[0], 1918, 'ref AD year 1918');
    is($NepaliDateTime::Data::REFERENCE_DATE_AD[1], 4,    'ref AD month 4');
    is($NepaliDateTime::Data::REFERENCE_DATE_AD[2], 13,   'ref AD day 13');

    # MAXORDINAL is total days in range
    ok($NepaliDateTime::Data::MAXORDINAL > 0, 'MAXORDINAL positive');
};

# ---------------------------------------------------------------------------
# 2. DAYS_BEFORE_YEAR
# ---------------------------------------------------------------------------
subtest 'DAYS_BEFORE_YEAR' => sub {
    # First entry (index 0 = year 1975) should be 0
    is($NepaliDateTime::Data::DAYS_BEFORE_YEAR[0], 0, 'DAYS_BEFORE_YEAR[0] = 0 (first year start)');

    # Should have 126 entries for years 1975..2100 plus sentinel
    my $n = scalar @NepaliDateTime::Data::DAYS_BEFORE_YEAR;
    is($n, 127, 'DAYS_BEFORE_YEAR has 127 entries (126 years + sentinel)');

    # Strictly increasing
    for my $i (1 .. $#NepaliDateTime::Data::DAYS_BEFORE_YEAR) {
        ok($NepaliDateTime::Data::DAYS_BEFORE_YEAR[$i] > $NepaliDateTime::Data::DAYS_BEFORE_YEAR[$i-1],
           "DAYS_BEFORE_YEAR[$i] > DAYS_BEFORE_YEAR[" . ($i-1) . "]");
    }
};

# ---------------------------------------------------------------------------
# 3. DAYS_IN_MONTH – spot checks
# ---------------------------------------------------------------------------
subtest 'DAYS_IN_MONTH spot checks' => sub {
    # Verify a few known values from the RAW table
    is($NepaliDateTime::Data::DAYS_IN_MONTH{1975}[1],  31, '1975 Baisakh = 31');
    is($NepaliDateTime::Data::DAYS_IN_MONTH{1975}[2],  31, '1975 Jestha = 31');
    is($NepaliDateTime::Data::DAYS_IN_MONTH{1975}[3],  32, '1975 Asar = 32');
    is($NepaliDateTime::Data::DAYS_IN_MONTH{2081}[2],  32, '2081 Jestha = 32');
    is($NepaliDateTime::Data::DAYS_IN_MONTH{2100}[12], 30, '2100 Chaitra = 30');

    # All months in all years should be between 29 and 32
    for my $year ($NepaliDateTime::Data::MINYEAR .. $NepaliDateTime::Data::MAXYEAR) {
        for my $m (1..12) {
            my $d = $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$m];
            ok($d >= 29 && $d <= 32, "days in $year-$m ($d) in 29..32");
        }
    }
};

# ---------------------------------------------------------------------------
# 4. CUMUL – prefix sums correctness
# ---------------------------------------------------------------------------
subtest 'CUMUL prefix sums' => sub {
    for my $year ($NepaliDateTime::Data::MINYEAR .. $NepaliDateTime::Data::MAXYEAR) {
        my $cum = $NepaliDateTime::Data::CUMUL{$year};
        is($cum->[0], 0, "CUMUL{$year}[0] = 0");

        # Each element is the sum of months up to that point
        my $total = 0;
        for my $m (1..12) {
            $total += $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$m];
            is($cum->[$m], $total, "CUMUL{$year}[$m] = $total");
        }
    }
};

# ---------------------------------------------------------------------------
# 5. MAXORDINAL equals total days
# ---------------------------------------------------------------------------
subtest 'MAXORDINAL equals total days in all years' => sub {
    my $total = 0;
    for my $year ($NepaliDateTime::Data::MINYEAR .. $NepaliDateTime::Data::MAXYEAR) {
        $total += $NepaliDateTime::Data::CUMUL{$year}[12];
    }
    is($NepaliDateTime::Data::MAXORDINAL, $total, 'MAXORDINAL = total days');
};

# ---------------------------------------------------------------------------
# 6. Name tables
# ---------------------------------------------------------------------------
subtest 'Month name tables' => sub {
    is(scalar(@NepaliDateTime::Data::MONTH_ABBR), 13, 'MONTH_ABBR has 13 entries (undef + 12)');
    is(scalar(@NepaliDateTime::Data::MONTH_FULL), 13, 'MONTH_FULL has 13 entries');
    is(scalar(@NepaliDateTime::Data::MONTH_NP),   13, 'MONTH_NP has 13 entries');

    # undef at index 0
    ok(!defined $NepaliDateTime::Data::MONTH_ABBR[0], 'MONTH_ABBR[0] is undef');

    # Spot checks – match Python _MONTHNAMES / _FULLMONTHNAMES / _MONTHNAMES_NP
    is($NepaliDateTime::Data::MONTH_ABBR[1],  'Bai',      'Baisakh abbr');
    is($NepaliDateTime::Data::MONTH_ABBR[12], 'Cha',      'Chaitra abbr');
    is($NepaliDateTime::Data::MONTH_FULL[1],  'Baishakh', 'Baishakh full');
    is($NepaliDateTime::Data::MONTH_FULL[6],  'Aswin',    'Aswin full');
    is($NepaliDateTime::Data::MONTH_FULL[12], 'Chaitra',  'Chaitra full');
    is($NepaliDateTime::Data::MONTH_NP[1],    'वैशाख',    'Baisakh NP');
    is($NepaliDateTime::Data::MONTH_NP[12],   'चैत्र',    'Chaitra NP');
};

subtest 'Weekday name tables' => sub {
    is(scalar(@NepaliDateTime::Data::WDAY_ABBR), 7, 'WDAY_ABBR has 7 entries');
    is(scalar(@NepaliDateTime::Data::WDAY_FULL), 7, 'WDAY_FULL has 7 entries');
    is(scalar(@NepaliDateTime::Data::WDAY_NP),   7, 'WDAY_NP has 7 entries');

    # 0=Sunday convention (matches Python nepali_datetime)
    is($NepaliDateTime::Data::WDAY_ABBR[0], 'Sun', 'WDAY_ABBR[0] = Sun (0=Sunday)');
    is($NepaliDateTime::Data::WDAY_ABBR[6], 'Sat', 'WDAY_ABBR[6] = Sat (6=Saturday)');
    is($NepaliDateTime::Data::WDAY_FULL[0], 'Sunday',   'WDAY_FULL[0] = Sunday');
    is($NepaliDateTime::Data::WDAY_FULL[6], 'Saturday', 'WDAY_FULL[6] = Saturday');
    is($NepaliDateTime::Data::WDAY_NP[0],   'आइतबार',   'WDAY_NP[0] = आइतबार (Sunday)');
    is($NepaliDateTime::Data::WDAY_NP[6],   'शनिबार',   'WDAY_NP[6] = शनिबार (Saturday)');
};

subtest 'Devanagari digit table' => sub {
    is(scalar(@NepaliDateTime::Data::DIGIT_NP), 10, 'DIGIT_NP has 10 entries (0-9)');
    is($NepaliDateTime::Data::DIGIT_NP[0], '०', 'DIGIT_NP[0] = ०');
    is($NepaliDateTime::Data::DIGIT_NP[9], '९', 'DIGIT_NP[9] = ९');
};

# ---------------------------------------------------------------------------
# 7. Ordinal consistency: DAYS_BEFORE_YEAR[i+1] - DAYS_BEFORE_YEAR[i] = year total
# ---------------------------------------------------------------------------
subtest 'DAYS_BEFORE_YEAR differences equal year totals' => sub {
    my $n = $NepaliDateTime::Data::MAXYEAR - $NepaliDateTime::Data::MINYEAR; # 125
    for my $i (0 .. $n - 1) {
        my $year = $NepaliDateTime::Data::MINYEAR + $i;
        my $diff = $NepaliDateTime::Data::DAYS_BEFORE_YEAR[$i+1]
                 - $NepaliDateTime::Data::DAYS_BEFORE_YEAR[$i];
        my $total = $NepaliDateTime::Data::CUMUL{$year}[12];
        is($diff, $total, "year $year: DAYS_BEFORE_YEAR diff = $total");
    }
};

done_testing();
