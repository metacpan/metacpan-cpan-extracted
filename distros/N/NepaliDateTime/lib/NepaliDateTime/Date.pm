package NepaliDateTime::Date;

use strict;
use warnings;
use utf8;
use Carp qw(croak confess);
use POSIX qw(floor);

use NepaliDateTime::Data qw();

our $VERSION = '0.02';

=encoding utf8

=head1 NAME

NepaliDateTime::Date - Bikram Sambat date object

=head1 SYNOPSIS

    use NepaliDateTime::Date;

    # Construction
    my $d = NepaliDateTime::Date->new(2081, 3, 15);

    # Today in BS
    my $today = NepaliDateTime::Date->today();

    # From AD date
    my $bs = NepaliDateTime::Date->from_ad(2024, 7, 15);

    # Convert to AD
    my ($y, $m, $day) = $bs->to_ad();

    # From ordinal (days since BS 1975-01-01)
    my $d2 = NepaliDateTime::Date->from_ordinal(1);

    # Arithmetic
    my $d3 = $d->add_days(10);
    my $d4 = $d->add_months(3);
    my $d5 = $d->add_years(1);
    my $diff = $d3 - $d;   # integer days

    # Comparison
    print "equal\n" if $d == $d2;
    print "later\n" if $d3 > $d;

    # Formatting
    print $d->isoformat(), "\n";       # 2081-03-15
    print $d->strftime('%B %Y'), "\n"; # Asar 2081
    print $d->format_devanagari(), "\n";

    # Weekday info
    print $d->weekday(), "\n";         # 0=Sun .. 6=Sat
    print $d->day_name(), "\n";        # "Wednesday"
    print $d->day_name_np(), "\n";     # Devanagari

    # Month info
    print $d->month_name(), "\n";
    print $d->days_in_month(), "\n";
    print $d->days_in_year(), "\n";

    # Nepal fiscal year (Shrawan 1 – Ashadh end)
    my ($fy_start, $fy_end) = $d->fiscal_year();  # e.g. (2080, 2081)
    my $fq = $d->fiscal_quarter();                 # 1..4

    # Calendar quarter  (Q1=Bai-Asa, Q2=Shr-Asw, Q3=Kar-Pou, Q4=Mag-Cha)
    print $d->quarter(), "\n";

    # Date-range list
    my @dates = NepaliDateTime::Date->date_range($start, $end);

    # Print a calendar for this month
    $d->print_calendar();

=head1 DESCRIPTION

NepaliDateTime::Date represents a date in the Bikram Sambat calendar.

Supported range: BS 1975-01-01 to BS 2100-12-30.

=cut

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# days_before_year(year) – total BS days from epoch before 1st of Baisakh in year
sub _days_before_year {
    my ($year) = @_;
    my $D = \@NepaliDateTime::Data::DAYS_BEFORE_YEAR;
    return $D->[$year - $NepaliDateTime::Data::MINYEAR];
}

# days_before_month(year, month) – days in year before month 1
sub _days_before_month {
    my ($year, $month) = @_;
    return $NepaliDateTime::Data::CUMUL{$year}[$month - 1];
}

# ymd_to_ordinal(y,m,d) – ordinal where 1975-01-01 = 1
sub _ymd_to_ordinal {
    my ($year, $month, $day) = @_;
    return _days_before_year($year) + _days_before_month($year, $month) + $day;
}

# ordinal_to_ymd(n) – inverse
sub _ordinal_to_ymd {
    my ($n) = @_;
    # binary search for year
    my $D = \@NepaliDateTime::Data::DAYS_BEFORE_YEAR;
    my $lo = 0; my $hi = $#$D;
    while ($lo < $hi - 1) {
        my $mid = int(($lo + $hi) / 2);
        if ($D->[$mid] < $n) { $lo = $mid; }
        else                  { $hi = $mid; }
    }
    my $year = $NepaliDateTime::Data::MINYEAR + $lo;
    my $rem  = $n - $D->[$lo];

    # binary search for month
    my $cum = $NepaliDateTime::Data::CUMUL{$year};
    my $mlo = 0; my $mhi = 12;
    while ($mlo < $mhi - 1) {
        my $mm = int(($mlo + $mhi) / 2);
        if ($cum->[$mm] < $rem) { $mlo = $mm; }
        else                    { $mhi = $mm; }
    }
    my $month = $mlo + 1;
    my $day   = $rem - $cum->[$mlo];
    return ($year, $month, $day);
}

# _check_fields(year, month, day) – validate and die if out of range
sub _check_fields {
    my ($year, $month, $day) = @_;
    croak "year must be in $NepaliDateTime::Data::MINYEAR..$NepaliDateTime::Data::MAXYEAR, got $year"
        unless $year >= $NepaliDateTime::Data::MINYEAR && $year <= $NepaliDateTime::Data::MAXYEAR;
    croak "month must be in 1..12, got $month"
        unless $month >= 1 && $month <= 12;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$month];
    croak "day must be in 1..$dim for $year-$month, got $day"
        unless $day >= 1 && $day <= $dim;
}

# _ad_to_julian(y,m,d) – Julian Day Number from a proleptic Gregorian date
sub _ad_to_jdn {
    my ($y, $m, $d) = @_;
    return int((1461 * ($y + 4800 + int(($m - 14)/12))) / 4)
         + int((367  * ($m - 2  - 12*int(($m - 14)/12))) / 12)
         - int((3 * int(($y + 4900 + int(($m - 14)/12)) / 100)) / 4)
         + $d - 32075;
}

sub _jdn_to_ad {
    my ($jdn) = @_;
    my $l  = $jdn + 68569;
    my $n  = int((4 * $l) / 146097);
    $l  = $l - int((146097 * $n + 3) / 4);
    my $i  = int((4000 * ($l + 1)) / 1461001);
    $l  = $l - int((1461 * $i) / 4) + 31;
    my $j  = int((80 * $l) / 2447);
    my $d  = $l - int((2447 * $j) / 80);
    $l  = int($j / 11);
    my $m  = $j + 2 - 12 * $l;
    my $y  = 100 * ($n - 49) + $i + $l;
    return ($y, $m, $d);
}

# Reference AD anchor as Julian Day Number
my $_REF_JDN = _ad_to_jdn(@NepaliDateTime::Data::REFERENCE_DATE_AD);

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head1 CONSTRUCTOR

=head2 new($year, $month, $day)

Creates a new BS date. Croaks if the date is out of the supported range.

=cut

sub new {
    my ($class, $year, $month, $day) = @_;
    _check_fields($year, $month, $day);
    return bless { year => $year, month => $month, day => $day }, $class;
}

# ---------------------------------------------------------------------------
# Class methods / alternate constructors
# ---------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 today()

Returns today's date in BS (using Nepal Standard Time UTC+05:45).

=cut

sub today {
    my ($class) = @_;
    my $epoch = time() + $NepaliDateTime::Data::NEPAL_UTC_OFFSET;
    my @gm = gmtime($epoch);
    my ($ad_y, $ad_m, $ad_d) = ($gm[5]+1900, $gm[4]+1, $gm[3]);
    return $class->from_ad($ad_y, $ad_m, $ad_d);
}

=head2 from_ad($year, $month, $day)

Convert an AD (Gregorian) date to BS.

    my $bs = NepaliDateTime::Date->from_ad(2024, 7, 15);

=cut

sub from_ad {
    my ($class, $y, $m, $d) = @_;
    my $jdn  = _ad_to_jdn($y, $m, $d);
    my $diff = $jdn - $_REF_JDN;   # days since BS 1975-01-01
    my $ord  = $diff + 1;           # ordinal (1975-01-01 = 1)
    croak "AD date $y-$m-$d is before the supported BS range"
        if $ord < 1;
    croak "AD date $y-$m-$d is after the supported BS range"
        if $ord > $NepaliDateTime::Data::MAXORDINAL;
    my ($by, $bm, $bd) = _ordinal_to_ymd($ord);
    return $class->new($by, $bm, $bd);
}

=head2 from_ordinal($n)

Construct a date from its BS ordinal (BS 1975-01-01 == 1).

=cut

sub from_ordinal {
    my ($class, $n) = @_;
    croak "ordinal $n out of range 1..$NepaliDateTime::Data::MAXORDINAL"
        unless $n >= 1 && $n <= $NepaliDateTime::Data::MAXORDINAL;
    my ($y, $m, $d) = _ordinal_to_ymd($n);
    return $class->new($y, $m, $d);
}

=head2 from_timestamp($epoch)

Construct from a Unix timestamp, converting to Nepal Standard Time.

=cut

sub from_timestamp {
    my ($class, $t) = @_;
    my $epoch = $t + $NepaliDateTime::Data::NEPAL_UTC_OFFSET;
    my @gm = gmtime($epoch);
    return $class->from_ad($gm[5]+1900, $gm[4]+1, $gm[3]);
}

=head2 from_iso($string)

Parse an ISO-8601 BS date string C<YYYY-MM-DD>.

=cut

sub from_iso {
    my ($class, $str) = @_;
    $str =~ /^(\d{4})-(\d{2})-(\d{2})$/
        or croak "Invalid ISO date string '$str' (expected YYYY-MM-DD)";
    return $class->new($1+0, $2+0, $3+0);
}

=head2 date_range($start_date, $end_date)

Returns a list of all NepaliDateTime::Date objects from C<$start_date> up to
and including C<$end_date>. Both arguments must be NepaliDateTime::Date objects.

    my @week = NepaliDateTime::Date->date_range($start, $end);

=cut

sub date_range {
    my ($class, $start, $end) = @_;
    croak "start must be a NepaliDateTime::Date" unless ref $start && $start->isa('NepaliDateTime::Date');
    croak "end must be a NepaliDateTime::Date"   unless ref $end   && $end->isa('NepaliDateTime::Date');
    my $s = $start->toordinal();
    my $e = $end->toordinal();
    croak "start must be <= end" if $s > $e;
    return map { $class->from_ordinal($_) } $s .. $e;
}

=head2 min()

Returns the minimum supported date (BS 1975-01-01).

=cut

sub min { NepaliDateTime::Date->new($NepaliDateTime::Data::MINYEAR, 1, 1) }

=head2 max()

Returns the maximum supported date (BS 2100-12-30).

=cut

sub max { NepaliDateTime::Date->new($NepaliDateTime::Data::MAXYEAR, 12,
    $NepaliDateTime::Data::DAYS_IN_MONTH{$NepaliDateTime::Data::MAXYEAR}[12]) }

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

=head1 ACCESSORS

=head2 year() / month() / day()

=cut

sub year  { $_[0]{year}  }
sub month { $_[0]{month} }
sub day   { $_[0]{day}   }

# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

=head1 CONVERSION METHODS

=head2 to_ad()

Returns C<($year, $month, $day)> in the Gregorian (AD) calendar.

=cut

sub to_ad {
    my ($self) = @_;
    my $ord = $self->toordinal();     # 1975-01-01 = 1
    my $jdn = $_REF_JDN + ($ord - 1);
    return _jdn_to_ad($jdn);
}

=head2 to_ad_string()

Returns the AD date as C<"YYYY-MM-DD">.

=cut

sub to_ad_string {
    my ($self) = @_;
    my ($y, $m, $d) = $self->to_ad();
    return sprintf('%04d-%02d-%02d', $y, $m, $d);
}

=head2 toordinal()

Returns the BS ordinal: BS 1975-01-01 = 1.

=cut

sub toordinal {
    my ($self) = @_;
    return _ymd_to_ordinal($self->{year}, $self->{month}, $self->{day});
}

=head2 to_timestamp()

Returns approximate Unix timestamp for midnight of this date in Nepal time.

=cut

sub to_timestamp {
    my ($self) = @_;
    my ($y, $m, $d) = $self->to_ad();
    # Days since Unix epoch (1970-01-01)
    my $unix_jdn  = _ad_to_jdn(1970, 1, 1);
    my $this_jdn  = _ad_to_jdn($y, $m, $d);
    my $days      = $this_jdn - $unix_jdn;
    # Midnight Nepal time = epoch - offset (since Nepal is ahead of UTC)
    return $days * 86400 - $NepaliDateTime::Data::NEPAL_UTC_OFFSET;
}

# ---------------------------------------------------------------------------
# Date attributes
# ---------------------------------------------------------------------------

=head1 DATE ATTRIBUTES

=head2 weekday()

Day of the week: 0=Sunday, 1=Monday, …, 6=Saturday.

(Note: this follows the Python nepali_datetime convention where Sunday=0,
unlike Python's standard datetime where Monday=0.)

=cut

sub weekday {
    my ($self) = @_;
    return ($self->toordinal() + 5) % 7;
}

=head2 weekday_iso()

ISO weekday: 1=Monday … 7=Sunday.

=cut

sub weekday_iso {
    my ($self) = @_;
    my $w = $self->weekday();   # 0=Sun, 1=Mon, ..., 6=Sat
    # Map: Sun=0→7, Mon=1→1, ..., Sat=6→6
    return $w == 0 ? 7 : $w;
}

=head2 day_name()

Full English weekday name, e.g. C<"Wednesday">.

=cut

sub day_name {
    my ($self) = @_;
    return $NepaliDateTime::Data::WDAY_FULL[$self->weekday()];
}

=head2 day_name_abbr()

Abbreviated English weekday name, e.g. C<"Wed">.

=cut

sub day_name_abbr {
    my ($self) = @_;
    return $NepaliDateTime::Data::WDAY_ABBR[$self->weekday()];
}

=head2 day_name_np()

Weekday name in Nepali (Devanagari).

=cut

sub day_name_np {
    my ($self) = @_;
    return $NepaliDateTime::Data::WDAY_NP[$self->weekday()];
}

=head2 month_name()

Full English month name, e.g. C<"Asar">.

=cut

sub month_name {
    my ($self) = @_;
    return $NepaliDateTime::Data::MONTH_FULL[$self->{month}];
}

=head2 month_name_abbr()

Abbreviated English month name, e.g. C<"Asa">.

=cut

sub month_name_abbr {
    my ($self) = @_;
    return $NepaliDateTime::Data::MONTH_ABBR[$self->{month}];
}

=head2 month_name_np()

Month name in Nepali (Devanagari).

=cut

sub month_name_np {
    my ($self) = @_;
    return $NepaliDateTime::Data::MONTH_NP[$self->{month}];
}

=head2 days_in_month()

Number of days in the current month.

=cut

sub days_in_month {
    my ($self) = @_;
    return $NepaliDateTime::Data::DAYS_IN_MONTH{$self->{year}}[$self->{month}];
}

=head2 days_in_year()

Total number of days in the current BS year.

=cut

sub days_in_year {
    my ($self) = @_;
    return _days_in_year($self->{year});
}

sub _days_in_year {
    my ($year) = @_;
    my $cum = $NepaliDateTime::Data::CUMUL{$year};
    return $cum->[12];
}

=head2 day_of_year()

Day number within the year (1-based).

=cut

sub day_of_year {
    my ($self) = @_;
    return _days_before_month($self->{year}, $self->{month}) + $self->{day};
}

=head2 week_of_year()

Week number within the year (1-based, week starts on Sunday).

=cut

sub week_of_year {
    my ($self) = @_;
    my $jan1_wday = NepaliDateTime::Date->new($self->{year}, 1, 1)->weekday(); # 0=Sun
    my $doy = $self->day_of_year();
    return int(($doy + $jan1_wday - 1) / 7) + 1;
}

=head2 quarter()

Calendar quarter (1..4):

    Q1: Baishakh – Asar   (months 1–3)
    Q2: Shrawan  – Aswin  (months 4–6)
    Q3: Kartik   – Poush  (months 7–9)
    Q4: Magh     – Chaitra (months 10–12)

=cut

sub quarter {
    my ($self) = @_;
    return int(($self->{month} - 1) / 3) + 1;
}

=head2 fiscal_year()

Returns C<($fy_start_year, $fy_end_year)> for Nepal's fiscal year.

Nepal's fiscal year runs from 1 Shrawan (month 4) to the last day of Ashadh
(month 3) of the next year.

    my ($fy_s, $fy_e) = $date->fiscal_year();
    # e.g. for a date in 2081, month 6 → (2081, 2082)
    # e.g. for a date in 2081, month 2 → (2080, 2081)

=cut

sub fiscal_year {
    my ($self) = @_;
    my $m = $self->{month};
    my $y = $self->{year};
    if ($m >= 4) {
        return ($y, $y + 1);
    } else {
        return ($y - 1, $y);
    }
}

=head2 fiscal_quarter()

Returns the quarter (1..4) within Nepal's fiscal year:

    FQ1: Shrawan  – Aswin   (months 4–6)
    FQ2: Kartik   – Poush   (months 7–9)
    FQ3: Magh     – Asar    (months 10–3 spanning the year boundary)
    FQ4: Baishakh – Ashadh  (months 1–3, i.e. the second half of FQ3 and FQ4)

More precisely:
    FQ1: months 4,5,6
    FQ2: months 7,8,9
    FQ3: months 10,11,12
    FQ4: months 1,2,3

=cut

sub fiscal_quarter {
    my ($self) = @_;
    my $m = $self->{month};
    if ($m >= 4 && $m <= 6)  { return 1; }
    if ($m >= 7 && $m <= 9)  { return 2; }
    if ($m >= 10)             { return 3; }
    return 4;   # months 1,2,3
}

=head2 is_weekend()

Returns true (1) if the day is Saturday (the Nepal weekend day).
(Friday is a half-day in Nepal; returns 0 for Friday unless $include_friday is set.)

=cut

sub is_weekend {
    my ($self, $include_friday) = @_;
    my $w = $self->weekday();   # 0=Sun..6=Sat
    return 1 if $w == 6;       # Saturday always weekend
    return 1 if $include_friday && $w == 5;
    return 0;
}

=head2 is_holiday()

Placeholder – returns 0. Override in a subclass or supply a holiday list.

=cut

sub is_holiday { 0 }

# ---------------------------------------------------------------------------
# Arithmetic
# ---------------------------------------------------------------------------

=head1 ARITHMETIC

=head2 add_days($n)

Returns a new date C<$n> days in the future (or past for negative C<$n>).

=cut

sub add_days {
    my ($self, $n) = @_;
    my $ord = $self->toordinal() + $n;
    croak "Result out of supported BS range" if $ord < 1 || $ord > $NepaliDateTime::Data::MAXORDINAL;
    return NepaliDateTime::Date->from_ordinal($ord);
}

=head2 add_months($n)

Returns a new date C<$n> months in the future (negative for past).

If the resulting month has fewer days than the current day, the day is clamped
to the last day of that month.

=cut

sub add_months {
    my ($self, $n) = @_;
    my $total_months = ($self->{year} - $NepaliDateTime::Data::MINYEAR) * 12 + ($self->{month} - 1) + $n;
    croak "Result out of supported BS range" if $total_months < 0;
    my $ny = $NepaliDateTime::Data::MINYEAR + int($total_months / 12);
    my $nm = ($total_months % 12) + 1;
    croak "Result out of supported BS range" if $ny > $NepaliDateTime::Data::MAXYEAR;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$ny}[$nm];
    my $nd  = $self->{day} > $dim ? $dim : $self->{day};
    return NepaliDateTime::Date->new($ny, $nm, $nd);
}

=head2 add_years($n)

Returns a new date C<$n> years in the future (negative for past). Day is
clamped to month end if necessary.

=cut

sub add_years {
    my ($self, $n) = @_;
    return $self->add_months($n * 12);
}

=head2 month_start()

Returns the first day of the current month.

=cut

sub month_start {
    my ($self) = @_;
    return NepaliDateTime::Date->new($self->{year}, $self->{month}, 1);
}

=head2 month_end()

Returns the last day of the current month.

=cut

sub month_end {
    my ($self) = @_;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$self->{year}}[$self->{month}];
    return NepaliDateTime::Date->new($self->{year}, $self->{month}, $dim);
}

=head2 year_start()

Returns 1 Baishakh of the current year.

=cut

sub year_start {
    my ($self) = @_;
    return NepaliDateTime::Date->new($self->{year}, 1, 1);
}

=head2 year_end()

Returns the last day of Chaitra (month 12) of the current year.

=cut

sub year_end {
    my ($self) = @_;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$self->{year}}[12];
    return NepaliDateTime::Date->new($self->{year}, 12, $dim);
}

=head2 fiscal_year_start()

Returns the start of the fiscal year this date falls in (1 Shrawan).

=cut

sub fiscal_year_start {
    my ($self) = @_;
    my ($fy_s, undef) = $self->fiscal_year();
    return NepaliDateTime::Date->new($fy_s, 4, 1);
}

=head2 fiscal_year_end()

Returns the end of the fiscal year this date falls in (last day of Ashadh).

=cut

sub fiscal_year_end {
    my ($self) = @_;
    my (undef, $fy_e) = $self->fiscal_year();
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$fy_e}[3];
    return NepaliDateTime::Date->new($fy_e, 3, $dim);
}

=head2 age_from($birth_date)

Returns the age in complete years from C<$birth_date> to this date.

    my $age = NepaliDateTime::Date->today()->age_from($birth);

=cut

sub age_from {
    my ($self, $birth) = @_;
    croak "birth must be a NepaliDateTime::Date" unless ref $birth && $birth->isa('NepaliDateTime::Date');
    my $years = $self->{year} - $birth->{year};
    if ($self->{month} < $birth->{month} ||
        ($self->{month} == $birth->{month} && $self->{day} < $birth->{day})) {
        $years--;
    }
    return $years;
}

=head2 days_until($other)

Returns the number of days from this date to C<$other> (positive if $other is
in the future).

=cut

sub days_until {
    my ($self, $other) = @_;
    croak "argument must be a NepaliDateTime::Date" unless ref $other && $other->isa('NepaliDateTime::Date');
    return $other->toordinal() - $self->toordinal();
}

=head2 days_since($other)

Returns the number of days from C<$other> to this date.

=cut

sub days_since {
    my ($self, $other) = @_;
    return -$self->days_until($other);
}

=head2 nth_weekday_of_month($n, $weekday)

Returns the C<$n>-th occurrence (1-based) of C<$weekday> (0=Sun..6=Sat) in
the same year/month as this date.  Returns C<undef> if no such occurrence
exists (e.g. 5th Saturday in a short month).

    my $first_sat = $d->nth_weekday_of_month(1, 6);   # first Saturday
    my $second_sun = $d->nth_weekday_of_month(2, 0);  # second Sunday

=cut

sub nth_weekday_of_month {
    my ($self, $n, $weekday) = @_;
    my $first = NepaliDateTime::Date->new($self->{year}, $self->{month}, 1);
    my $first_wday = $first->weekday();
    my $offset = ($weekday - $first_wday + 7) % 7;
    my $day = 1 + $offset + ($n - 1) * 7;
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$self->{year}}[$self->{month}];
    return undef if $day > $dim;
    return NepaliDateTime::Date->new($self->{year}, $self->{month}, $day);
}

=head2 last_weekday_of_month($weekday)

Returns the last occurrence of C<$weekday> in the current month.

=cut

sub last_weekday_of_month {
    my ($self, $weekday) = @_;
    my $dim  = $NepaliDateTime::Data::DAYS_IN_MONTH{$self->{year}}[$self->{month}];
    my $last = NepaliDateTime::Date->new($self->{year}, $self->{month}, $dim);
    my $lw   = $last->weekday();
    my $offset = ($lw - $weekday + 7) % 7;
    return $last->add_days(-$offset);
}

=head2 next_weekday($weekday)

Returns the next occurrence of C<$weekday> on or after this date.

=cut

sub next_weekday {
    my ($self, $weekday) = @_;
    my $offset = ($weekday - $self->weekday() + 7) % 7;
    return $self->add_days($offset);
}

=head2 prev_weekday($weekday)

Returns the previous occurrence of C<$weekday> on or before this date.

=cut

sub prev_weekday {
    my ($self, $weekday) = @_;
    my $offset = ($self->weekday() - $weekday + 7) % 7;
    return $self->add_days(-$offset);
}

=head2 replace(%fields)

Returns a new date with some fields replaced.  Valid keys: C<year>, C<month>,
C<day>.

    my $d2 = $d->replace(day => 1);

=cut

sub replace {
    my ($self, %args) = @_;
    my $y = $args{year}  // $self->{year};
    my $m = $args{month} // $self->{month};
    my $d = $args{day}   // $self->{day};
    return NepaliDateTime::Date->new($y, $m, $d);
}

# ---------------------------------------------------------------------------
# Operators
# ---------------------------------------------------------------------------

use overload
    '+'   => \&_op_add,
    '-'   => \&_op_sub,
    '=='  => \&_op_eq,
    '!='  => \&_op_ne,
    '<'   => \&_op_lt,
    '<='  => \&_op_le,
    '>'   => \&_op_gt,
    '>='  => \&_op_ge,
    '<=>' => \&_op_cmp,
    '""'  => \&isoformat,
    fallback => 1;

sub _op_add {
    my ($self, $other, $swap) = @_;
    croak "Can only add an integer (days) to NepaliDateTime::Date" unless defined $other && !ref $other;
    return $self->add_days($other);
}

sub _op_sub {
    my ($self, $other, $swap) = @_;
    if (ref $other && $other->isa('NepaliDateTime::Date')) {
        my $d = $self->toordinal() - $other->toordinal();
        return $swap ? -$d : $d;
    }
    # subtract integer days
    croak "Can only subtract an integer (days) or another NepaliDateTime::Date"
        unless !ref $other;
    return $swap ? NepaliDateTime::Date->from_ordinal($other - $self->toordinal())
                 : $self->add_days(-$other);
}

sub _op_eq  { $_[0]->toordinal() == $_[1]->toordinal() }
sub _op_ne  { $_[0]->toordinal() != $_[1]->toordinal() }
sub _op_lt  { $_[0]->toordinal() <  $_[1]->toordinal() }
sub _op_le  { $_[0]->toordinal() <= $_[1]->toordinal() }
sub _op_gt  { $_[0]->toordinal() >  $_[1]->toordinal() }
sub _op_ge  { $_[0]->toordinal() >= $_[1]->toordinal() }
sub _op_cmp { $_[0]->toordinal() <=> $_[1]->toordinal() }

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

=head1 FORMATTING

=head2 isoformat()

Returns the date as C<"YYYY-MM-DD"> in BS.

=cut

sub isoformat {
    my ($self) = @_;
    return sprintf('%04d-%02d-%02d', $self->{year}, $self->{month}, $self->{day});
}

=head2 to_string()

Alias for C<isoformat()>. Also used by string overloading (C<"$date">).

=cut

sub to_string { $_[0]->isoformat() }

=head2 ctime()

Returns a C<ctime>-style string, e.g. C<"Wed Asa 15 00:00:00 2081">.

=cut

sub ctime {
    my ($self) = @_;
    return sprintf('%s %s %2d 00:00:00 %04d',
        $NepaliDateTime::Data::WDAY_ABBR[$self->weekday()],
        $NepaliDateTime::Data::MONTH_ABBR[$self->{month}],
        $self->{day},
        $self->{year},
    );
}

=head2 strftime($format)

Format using a strftime-like format string.

Supported directives:

    %a   Abbreviated weekday name (Sun Mon Tue …)
    %A   Full weekday name (Sunday Monday …)
    %G   Full weekday name in Nepali
    %w   Weekday as integer (0=Sun .. 6=Sat)
    %d   Day of month, zero-padded (01-32)
    %D   Day of month in Devanagari numerals
    %b   Abbreviated month name (Bai Jes Asa …)
    %B   Full month name (Baishakh Jestha Asar …)
    %N   Month name in Nepali
    %m   Month number, zero-padded (01-12)
    %n   Month number in Devanagari
    %y   2-digit year
    %Y   4-digit year
    %k   2-digit year in Devanagari
    %K   4-digit year in Devanagari
    %j   Day of year (001-366)
    %U   Week number (Sunday start)
    %H   Hour 00-23     (00 for date-only)
    %I   Hour 01-12     (00 for date-only)
    %p   AM/PM          (AM for date-only)
    %M   Minute 00-59   (00 for date-only)
    %S   Second 00-59   (00 for date-only)
    %f   Microseconds   (000000 for date-only)
    %%   Literal %

=cut

sub strftime {
    my ($self, $fmt) = @_;
    return _do_strftime($self, $fmt);
}

sub _to_np {
    my ($num_str) = @_;
    my $D = \@NepaliDateTime::Data::DIGIT_NP;
    my $r = $num_str;
    $r =~ s/(\d)/$D->[$1]/g;
    return $r;
}

sub _do_strftime {
    my ($obj, $fmt) = @_;
    my $hour   = $obj->can('hour')        ? $obj->hour()        : 0;
    my $minute = $obj->can('minute')      ? $obj->minute()      : 0;
    my $second = $obj->can('second')      ? $obj->second()      : 0;
    my $usec   = $obj->can('microsecond') ? $obj->microsecond() : 0;

    my $result = '';
    my $i = 0;
    my $n = length($fmt);
    while ($i < $n) {
        my $ch = substr($fmt, $i, 1);
        $i++;
        if ($ch ne '%') { $result .= $ch; next; }
        last if $i >= $n;
        $ch = substr($fmt, $i, 1); $i++;
        if    ($ch eq '%') { $result .= '%'; }
        elsif ($ch eq 'a') { $result .= $NepaliDateTime::Data::WDAY_ABBR[$obj->weekday()]; }
        elsif ($ch eq 'A') { $result .= $NepaliDateTime::Data::WDAY_FULL[$obj->weekday()]; }
        elsif ($ch eq 'G') { $result .= $NepaliDateTime::Data::WDAY_NP[$obj->weekday()]; }
        elsif ($ch eq 'w') { $result .= $obj->weekday(); }
        elsif ($ch eq 'd') { $result .= sprintf('%02d', $obj->day()); }
        elsif ($ch eq 'D') { $result .= _to_np(sprintf('%02d', $obj->day())); }
        elsif ($ch eq 'b') { $result .= $NepaliDateTime::Data::MONTH_ABBR[$obj->month()]; }
        elsif ($ch eq 'B') { $result .= $NepaliDateTime::Data::MONTH_FULL[$obj->month()]; }
        elsif ($ch eq 'N') { $result .= $NepaliDateTime::Data::MONTH_NP[$obj->month()]; }
        elsif ($ch eq 'm') { $result .= sprintf('%02d', $obj->month()); }
        elsif ($ch eq 'n') { $result .= _to_np(sprintf('%02d', $obj->month())); }
        elsif ($ch eq 'y') { $result .= sprintf('%02d', $obj->year() % 100); }
        elsif ($ch eq 'Y') { $result .= sprintf('%04d', $obj->year()); }
        elsif ($ch eq 'k') { $result .= _to_np(sprintf('%02d', $obj->year() % 100)); }
        elsif ($ch eq 'K') { $result .= _to_np(sprintf('%d', $obj->year())); }
        elsif ($ch eq 'j') { $result .= sprintf('%03d', $obj->can('day_of_year') ? $obj->day_of_year() : 0); }
        elsif ($ch eq 'U') {
            my $woy = $obj->can('week_of_year') ? $obj->week_of_year() : 0;
            $result .= sprintf('%02d', $woy);
        }
        elsif ($ch eq 'H') { $result .= sprintf('%02d', $hour); }
        elsif ($ch eq 'h') { $result .= _to_np(sprintf('%02d', $hour)); }
        elsif ($ch eq 'I') { $result .= sprintf('%02d', $hour % 12 || 12); }
        elsif ($ch eq 'i') { $result .= _to_np(sprintf('%02d', $hour % 12 || 12)); }
        elsif ($ch eq 'p') { $result .= $hour < 12 ? 'AM' : 'PM'; }
        elsif ($ch eq 'M') { $result .= sprintf('%02d', $minute); }
        elsif ($ch eq 'l') { $result .= _to_np(sprintf('%02d', $minute)); }
        elsif ($ch eq 'S') { $result .= sprintf('%02d', $second); }
        elsif ($ch eq 's') { $result .= _to_np(sprintf('%02d', $second)); }
        elsif ($ch eq 'f') { $result .= sprintf('%06d', $usec); }
        elsif ($ch eq 'z') {
            # UTC offset (+0545 for Nepal)
            $result .= '+0545';
        }
        elsif ($ch eq 'Z') { $result .= 'NST'; }
        else               { $result .= '%' . $ch; }
    }
    return $result;
}

=head2 strptime($class, $string, $format)

Parse a BS date string using a format string.  Returns a new
NepaliDateTime::Date.  Supports the same directives as C<strftime>.

    my $d = NepaliDateTime::Date->strptime('2081-03-15', '%Y-%m-%d');
    my $d = NepaliDateTime::Date->strptime('15 Asar 2081', '%d %B %Y');

=cut

sub strptime {
    my ($class, $str, $fmt) = @_;
    my %p = _do_strptime($str, $fmt);
    my $y = $p{Y} // croak "strptime: year not found in '$str' with format '$fmt'";
    my $m = $p{m} // croak "strptime: month not found";
    my $d = $p{d} // croak "strptime: day not found";
    return $class->new($y, $m, $d);
}

sub _do_strptime {
    my ($str, $fmt) = @_;
    # Build a regex from the format
    my %caps;
    my $regex = '';
    my $i = 0; my $n = length($fmt);
    my @order;
    while ($i < $n) {
        my $ch = substr($fmt, $i, 1); $i++;
        if ($ch ne '%') { $regex .= quotemeta($ch); next; }
        last if $i >= $n;
        $ch = substr($fmt, $i, 1); $i++;
        if    ($ch eq 'Y') { $regex .= '(?<Y>\d{4})'; push @order, 'Y'; }
        elsif ($ch eq 'y') { $regex .= '(?<y>\d{2})'; push @order, 'y'; }
        elsif ($ch eq 'm') { $regex .= '(?<m>\d{1,2})'; push @order, 'm'; }
        elsif ($ch eq 'd') { $regex .= '(?<d>\d{1,2})'; push @order, 'd'; }
        elsif ($ch eq 'B') {
            my $pat = join('|', map { quotemeta($_) } @NepaliDateTime::Data::MONTH_FULL[1..12]);
            $regex .= "(?<B>$pat)";
            push @order, 'B';
        }
        elsif ($ch eq 'b') {
            my $pat = join('|', map { quotemeta($_) } @NepaliDateTime::Data::MONTH_ABBR[1..12]);
            $regex .= "(?<b>$pat)";
            push @order, 'b';
        }
        elsif ($ch eq 'N') {
            my $pat = join('|', map { quotemeta($_) } @NepaliDateTime::Data::MONTH_NP[1..12]);
            $regex .= "(?<N>$pat)";
            push @order, 'N';
        }
        elsif ($ch eq 'A') {
            my $pat = join('|', map { quotemeta($_) } @NepaliDateTime::Data::WDAY_FULL);
            $regex .= "(?<A>$pat)";
            push @order, 'A';
        }
        elsif ($ch eq 'a') {
            my $pat = join('|', map { quotemeta($_) } @NepaliDateTime::Data::WDAY_ABBR);
            $regex .= "(?<a>$pat)";
            push @order, 'a';
        }
        elsif ($ch eq 'H') { $regex .= '(?<H>\d{1,2})'; push @order, 'H'; }
        elsif ($ch eq 'I') { $regex .= '(?<I>\d{1,2})'; push @order, 'I'; }
        elsif ($ch eq 'M') { $regex .= '(?<M2>\d{1,2})'; push @order, 'M2'; }
        elsif ($ch eq 'S') { $regex .= '(?<S>\d{1,2})'; push @order, 'S'; }
        elsif ($ch eq 'p') { $regex .= '(?<p>AM|PM|am|pm)'; push @order, 'p'; }
        elsif ($ch eq 'f') { $regex .= '(?<f>\d{1,6})'; push @order, 'f'; }
        elsif ($ch eq '%') { $regex .= '%'; }
        else               { $regex .= quotemeta('%') . quotemeta($ch); }
    }
    $str =~ /^$regex$/ or croak "strptime: '$str' does not match format '$fmt' (regex: $regex)";
    my %m;
    $m{Y}  = $+{Y}+0  if defined $+{Y};
    $m{y}  = do { my $y = $+{y}+0; $y <= 89 ? $y+2000 : $y+1900 } if defined $+{y};
    $m{Y} //= $m{y};
    $m{m}  = $+{m}+0  if defined $+{m};
    $m{d}  = $+{d}+0  if defined $+{d};
    if (defined $+{B}) {
        my %rev = map { $NepaliDateTime::Data::MONTH_FULL[$_] => $_ } 1..12;
        $m{m}  = $rev{$+{B}};
    }
    if (defined $+{b}) {
        my %rev = map { $NepaliDateTime::Data::MONTH_ABBR[$_] => $_ } 1..12;
        $m{m}  = $rev{$+{b}};
    }
    if (defined $+{N}) {
        my %rev = map { $NepaliDateTime::Data::MONTH_NP[$_] => $_ } 1..12;
        $m{m}  = $rev{$+{N}};
    }
    $m{H}  = $+{H}+0  if defined $+{H};
    $m{I}  = $+{I}+0  if defined $+{I};
    $m{M2} = $+{M2}+0 if defined $+{M2};
    $m{m}  //= $m{M2};  # avoid collision with minute (M2)
    $m{S}  = $+{S}+0  if defined $+{S};
    $m{p}  = $+{p}    if defined $+{p};
    $m{f}  = $+{f}    if defined $+{f};
    # Resolve 12-hour clock
    if (defined $m{I} && !defined $m{H}) {
        my $h = $m{I};
        if (defined $m{p} && uc($m{p}) eq 'PM') { $h += 12 unless $h == 12; }
        elsif (defined $m{p} && uc($m{p}) eq 'AM') { $h = 0 if $h == 12; }
        $m{H} = $h;
    }
    return %m;
}

=head2 format_devanagari()

Returns a nicely formatted date string entirely in Devanagari script:

    e.g. "२०८१ असार १५, बुधवार"

=cut

sub format_devanagari {
    my ($self) = @_;
    my $y  = _to_np(sprintf('%d', $self->{year}));
    my $m  = $NepaliDateTime::Data::MONTH_NP[$self->{month}];
    my $d  = _to_np(sprintf('%d', $self->{day}));
    my $wd = $NepaliDateTime::Data::WDAY_NP[$self->weekday()];
    return "$y $m $d, $wd";
}

=head2 format_nepali_date()

Returns the date as C<"DD Month YYYY"> in English month names.

=cut

sub format_nepali_date {
    my ($self) = @_;
    return sprintf('%d %s %04d',
        $self->{day},
        $NepaliDateTime::Data::MONTH_FULL[$self->{month}],
        $self->{year});
}

# ---------------------------------------------------------------------------
# Calendar display
# ---------------------------------------------------------------------------

=head1 CALENDAR

=head2 print_calendar(%opts)

Prints a month calendar to STDOUT.

Options (key-value pairs):

    devanagari => 1    Use Devanagari month name and digits
    highlight  => 1    Highlight today (ANSI colour; default on if $date == today)
    width      => 4    Column width (default 4)

=cut

sub print_calendar {
    my ($self, %opts) = @_;
    my $use_np  = $opts{devanagari} // 0;
    my $width   = $opts{width} // 4;

    my $year  = $self->{year};
    my $month = $self->{month};
    my $dim   = $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$month];

    # Header
    my $mname = $use_np ? $NepaliDateTime::Data::MONTH_NP[$month]
                        : $NepaliDateTime::Data::MONTH_FULL[$month];
    my $ystr  = $use_np ? _to_np(sprintf('%d', $year)) : sprintf('%04d', $year);
    my $header = "$mname $ystr";
    my $total_w = ($width + 1) * 7 - 1;
    printf "\n%*s\n", int(($total_w + length($header))/2), $header;

    # Weekday header (Sun first)
    my @wdays = $use_np ? @NepaliDateTime::Data::WDAY_NP : @NepaliDateTime::Data::WDAY_ABBR;
    # Truncate to $width chars
    print join(' ', map { sprintf("%-*s", $width, substr($_, 0, $width)) } @wdays), "\n";

    my $first_wday = NepaliDateTime::Date->new($year, $month, 1)->weekday();
    my $col = 0;

    # Blank cells before the 1st
    print '    ' x $first_wday;
    $col = $first_wday;

    # Today (for optional highlighting)
    my $today = NepaliDateTime::Date->today();
    my $is_this_month = ($today->{year} == $year && $today->{month} == $month);

    for my $day (1 .. $dim) {
        my $str = $use_np ? _to_np(sprintf('%d', $day)) : sprintf('%d', $day);
        if ($is_this_month && $day == $today->{day}) {
            printf("\033[1;31m%*s\033[0m", $width, $str);
        } else {
            printf('%*s', $width, $str);
        }
        $col++;
        if ($col % 7 == 0) { print "\n"; }
        else                { print ' '; }
    }
    print "\n\n";
}

=head2 print_year_calendar(%opts)

Prints calendars for all 12 months of the year, 3 months per row.

=cut

sub print_year_calendar {
    my ($self, %opts) = @_;
    for my $m (1..12) {
        NepaliDateTime::Date->new($self->{year}, $m, 1)->print_calendar(%opts);
    }
}

# ---------------------------------------------------------------------------
# Utility / class-level functions
# ---------------------------------------------------------------------------

=head1 UTILITY FUNCTIONS

=head2 NepaliDateTime::Date::days_in_month_for($year, $month)

Returns the number of days in the given BS year/month.

=cut

sub days_in_month_for {
    my ($class_or_year, $month_or_undef) = @_;
    my ($year, $month);
    if (ref $class_or_year) {
        # called as instance method
        return $class_or_year->days_in_month();
    } elsif ($class_or_year eq 'NepaliDateTime::Date') {
        ($year, $month) = ($month_or_undef, $_[2]);
    } else {
        ($year, $month) = ($class_or_year, $month_or_undef);
    }
    croak "year $year out of range" unless exists $NepaliDateTime::Data::DAYS_IN_MONTH{$year};
    croak "month $month out of range" unless $month >= 1 && $month <= 12;
    return $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$month];
}

=head2 NepaliDateTime::Date::is_valid($year, $month, $day)

Returns true if C<($year, $month, $day)> is a valid BS date.

=cut

sub is_valid {
    my ($class, $year, $month, $day) = @_;
    return 0 unless $year >= $NepaliDateTime::Data::MINYEAR && $year <= $NepaliDateTime::Data::MAXYEAR;
    return 0 unless $month >= 1 && $month <= 12;
    return 0 unless exists $NepaliDateTime::Data::DAYS_IN_MONTH{$year};
    my $dim = $NepaliDateTime::Data::DAYS_IN_MONTH{$year}[$month];
    return $day >= 1 && $day <= $dim;
}

=head2 clone()

Returns a copy of this date object.

=cut

sub clone {
    my ($self) = @_;
    return NepaliDateTime::Date->new($self->{year}, $self->{month}, $self->{day});
}

=head2 stringify()

Human-readable string (same as C<isoformat()>).  Also invoked by C<"$date">.

=cut

sub stringify { $_[0]->isoformat() }

1;

=head1 SUPPORTED B.S. DATE RANGE

1975-01-01 (= AD 1918-04-13)  to  2100-12-30 (= AD 2044-04-13 approx.)

=head1 WEEKDAY CONVENTION

    0 = Sunday
    1 = Monday
    2 = Tuesday
    3 = Wednesday
    4 = Thursday
    5 = Friday
    6 = Saturday

This matches the Python nepali_datetime convention (not Python's standard
datetime, where Monday=0).

=head1 SEE ALSO

L<NepaliDateTime::DateTime>

=cut
