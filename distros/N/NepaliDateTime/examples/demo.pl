#!/usr/bin/env perl
# demo.pl – demonstration of NepaliDateTime::Date and NepaliDateTime::DateTime
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use NepaliDateTime::Date;
use NepaliDateTime::DateTime;

binmode STDOUT, ':utf8';

print "=" x 60, "\n";
print "NepaliDateTime Demo\n";
print "=" x 60, "\n\n";

# ------------------------------------------------------------------
# 1. Today's date in BS
# ------------------------------------------------------------------
my $today = NepaliDateTime::Date->today();
printf "Today (BS)       : %s\n",    $today->isoformat();
printf "Today (AD)       : %s\n",    $today->to_ad_string();
printf "Weekday (EN)     : %s\n",    $today->day_name();
printf "Weekday (NP)     : %s\n",    $today->day_name_np();
printf "Month (EN)       : %s\n",    $today->month_name();
printf "Month (NP)       : %s\n",    $today->month_name_np();
printf "Days in month    : %d\n",    $today->days_in_month();
printf "Days in year     : %d\n",    $today->days_in_year();
printf "Day of year      : %d\n",    $today->day_of_year();
printf "Week of year     : %d\n",    $today->week_of_year();
printf "Quarter          : %d\n",    $today->quarter();
printf "Is weekend?      : %s\n",    $today->is_weekend() ? 'Yes' : 'No';
printf "Devanagari       : %s\n\n",  $today->format_devanagari();

# ------------------------------------------------------------------
# 2. Fiscal year
# ------------------------------------------------------------------
my ($fy_s, $fy_e) = $today->fiscal_year();
printf "Fiscal year      : %d/%d\n",   $fy_s, $fy_e;
printf "Fiscal quarter   : FQ%d\n",    $today->fiscal_quarter();
printf "FY start         : %s\n",      $today->fiscal_year_start()->isoformat();
printf "FY end           : %s\n\n",    $today->fiscal_year_end()->isoformat();

# ------------------------------------------------------------------
# 3. AD ↔ BS conversion examples
# ------------------------------------------------------------------
print "-" x 40, "\n";
print "AD → BS conversions\n";
print "-" x 40, "\n";
my @ad_examples = ([2024,7,15],[2019,10,14],[1995,1,15]);
for my $e (@ad_examples) {
    my $bs = NepaliDateTime::Date->from_ad(@$e);
    printf "  AD %04d-%02d-%02d  →  BS %s\n", @$e, $bs->isoformat();
}

print "\nBS → AD conversions\n";
print "-" x 40, "\n";
my @bs_examples = ([2081,3,31],[2076,6,27],[2051,10,1]);
for my $e (@bs_examples) {
    my $bs = NepaliDateTime::Date->new(@$e);
    my ($ay,$am,$ad) = $bs->to_ad();
    printf "  BS %04d-%02d-%02d  →  AD %04d-%02d-%02d\n", @$e, $ay,$am,$ad;
}

# ------------------------------------------------------------------
# 4. strftime formatting
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "strftime examples\n";
print "-" x 40, "\n";
my $d = NepaliDateTime::Date->new(2081, 3, 15);
my @fmts = (
    [ '%Y-%m-%d',       'ISO date' ],
    [ '%d %B %Y',       'Long date' ],
    [ '%A, %d %B %Y',   'Full date with weekday' ],
    [ '%d/%m/%y',       'Short date' ],
    [ '%K-%n-%D',       'Devanagari numerals' ],
    [ '%N %K',          'Devanagari month + year' ],
    [ '%G, %D %N %K',   'Full Devanagari' ],
    [ '%b %y',          'Abbreviated' ],
);
for my $f (@fmts) {
    printf "  %-30s → %s\n", $f->[1], $d->strftime($f->[0]);
}

# ------------------------------------------------------------------
# 5. strptime parsing
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "strptime examples\n";
print "-" x 40, "\n";
my @parse_examples = (
    [ '2081-03-15',         '%Y-%m-%d' ],
    [ '15 Asar 2081',       '%d %B %Y' ],
    [ 'Wednesday 15 Asar',  '%A %d %B' ],
);
for my $e (@parse_examples) {
    eval {
        my $pd = NepaliDateTime::Date->strptime($e->[0], $e->[1]);
        printf "  %-28s  →  BS year=%d month=%d day=%d\n",
            "'$e->[0]'", $pd->year, $pd->month, $pd->day;
    };
    if ($@) { printf "  (skipped: %s)\n", $@; }
}

# ------------------------------------------------------------------
# 6. Arithmetic
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "Date arithmetic\n";
print "-" x 40, "\n";
my $base = NepaliDateTime::Date->new(2081, 3, 15);
printf "  Base date          : %s\n", $base;
printf "  + 10 days          : %s\n", $base->add_days(10);
printf "  - 10 days          : %s\n", $base->add_days(-10);
printf "  + 3 months         : %s\n", $base->add_months(3);
printf "  + 1 year           : %s\n", $base->add_years(1);
printf "  Month start        : %s\n", $base->month_start();
printf "  Month end          : %s\n", $base->month_end();
printf "  Year start         : %s\n", $base->year_start();
printf "  Year end           : %s\n", $base->year_end();

my $birth = NepaliDateTime::Date->new(2050, 1, 1);
printf "  Age from 2050-01-01: %d years\n", $base->age_from($birth);

my $other = NepaliDateTime::Date->new(2081, 12, 30);
printf "  Days until 2081-12-30: %d\n", $base->days_until($other);

# ------------------------------------------------------------------
# 7. Weekday helpers
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "Weekday helpers\n";
print "-" x 40, "\n";
my $m = NepaliDateTime::Date->new(2081, 1, 15);
for my $n (1..5) {
    my $sat = $m->nth_weekday_of_month($n, 6);  # Saturdays
    last unless defined $sat;
    printf "  %d%s Saturday in %s %d: %s\n",
        $n, ($n==1?'st':$n==2?'nd':$n==3?'rd':'th'),
        $m->month_name(), $m->year(), $sat;
}
my $last_sat = $m->last_weekday_of_month(6);
printf "  Last Saturday: %s\n", $last_sat;

# ------------------------------------------------------------------
# 8. Date range
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "Date range: first 7 days of 2081-01\n";
print "-" x 40, "\n";
my $start = NepaliDateTime::Date->new(2081,1,1);
my $end   = NepaliDateTime::Date->new(2081,1,7);
for my $dd (NepaliDateTime::Date->date_range($start,$end)) {
    printf "  %s  %s\n", $dd, $dd->day_name_abbr();
}

# ------------------------------------------------------------------
# 9. DateTime examples
# ------------------------------------------------------------------
print "\n", "=" x 60, "\n";
print "DateTime examples\n";
print "=" x 60, "\n\n";

my $now = NepaliDateTime::DateTime->now();
printf "Now (BS, NST)    : %s\n",   $now->isoformat();
printf "ctime            : %s\n",   $now->ctime();
printf "Devanagari       : %s\n\n", $now->format_devanagari();

my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 23, 50, 0);
printf "Base datetime    : %s\n",   $dt->isoformat();
printf "+ 15 minutes     : %s\n",   $dt->add_minutes(15)->isoformat();
printf "+ 5 hours        : %s\n",   $dt->add_hours(5)->isoformat();
printf "+ 1 day          : %s\n",   $dt->add_days(1)->isoformat();
printf "from AD datetime : %s\n",
    NepaliDateTime::DateTime->from_ad_datetime(2024,7,15,14,30,0)->isoformat();

my $dt2 = NepaliDateTime::DateTime->new(2081, 3, 15, 10, 0, 0);
my $dt3 = NepaliDateTime::DateTime->new(2081, 3, 15, 12, 30, 0);
printf "\nTime difference  : %.0f seconds (%.1f hours)\n",
    $dt3 - $dt2, ($dt3 - $dt2) / 3600;

# ------------------------------------------------------------------
# 10. Calendar display
# ------------------------------------------------------------------
print "\n", "-" x 40, "\n";
print "Calendar for current BS month\n";
print "-" x 40, "\n";
$today->print_calendar();

print "\n";
print "Devanagari calendar\n";
print "-" x 40, "\n";
$today->print_calendar(devanagari => 1);
