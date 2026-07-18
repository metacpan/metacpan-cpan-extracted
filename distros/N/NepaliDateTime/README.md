# NepaliDateTime — Bikram Sambat Date/Time for Perl


[![Perl CI](https://github.com/sumanstats/NepaliDateTime/actions/workflows/test.yml/badge.svg)](https://github.com/sumanstats/NepaliDateTime/actions/workflows/test.yml)

A pure-Perl implementation of the Bikram Sambat (B.S.) calendar, modelled
after the Python [nepali_datetime](https://github.com/amitgaru2/nepali-datetime)
library and extended with additional features.

**Supported date range:** BS 1975-01-01 to BS 2100-12-30  
**Reference anchor:** AD 1918-04-13 ≡ BS 1975-01-01  
**Nepal Standard Time:** UTC+05:45

---

## Installation

Standard toolchain (`ExtUtils::MakeMaker`, ships with every Perl):

```bash
perl Makefile.PL
make
make test
make install
```

Or, with [`cpanm`](https://metacpan.org/pod/App::cpanminus):

```bash
cpanm .
```

Both install `NepaliDateTime`, `NepaliDateTime::Date`, and
`NepaliDateTime::DateTime` (plus man pages) into your normal Perl library
path. To install somewhere else instead (e.g. a local `lib`, for
`local::lib`-style setups), pass `INSTALL_BASE`:

```bash
perl Makefile.PL INSTALL_BASE=$HOME/perl5
make install
```

The runtime code has no external CPAN dependencies — only core modules
(`Carp`, `POSIX`). The test suite uses [`Test2::Suite`](https://metacpan.org/pod/Test2::Suite)
(for `Test2::V0`), which is *not* core — install it with `cpanm Test2::Suite`
or your OS package (e.g. `libtest2-suite-perl` on Debian/Ubuntu) if
`make test` can't find it. Requires Perl 5.10 or newer.

If you'd rather not install it at all, see [Running Tests](#running-tests)
and [Running the Demo](#running-the-demo) below for running straight from
the source tree with `-Ilib`.

---

## Modules

| Module | Purpose |
|---|---|
| `NepaliDateTime::Date` | BS date object |
| `NepaliDateTime::DateTime` | BS date + time object |
| `NepaliDateTime::Data` | Internal calendar data (not for direct use) |

---

## Quick Start

```perl
use NepaliDateTime::Date;
use NepaliDateTime::DateTime;

# Today in BS
my $today = NepaliDateTime::Date->today();
print $today->isoformat();          # e.g. "2081-03-15"
print $today->format_devanagari();  # e.g. "२०८१ असार १५, बुधवार"

# Now (Nepal Standard Time)
my $now = NepaliDateTime::DateTime->now();
print $now->isoformat();   # "2081-03-15T14:30:00+05:45"
```

---

## NepaliDateTime::Date

### Construction

```perl
# By year, month, day (BS)
my $d = NepaliDateTime::Date->new(2081, 3, 15);

# Today in Nepal Standard Time
my $today = NepaliDateTime::Date->today();

# From AD (Gregorian) date
my $bs = NepaliDateTime::Date->from_ad(2024, 7, 15);

# From ISO string
my $d2 = NepaliDateTime::Date->from_iso('2081-03-15');

# From ordinal (BS 1975-01-01 = 1)
my $d3 = NepaliDateTime::Date->from_ordinal(1);

# From Unix timestamp (converted to Nepal time)
my $d4 = NepaliDateTime::Date->from_timestamp(time());
```

### Conversion

```perl
my ($ay, $am, $ad) = $d->to_ad();          # BS → AD (year, month, day)
my $ad_str         = $d->to_ad_string();    # "2024-07-15"
my $ordinal        = $d->toordinal();       # integer ordinal
my $epoch          = $d->to_timestamp();    # Unix timestamp (midnight NST)
```

### Date Attributes

```perl
$d->year();            # 2081
$d->month();           # 3
$d->day();             # 15
$d->weekday();         # 0=Sun … 6=Sat
$d->weekday_iso();     # 1=Mon … 7=Sun
$d->day_name();        # "Wednesday"
$d->day_name_abbr();   # "Wed"
$d->day_name_np();     # "बुधवार"
$d->month_name();      # "Asar"
$d->month_name_abbr(); # "Asa"
$d->month_name_np();   # "असार"
$d->days_in_month();   # 32
$d->days_in_year();    # 365 or 366
$d->day_of_year();     # 1–366
$d->week_of_year();    # 1–53
$d->quarter();         # 1–4  (Q1 = Baisakh–Asar)
$d->is_weekend();      # 1 if Saturday
$d->is_weekend(1);     # 1 if Saturday or Friday
```

### Nepal Fiscal Year

Nepal's fiscal year runs **1 Shrawan → last day of Ashadh** (month 4 → month 3 of next year).

```perl
my ($fy_start, $fy_end) = $d->fiscal_year();   # (2080, 2081)
my $fq                   = $d->fiscal_quarter(); # 1–4
my $fy_s                 = $d->fiscal_year_start();
my $fy_e                 = $d->fiscal_year_end();
```

### Arithmetic

```perl
$d->add_days(10);      # new date 10 days later (negative for past)
$d->add_months(3);     # new date 3 months later (day clamped to month end)
$d->add_years(1);      # new date 1 year later
$d->month_start();     # first day of current month
$d->month_end();       # last day of current month
$d->year_start();      # 1 Baishakh of current year
$d->year_end();        # last day of Chaitra of current year
$d->replace(day => 1); # copy with day replaced
$d->clone();           # exact copy
```

Overloaded operators:

```perl
my $d2 = $d + 5;      # add 5 days
my $d3 = $d - 5;      # subtract 5 days
my $n  = $d2 - $d;    # integer day difference
# Comparison: ==  !=  <  <=  >  >=  <=>
# Stringification: "$d" → "2081-03-15"
```

### Age & Distance

```perl
$today->age_from($birth_date);     # integer years
$d->days_until($other);            # +n if $other is future
$d->days_since($other);            # +n if $other is past
```

### Weekday Helpers

```perl
# n-th occurrence of a weekday in the current month (0=Sun..6=Sat)
my $sat = $d->nth_weekday_of_month(1, 6);   # first Saturday
my $sat = $d->last_weekday_of_month(6);     # last Saturday
my $sat = $d->next_weekday(6);              # next Saturday on/after $d
my $sat = $d->prev_weekday(6);             # prev Saturday on/before $d
```

### Date Range

```perl
my @dates = NepaliDateTime::Date->date_range($start, $end);
```

### Formatting

```perl
$d->isoformat();               # "2081-03-15"
$d->to_string();               # alias for isoformat
$d->ctime();                   # "Wed Asa 15 00:00:00 2081"
$d->format_devanagari();       # "२०८१ असार १५, बुधवार"
$d->format_nepali_date();      # "15 Asar 2081"
$d->strftime($format);
```

**`strftime` directives:**

| Code | Meaning | Example |
|---|---|---|
| `%Y` | 4-digit BS year | `2081` |
| `%y` | 2-digit BS year | `81` |
| `%K` | 4-digit year in Devanagari | `२०८१` |
| `%k` | 2-digit year in Devanagari | `८१` |
| `%m` | Month number 01–12 | `03` |
| `%n` | Month number in Devanagari | `०३` |
| `%B` | Full month name | `Asar` |
| `%b` | Abbreviated month name | `Asa` |
| `%N` | Month name in Nepali | `असार` |
| `%d` | Day of month 01–32 | `15` |
| `%D` | Day in Devanagari | `१५` |
| `%A` | Full weekday name | `Wednesday` |
| `%a` | Abbreviated weekday | `Wed` |
| `%G` | Weekday in Nepali | `बुधवार` |
| `%w` | Weekday integer 0=Sun..6=Sat | `3` |
| `%j` | Day of year 001–366 | `075` |
| `%U` | Week of year | `11` |
| `%H` | Hour 00–23 | `14` |
| `%I` | Hour 01–12 | `02` |
| `%p` | AM/PM | `PM` |
| `%M` | Minute 00–59 | `30` |
| `%S` | Second 00–59 | `00` |
| `%f` | Microseconds | `000000` |
| `%h` | Hour in Devanagari | `१४` |
| `%l` | Minute in Devanagari | `३०` |
| `%s` | Second in Devanagari | `०० ` |
| `%z` | UTC offset | `+0545` |
| `%Z` | Timezone name | `NST` |
| `%%` | Literal `%` | `%` |

### Parsing

```perl
my $d = NepaliDateTime::Date->strptime('2081-03-15',  '%Y-%m-%d');
my $d = NepaliDateTime::Date->strptime('15 Asar 2081','%d %B %Y');
my $d = NepaliDateTime::Date->strptime('15 असार',      '%d %N');
```

### Calendar Display

```perl
$d->print_calendar();                      # English, ASCII
$d->print_calendar(devanagari => 1);       # Devanagari digits & names
$d->print_year_calendar();                 # All 12 months
```

### Validation

```perl
NepaliDateTime::Date->is_valid(2081, 3, 15);  # true/false
```

---

## NepaliDateTime::DateTime

Inherits all methods of `NepaliDateTime::Date` plus time support.

### Construction

```perl
my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0);        # hh mm ss
my $dt = NepaliDateTime::DateTime->new(2081, 3, 15, 14, 30, 0, 500000); # with µs

my $now = NepaliDateTime::DateTime->now();       # current Nepal time
my $utc = NepaliDateTime::DateTime->utcnow();    # current UTC time in BS date

my $dt = NepaliDateTime::DateTime->from_timestamp(time());
my $dt = NepaliDateTime::DateTime->from_ad_datetime(2024, 7, 15, 14, 30, 0);
my $dt = NepaliDateTime::DateTime->combine($date, 14, 30, 0);
my $dt = NepaliDateTime::DateTime->strptime('2081-03-15 14:30:00', '%Y-%m-%d %H:%M:%S');
```

### Time Accessors

```perl
$dt->hour();        $dt->minute();
$dt->second();      $dt->microsecond();
$dt->date();        # NepaliDateTime::Date part
$dt->time_string(); # "14:30:00" or "14:30:00.500000"
$dt->tzname();      # "NST"
$dt->utcoffset_string(); # "+05:45"
```

### Conversion

```perl
my ($y,$m,$d,$h,$mi,$s,$us) = $dt->to_ad_datetime();
my $epoch = $dt->to_timestamp();
```

### Arithmetic

```perl
$dt->add_seconds(90);
$dt->add_minutes(30);
$dt->add_hours(5);
$dt->add_days(1);
$dt->add_months(2);
$dt->add_years(1);
$dt->replace(hour => 9, minute => 0);

my $secs = $dt2 - $dt1;   # seconds (float) between two datetimes
```

### Formatting

```perl
$dt->isoformat();           # "2081-03-15T14:30:00+05:45"
$dt->isoformat(' ');        # "2081-03-15 14:30:00+05:45"
$dt->ctime();               # "Wed Asa 15 14:30:00 2081"
$dt->strftime($format);     # same directives as Date::strftime
$dt->format_devanagari();   # "२०८१ असार १५, बुधवार १४:३०:००"
```

---

## Features Beyond the Python Package

| Feature | Description |
|---|---|
| `fiscal_year()` | Nepal fiscal year (Shrawan → Ashadh) |
| `fiscal_quarter()` | FQ1–FQ4 within fiscal year |
| `fiscal_year_start()` / `fiscal_year_end()` | First/last day of fiscal year |
| `quarter()` | Calendar quarter Q1–Q4 |
| `days_in_year()` | Total days in the BS year |
| `day_of_year()` | Day number within year |
| `week_of_year()` | Week number |
| `weekday_iso()` | ISO weekday 1=Mon..7=Sun |
| `is_weekend()` | Saturday (and optionally Friday) check |
| `add_months()` / `add_years()` | Arithmetic with clamping |
| `month_start()` / `month_end()` | Boundary dates of month |
| `year_start()` / `year_end()` | Boundary dates of year |
| `fiscal_year_start()` / `fiscal_year_end()` | Fiscal year boundaries |
| `age_from($birth)` | Age in complete years |
| `days_until()` / `days_since()` | Day distances |
| `date_range($s,$e)` | List of all dates between two dates |
| `nth_weekday_of_month($n,$wd)` | n-th weekday of the month |
| `last_weekday_of_month($wd)` | Last weekday in month |
| `next_weekday($wd)` / `prev_weekday($wd)` | Next/previous occurrence |
| `format_devanagari()` | Full Devanagari string |
| `format_nepali_date()` | "15 Asar 2081" |
| `print_calendar()` | Terminal month calendar |
| `print_year_calendar()` | 12-month terminal calendar |
| `is_valid($y,$m,$d)` | Validation without exceptions |
| `from_iso($str)` | Parse ISO string |
| `to_timestamp()` | Unix epoch conversion |
| Overloaded operators | `+`, `-`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `<=>`, `""` |

---

## Running Tests

After `perl Makefile.PL`:

```bash
make test
```

Or, straight from the source tree without building/installing anything:

```bash
prove -Ilib t/
# or
perl -Ilib t/01_date.t
perl -Ilib t/02_datetime.t
```

## Running the Demo

```bash
perl -Ilib examples/demo.pl
```

---

## Weekday Convention

This module follows the same convention as the Python `nepali_datetime` library:

| Value | Weekday |
|---|---|
| 0 | Sunday |
| 1 | Monday |
| 2 | Tuesday |
| 3 | Wednesday |
| 4 | Thursday |
| 5 | Friday |
| 6 | Saturday |

(Note: Python's built-in `datetime.weekday()` uses Monday=0. `weekday_iso()` uses the ISO convention: Monday=1 … Sunday=7.)

---

## License

MIT — see [LICENSE](LICENSE).
