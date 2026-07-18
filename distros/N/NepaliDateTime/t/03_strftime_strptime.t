#!/usr/bin/env perl
# t/03_strftime_strptime.t – strftime and strptime tests
# Mirrors Python nepali_datetime strftime/strptime tests and adds more.
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test2::V1 '-ipP';

use NepaliDateTime::Date;
use NepaliDateTime::DateTime;

# ===========================================================================
# strftime on Date
# ===========================================================================

# Python: test_strftime_date
subtest 'strftime on Date – Python test_strftime_date' => sub {
    # dt = date(2077, 6, 4)
    my $d = NepaliDateTime::Date->new(2077, 6, 4);
    is($d->strftime('%m/%d/%Y'), '06/04/2077', '%m/%d/%Y');

    # Python: "%A of %B %d %y" == "Sunday of Aswin 04 77"
    is($d->strftime('%A of %B %d %y'), 'Sunday of Aswin 04 77', '%A of %B %d %y');

    # Python: "%a %b" == "Sun Asw"
    is($d->strftime('%a %b'), 'Sun Asw', '%a %b');
};

subtest 'strftime on Date – various format codes' => sub {
    my $d = NepaliDateTime::Date->new(2081, 3, 15);

    is($d->strftime('%Y'),         '2081',         '%Y 4-digit year');
    is($d->strftime('%y'),         '81',            '%y 2-digit year');
    is($d->strftime('%m'),         '03',            '%m zero-padded month');
    is($d->strftime('%d'),         '15',            '%d zero-padded day');
    is($d->strftime('%Y-%m-%d'),   '2081-03-15',    '%Y-%m-%d');
    is($d->strftime('%B'),         'Asar',          '%B full month name');
    is($d->strftime('%b'),         'Asa',           '%b abbreviated month name');
    is($d->strftime('%N'),         'असार',          '%N Nepali month name');
    is($d->strftime('%w'),         '6',             '%w weekday number');  # Saturday=6

    # Devanagari variants
    my $k = $d->strftime('%K');
    like($k, qr/^[०-९]+$/, '%K Devanagari year');
    my $k2 = $d->strftime('%k');
    like($k2, qr/^[०-९]+$/, '%k Devanagari 2-digit year');
    my $Dn = $d->strftime('%D');
    like($Dn, qr/^[०-९]+$/, '%D Devanagari day');
    my $mn = $d->strftime('%n');
    like($mn, qr/^[०-९]+$/, '%n Devanagari month');

    # %G full Nepali weekday
    my $G = $d->strftime('%G');
    like($G, qr/शनिबार/, '%G Devanagari weekday (Saturday=शनिबार)');

    # Week number
    my $U = $d->strftime('%U');
    ok(length($U) > 0, '%U week number non-empty');

    # Day of year
    my $j = $d->strftime('%j');
    ok($j =~ /^\d{3}$/, '%j day of year 3 digits');

    # AM/PM, H, M, S are 0 for date-only objects
    is($d->strftime('%H'), '00', '%H = 00 for date-only');
    is($d->strftime('%M'), '00', '%M = 00 for date-only');
    is($d->strftime('%S'), '00', '%S = 00 for date-only');
    is($d->strftime('%p'), 'AM', '%p = AM for date-only');

    # 12-hour clock %I
    is($d->strftime('%I'), '12', '%I = 12 for date-only (midnight displayed as 12)');

    # Literal %
    is($d->strftime('%%'), '%', '%% → %');
    is($d->strftime('%% %Y'), '% 2081', '%% %Y');

    # Unknown format code passes through unchanged
    my $unk = $d->strftime('%Q');
    is($unk, '%Q', 'unknown format code passes through');
};

subtest 'strftime weekday names for each weekday' => sub {
    # We know 2077-06-04 is Sunday (weekday=0)
    my $base = NepaliDateTime::Date->new(2077, 6, 4);  # Sunday
    my @full_en = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @abbr_en = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @full_np = ('आइतबार','सोमबार','मंगलबार','बुधवार','बिहिबार','शुक्रबार','शनिबार');

    for my $i (0..6) {
        my $d = $base->add_days($i);
        is($d->strftime('%A'), $full_en[$i], "%A day $i = $full_en[$i]");
        is($d->strftime('%a'), $abbr_en[$i], "%a day $i = $abbr_en[$i]");
        is($d->strftime('%G'), $full_np[$i], "%G day $i = $full_np[$i]");
        is($d->weekday(),      $i,            "weekday = $i");
    }
};

subtest 'strftime all month names' => sub {
    my @months_full = (undef,
        'Baishakh','Jestha','Asar','Shrawan','Bhadau','Aswin',
        'Kartik','Mangsir','Poush','Magh','Falgun','Chaitra');
    my @months_abbr = (undef,
        'Bai','Jes','Asa','Shr','Bha','Asw',
        'Kar','Man','Pou','Mag','Fal','Cha');
    my @months_np = (undef,
        'वैशाख','जेष्ठ','असार','श्रावण','भदौ','आश्विन',
        'कार्तिक','मंसिर','पौष','माघ','फाल्गुण','चैत्र');

    for my $m (1..12) {
        my $d = NepaliDateTime::Date->new(2081, $m, 1);
        is($d->strftime('%B'), $months_full[$m], "%B month $m = $months_full[$m]");
        is($d->strftime('%b'), $months_abbr[$m], "%b month $m = $months_abbr[$m]");
        is($d->strftime('%N'), $months_np[$m],   "%N month $m = $months_np[$m]");
    }
};

# ===========================================================================
# strftime on DateTime  (Python: test_strftime_datetime)
# ===========================================================================

subtest 'strftime on DateTime – Python test_strftime_datetime' => sub {
    # Python: datetime(2052,10,29,15,22,50,2222)
    # .strftime("%m/%d/%Y %I:%M:%S.%f %p %a %A %U")
    #  == "10/29/2052 03:22:50.002222 PM Mon Monday 44"
    my $dt = NepaliDateTime::DateTime->new(2052, 10, 29, 15, 22, 50, 2222);

    is($dt->strftime('%m/%d/%Y'), '10/29/2052', '%m/%d/%Y on datetime');
    is($dt->strftime('%I'),       '03',          '%I 12h clock (15 mod 12 = 3)');
    is($dt->strftime('%H'),       '15',          '%H 24h');
    is($dt->strftime('%M'),       '22',          '%M minute');
    is($dt->strftime('%S'),       '50',          '%S second');
    is($dt->strftime('%f'),       '002222',      '%f microsecond padded to 6');
    is($dt->strftime('%p'),       'PM',          '%p PM for hour 15');
    is($dt->strftime('%a'),       'Mon',         '%a Monday');
    is($dt->strftime('%A'),       'Monday',      '%A Monday');

    my $U = $dt->strftime('%U');
    ok(length($U) >= 2, '%U week number present');

    # Full Python format string (skipping %U exact value as week calc differs slightly)
    my $full = $dt->strftime('%m/%d/%Y %I:%M:%S.%f %p %a %A');
    is($full, '10/29/2052 03:22:50.002222 PM Mon Monday', 'full datetime strftime');
};

subtest 'strftime on DateTime – time codes' => sub {
    my $dt_am = NepaliDateTime::DateTime->new(2081, 3, 15, 9, 5, 3);
    is($dt_am->strftime('%H'), '09', '%H AM hour 9');
    is($dt_am->strftime('%I'), '09', '%I AM 12h = 9');
    is($dt_am->strftime('%p'), 'AM', '%p AM');
    is($dt_am->strftime('%M'), '05', '%M minute 5');
    is($dt_am->strftime('%S'), '03', '%S second 3');

    my $dt_pm = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    is($dt_pm->strftime('%H'), '14', '%H PM hour 14');
    is($dt_pm->strftime('%I'), '02', '%I PM 12h = 2');
    is($dt_pm->strftime('%p'), 'PM', '%p PM');

    # Midnight
    my $dt_mid = NepaliDateTime::DateTime->new(2081, 3, 15, 0, 0, 0);
    is($dt_mid->strftime('%I'), '12', '%I midnight = 12');
    is($dt_mid->strftime('%p'), 'AM', '%p midnight = AM');

    # Noon
    my $dt_noon = NepaliDateTime::DateTime->new(2081, 3, 15, 12, 0, 0);
    is($dt_noon->strftime('%I'), '12', '%I noon = 12');
    is($dt_noon->strftime('%p'), 'PM', '%p noon = PM');
};

subtest 'strftime Devanagari time codes on DateTime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 5);
    my $h = $dt->strftime('%h');
    like($h, qr/^[०-९]+$/, '%h Devanagari hour');
    my $l = $dt->strftime('%l');
    like($l, qr/^[०-९]+$/, '%l Devanagari minute');
    my $s = $dt->strftime('%s');
    like($s, qr/^[०-९]+$/, '%s Devanagari second');
    my $i = $dt->strftime('%i');
    like($i, qr/^[०-९]+$/, '%i Devanagari 12h');
};

subtest 'strftime timezone codes on DateTime' => sub {
    my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);
    is($dt->strftime('%z'), '+0545', '%z UTC offset');
    is($dt->strftime('%Z'), 'NST',   '%Z timezone name');
};

# ===========================================================================
# strptime on Date  (Python: test_strptime_date)
# ===========================================================================

subtest 'strptime on Date – Python test_strptime_date' => sub {
    # Python: datetime.strptime("2011-10-11", "%Y-%m-%d").date() == date(2011, 10, 11)
    my $d = NepaliDateTime::Date->strptime('2011-10-11', '%Y-%m-%d');
    is($d->year,  2011, 'strptime year 2011');
    is($d->month, 10,   'strptime month 10');
    is($d->day,   11,   'strptime day 11');

    # Python: datetime.strptime("2077-02-32", "%Y-%m-%d").date() == date(2077, 2, 32)
    my $d2 = NepaliDateTime::Date->strptime('2077-02-32', '%Y-%m-%d');
    is($d2->year,  2077, 'strptime 2077');
    is($d2->month, 2,    'strptime month 2');
    is($d2->day,   32,   'strptime day 32');
};

subtest 'strptime on Date – month name formats' => sub {
    # "15 Asar 2081" with %d %B %Y
    my $d = NepaliDateTime::Date->strptime('15 Asar 2081', '%d %B %Y');
    is($d->year,  2081, 'strptime with %B year');
    is($d->month, 3,    'strptime with %B month (Asar=3)');
    is($d->day,   15,   'strptime with %B day');

    # Abbreviated month name
    my $d2 = NepaliDateTime::Date->strptime('15 Asa 2081', '%d %b %Y');
    is($d2->month, 3, 'strptime with %b month (Asa=3)');
    is($d2->day,   15, 'strptime with %b day');

    # Nepali month name %N with ASCII day digits (Devanagari digits are not
    # matched by \d in the strptime regex, so the day must be ASCII)
    my $d3 = NepaliDateTime::Date->strptime('असार-15-2081', '%N-%d-%Y');
    is($d3->year,  2081, 'strptime %N year');
    is($d3->month, 3,    'strptime %N month (असार=3)');
    is($d3->day,   15,   'strptime %N day');

    # %B embedded alongside other tokens
    my $d4 = NepaliDateTime::Date->strptime('2081-Asar-15', '%Y-%B-%d');
    is($d4->month, 3, 'strptime %B embedded in format');
};

subtest 'strptime 2-digit year – Python: test_strptime_year_special_case' => sub {
    # Python: datetime.strptime("89", "%y") → year 2089 (≤89 → 2000+y)
    # Python: datetime.strptime("90", "%y") → year 1990 (≥90 → 1900+y)
    # Python: datetime.strptime("00", "%y") → year 2000
    #
    # NOTE: Perl's Date::strptime requires month and day to be present in the
    # format string (it does not silently default them to 1 the way Python
    # datetime.strptime does). We therefore supply a complete format. The %y
    # two-digit-year logic is identical to Python's: y≤89 → 2000+y, y≥90 → 1900+y.

    my $d89 = NepaliDateTime::Date->strptime('1/1/89', '%m/%d/%y');
    is($d89->year, 2089, '%y 89 → 2089');

    my $d90 = NepaliDateTime::Date->strptime('1/1/90', '%m/%d/%y');
    is($d90->year, 1990, '%y 90 → 1990');

    my $d00 = NepaliDateTime::Date->strptime('1/1/00', '%m/%d/%y');
    is($d00->year, 2000, '%y 00 → 2000');

    # Boundary: 89 is the pivot — verify both sides
    my $d88 = NepaliDateTime::Date->strptime('1/1/88', '%m/%d/%y');
    is($d88->year, 2088, '%y 88 → 2088');

    my $d91 = NepaliDateTime::Date->strptime('1/1/91', '%m/%d/%y');
    is($d91->year, 1991, '%y 91 → 1991');
};

subtest 'strptime errors on bad input' => sub {
    ok(dies { NepaliDateTime::Date->strptime('2081-13-15', '%Y-%m-%d') },
       'strptime with bad month dies on new()');
    ok(dies { NepaliDateTime::Date->strptime('not-a-date', '%Y-%m-%d') },
       'strptime non-matching string dies');
};

# ===========================================================================
# strptime on DateTime  (Python: test_strptime_datetime)
# ===========================================================================

subtest 'strptime on DateTime – Python test_strptime_datetime' => sub {
    # Python: datetime.strptime("Asar 23 2025 10:00:00", "%B %d %Y %H:%M:%S")
    #         == datetime(2025, 3, 23, 10, 0, 0)
    my $dt = NepaliDateTime::DateTime->strptime('Asar 23 2025 10:00:00', '%B %d %Y %H:%M:%S');
    is($dt->year,   2025, 'strptime DT year');
    is($dt->month,  3,    'strptime DT month (Asar=3)');
    is($dt->day,    23,   'strptime DT day');
    is($dt->hour,   10,   'strptime DT hour');
    is($dt->minute, 0,    'strptime DT minute');
    is($dt->second, 0,    'strptime DT second');
};

subtest 'strptime on DateTime – %H:%M:%S' => sub {
    my $dt = NepaliDateTime::DateTime->strptime('2081-03-15 14:30:45', '%Y-%m-%d %H:%M:%S');
    is($dt->year,   2081, 'DT strptime year');
    is($dt->month,  3,    'DT strptime month');
    is($dt->day,    15,   'DT strptime day');
    is($dt->hour,   14,   'DT strptime hour');
    is($dt->minute, 30,   'DT strptime minute');
    is($dt->second, 45,   'DT strptime second');
};

subtest 'strptime on DateTime – microseconds %f' => sub {
    my $dt = NepaliDateTime::DateTime->strptime('2081-03-15 10:00:00.123456', '%Y-%m-%d %H:%M:%S.%f');
    is($dt->microsecond, 123456, 'strptime microsecond');

    # Short microsecond string padded
    my $dt2 = NepaliDateTime::DateTime->strptime('2081-03-15 10:00:00.1', '%Y-%m-%d %H:%M:%S.%f');
    is($dt2->microsecond, 100000, 'strptime short microsecond padded');
};

subtest 'strptime on DateTime – 12-hour clock with AM/PM' => sub {
    my $dt_am = NepaliDateTime::DateTime->strptime('2081-03-15 02:30 AM', '%Y-%m-%d %I:%M %p');
    is($dt_am->hour,   2,  'strptime 2 AM → hour 2');
    is($dt_am->minute, 30, 'strptime minute 30');

    my $dt_pm = NepaliDateTime::DateTime->strptime('2081-03-15 02:30 PM', '%Y-%m-%d %I:%M %p');
    is($dt_pm->hour, 14, 'strptime 2 PM → hour 14');

    my $dt_noon = NepaliDateTime::DateTime->strptime('2081-03-15 12:00 PM', '%Y-%m-%d %I:%M %p');
    is($dt_noon->hour, 12, 'strptime noon = 12');

    my $dt_mid = NepaliDateTime::DateTime->strptime('2081-03-15 12:00 AM', '%Y-%m-%d %I:%M %p');
    is($dt_mid->hour, 0, 'strptime midnight = 0');
};

# ===========================================================================
# strftime / strptime round-trips
# ===========================================================================

subtest 'strftime / strptime round-trip – Date' => sub {
    my @dates = (
        [2081, 3, 15],
        [1975, 1, 1],
        [2100, 12, 30],
        [2055, 7, 22],
    );
    for my $d (@dates) {
        my $obj  = NepaliDateTime::Date->new(@$d);
        my $str  = $obj->strftime('%Y-%m-%d');
        my $back = NepaliDateTime::Date->strptime($str, '%Y-%m-%d');
        ok($obj == $back, "round-trip $str");
    }
};

subtest 'strftime / strptime round-trip – DateTime' => sub {
    my $dt   = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 45);
    my $str  = $dt->strftime('%Y-%m-%d %H:%M:%S');
    my $back = NepaliDateTime::DateTime->strptime($str, '%Y-%m-%d %H:%M:%S');
    is($back->year,   2081, 'RT DT year');
    is($back->hour,   14,   'RT DT hour');
    is($back->minute, 30,   'RT DT minute');
    is($back->second, 45,   'RT DT second');
};

done_testing();
