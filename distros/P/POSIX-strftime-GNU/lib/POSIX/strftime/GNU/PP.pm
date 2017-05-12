#!/usr/bin/perl -c

package POSIX::strftime::GNU::PP;

=head1 NAME

POSIX::strftime::GNU::PP - Pure-Perl extension for POSIX::strftime::GNU

=head1 SYNOPSIS

  $ export PERL_POSIX_STRFTIME_GNU_PP=1

=head1 DESCRIPTION

This is PP extension for POSIX::strftime which implements more character
sequences compatible with GNU systems.

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.0305';

use Carp ();
use POSIX ();
use Time::Local ();

use constant SEC   => 0;
use constant MIN   => 1;
use constant HOUR  => 2;
use constant MDAY  => 3;
use constant MON   => 4;
use constant YEAR  => 5;
use constant WDAY  => 6;
use constant YDAY  => 7;
use constant ISDST => 8;

use constant HAS_TZNAME => do {
    local $ENV{TZ} = 'Europe/London';
    !!(POSIX::strftime("%Z",0,0,0,1,6,114) eq 'BST');
};

# $str = tzoffset (@time)
#
# Returns the C<+hhmm> or C<-hhmm> numeric timezone (the hour and minute offset
# from UTC).

my $tzoffset = sub {
    my ($colons, @t) = @_;

    # Normalize @t array, we need seconds without frac
    $t[SEC] = int $t[SEC];

    my $diff = (exists $ENV{TZ} and $ENV{TZ} eq 'GMT')
             ? 0
             : Time::Local::timegm(@t) - Time::Local::timelocal(@t);

    my $h = $diff / 60 / 60;
    my $m = $diff / 60 % 60;
    my $s = $diff % 60;

    if ($colons == 0) {
        return sprintf '%+03d%02u', $h, $m;
    }
    elsif ($colons == 1) {
        return sprintf '%+03d:%02u', $h, $m;
    }
    elsif ($colons == 2) {
        return sprintf '%+03d:%02u:%02u', $h, $m, $s;
    }
    elsif ($colons == 3) {
        if ($s) {
            return sprintf '%+03d:%02u:%02u', $h, $m, $s;
        } elsif ($m) {
            return sprintf '%+03d:%02u', $h, $m;
        } else {
            return sprintf '%+03d', $h;
        }
    }
    else {
        return '%%' . ':' x $colons . 'z';
    };
};

my @offset2zone = qw(
    -11       0 SST     -11       0 SST
    -10       0 HAST    -09       1 HADT
    -10       0 HST     -10       0 HST
    -09:30    0 MART    -09:30    0 MART
    -09       0 AKST    -08       1 AKDT
    -09       0 GAMT    -09       0 GAMT
    -08       0 PST     -07       1 PDT
    -08       0 PST     -08       0 PST
    -07       0 MST     -06       1 MDT
    -07       0 MST     -07       0 MST
    -06       0 CST     -05       1 CDT
    -06       0 GALT    -06       0 GALT
    -05       0 ECT     -05       0 ECT
    -05       0 EST     -04       1 EDT
    -05       1 EASST   -06       0 EAST
    -04:30    0 VET     -04:30    0 VET
    -04       0 AMT     -04       0 AMT
    -04       0 AST     -03       1 ADT
    -03:30    0 NST     -02:30    1 NDT
    -03       0 ART     -03       0 ART
    -03       0 PMST    -02       1 PMDT
    -03       1 AMST    -04       0 AMT
    -03       1 WARST   -03       1 WARST
    -02       0 FNT     -02       0 FNT
    -02       1 UYST    -03       0 UYT
    -01       0 AZOT    +00       1 AZOST
    -01       0 CVT     -01       0 CVT
    +00       0 GMT     +00       0 GMT
    +00       0 WET     +01       1 WEST
    +01       0 CET     +02       1 CEST
    +01       0 WAT     +01       0 WAT
    +02       0 EET     +02       0 EET
    +02       0 IST     +03       1 IDT
    +02       1 WAST    +01       0 WAT
    +03       0 FET     +03       0 FET
    +03:07:04 0 zzz     +03:07:04 0 zzz
    +03:30    0 IRST    +04:30    1 IRDT
    +04       0 AZT     +05       1 AZST
    +04       0 GST     +04       0 GST
    +04:30    0 AFT     +04:30    0 AFT
    +05       0 DAVT    +07       0 DAVT
    +05       0 MVT     +05       0 MVT
    +05:30    0 IST     +05:30    0 IST
    +05:45    0 NPT     +05:45    0 NPT
    +06       0 BDT     +06       0 BDT
    +06:30    0 CCT     +06:30    0 CCT
    +07       0 ICT     +07       0 ICT
    +08       0 HKT     +08       0 HKT
    +08:45    0 CWST    +08:45    0 CWST
    +09       0 JST     +09       0 JST
    +09:30    0 CST     +09:30    0 CST
    +10       0 PGT     +10       0 PGT
    +10:30    1 CST     +09:30    0 CST
    +11       0 CAST    +08       0 WST
    +11       0 NCT     +11       0 NCT
    +11       1 EST     +10       0 EST
    +11       1 LHST    +10:30    0 LHST
    +11:30    0 NFT     +11:30    0 NFT
    +12       0 FJT     +12       0 FJT
    +13       0 TKT     +13       0 TKT
    +13       1 NZDT    +12       0 NZST
    +13:45    1 CHADT   +12:45    0 CHAST
    +14       0 LINT    +14       0 LINT
    +14       1 WSDT    +13       0 WST
);

# $str = tzname (@time)
#
# Returns the abbreviation of the time zone (e.g. "UTC" or "CEST").

my $tzname = HAS_TZNAME ? sub { '%Z' } : sub {
    my @t = @_;

    return 'GMT' if exists $ENV{TZ} and $ENV{TZ} eq 'GMT';

    my $diff = $tzoffset->(3, @t);

    my @t1 = my @t2 = @t;
    @t1[MDAY,MON] = (1, 1);  # winter
    @t2[MDAY,MON] = (1, 7);  # summer

    my $diff1 = $tzoffset->(3, @t1);
    my $diff2 = $tzoffset->(3, @t2);

    for (my $i=0; $i < @offset2zone; $i += 6) {
        next unless $offset2zone[$i] eq $diff1 and $offset2zone[$i+3] eq $diff2;
        return $diff2 eq $diff ? $offset2zone[$i+5] : $offset2zone[$i+2];
    }

    if ($diff =~ /^([+-])(\d\d)$/) {
        return sprintf 'GMT%s%d', $1 eq '-' ? '+' : '-', $2;
    };

    return 'Etc';
};

use constant ISO_WEEK_START_WDAY => 1;  # Monday
use constant ISO_WEEK1_WDAY      => 4;  # Thursday
use constant YDAY_MINIMUM        => -366;
use constant TM_YEAR_BASE        => 1900;

# ($days, $year_adjust) = isodaysnum (@time)
#
# Returns the number of the year's day based on ISO-8601 standard and year
# adjust value.

my $isodaysnum = sub {
    my @t = @_;

    my $isleap = sub {
        my ($year) = @_;
        return (($year) % 4 == 0 && (($year) % 100 != 0 || ($year) % 400 == 0));
    };

    my $iso_week_days = sub {
        my ($yday, $wday) = @_;

        # Add enough to the first operand of % to make it nonnegative.
        my $big_enough_multiple_of_7 = (int(- YDAY_MINIMUM / 7) + 2) * 7;
        return ($yday
                - ($yday - $wday + ISO_WEEK1_WDAY + $big_enough_multiple_of_7) % 7
                + ISO_WEEK1_WDAY - ISO_WEEK_START_WDAY);
    };

    # Normalize @t array, we need WDAY
    $t[SEC] = int $t[SEC];
    @t = gmtime Time::Local::timegm(@t);

    # YEAR is a leap year if and only if (tp->tm_year + TM_YEAR_BASE)
    # is a leap year, except that YEAR and YEAR - 1 both work
    # correctly even when (tp->tm_year + TM_YEAR_BASE) would
    # overflow.
    my $year = ($t[YEAR] + ($t[YEAR] < 0 ? TM_YEAR_BASE % 400 : TM_YEAR_BASE % 400 - 400));
    my $year_adjust = 0;
    my $days = $iso_week_days->($t[YDAY], $t[WDAY]);

    if ($days < 0) {
        # This ISO week belongs to the previous year.
        $year_adjust = -1;
        $days = $iso_week_days->($t[YDAY] + (365 + $isleap->($year - 1)), $t[WDAY]);
    }
    else {
        my $d = $iso_week_days->($t[YDAY] - (365 + $isleap->($year)), $t[WDAY]);
        if ($d >= 0) {
            # This ISO week belongs to the next year.  */
            $year_adjust = 1;
            $days = $d;
        };
    };

    return ($days, $year_adjust);
};

# $num = isoyearnum (@time)
#
# Returns the number of the year based on ISO-8601 standard. See
# L<http://en.wikipedia.org/wiki/ISO_8601> for details.

my $isoyearnum = sub {
    my @t = @_;
    my ($days, $year_adjust) = $isodaysnum->(@t);
    return sprintf '%04d', $t[YEAR] + TM_YEAR_BASE + $year_adjust;
};

# $num = isoweeknum (@time)
#
# Returns the number of the week based on ISO-8601 standard. See
# L<http://en.wikipedia.org/wiki/ISO_8601> for details.

my $isoweeknum = sub {
    my @t = @_;
    my ($days, $year_adjust) = $isodaysnum->(@t);
    return sprintf '%02d', int($days / 7) + 1;
};


=head1 FUNCTIONS

=head2 strftime_orig

  $str = strftime_orig (@time)

This is original L<POSIX::strftime|POSIX/strftime> function.

=cut

*strftime_orig = *POSIX::strftime;

my %format = (
    C => sub { 19 + int $_[YEAR] / 100 },
    D => sub { '%m/%d/%y' },
    e => sub { sprintf '%2d', $_[MDAY] },
    F => sub { '%Y-%m-%d' },
    G => $isoyearnum,
    g => sub { sprintf '%02d', $isoyearnum->(@_) % 100 },
    h => sub { '%b' },
    k => sub { sprintf '%2d', $_[HOUR] },
    l => sub { sprintf '%2d', $_[HOUR] % 12 + ($_[HOUR] % 12 == 0 ? 12 : 0) },
    n => sub { "\n" },
    N => sub { substr sprintf('%.9f', $_[SEC] - int $_[SEC]), 2 },
    P => sub { lc strftime_orig('%p', @_) },
    r => sub { '%I:%M:%S %p' },
    R => sub { '%H:%M' },
    s => sub { int Time::Local::timegm(@_) },
    t => sub { "\t" },
    T => sub { '%H:%M:%S' },
    u => sub { my $dw = strftime_orig('%w', @_); $dw += ($dw == 0 ? 7 : 0); $dw },
    V => $isoweeknum,
    z => $tzoffset,
    Z => $tzname,
    '%' => sub { '%%' },
);

my $formats = join '', sort keys %format;


=head2 strftime

  $str = strftime($format, @time)

This is replacement for L<POSIX::strftime|POSIX/strftime> function.

The non-POSIX feature is that seconds can be float number.

=cut

sub strftime {
    my ($fmt, @t) = @_;

    Carp::croak 'Usage: POSIX::strftime::GNU::PP::strftime(fmt, sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)'
        unless @t >= 6 and @t <= 9;

    my $strftime_modifier = sub {
        my ($prefix, $modifier, $format, @t) = @_;
        my $suffix = '';

        no warnings 'uninitialized';
        my $str = strftime("%$format", @t);

        for (;;) {
            if ($modifier eq '_' and $suffix !~ /0/ or $modifier eq '-' and $suffix !~ /0/ and $format =~ /[aAbBDFhnpPrRtTxXZ%]$/) {
                $str =~ s/^([+-])(0+)(\d:.*?|\d$)/' ' x length($2) . $1 . $3/ge;
                $str =~ s/^(0+)(.+?)$/' ' x length($1) . $2/ge;
            }
            elsif ($modifier eq '-' and $suffix !~ /0/ and $format =~ /[CdgGHIjmMNsSuUVwWyYz]$/) {
                $str =~ s/^([+-])(0+)(\d:.*?|\d$)/$1$3/g;
                $str =~ s/^(0+)(.+?)$/$2/g;
            }
            elsif ($modifier eq '-') {
                $str =~ s/^ +//ge;
            }
            elsif ($modifier eq '0' and $suffix !~ /_/) {
                $str =~ s/^( +)/'0' x length($1)/ge;
            }
            elsif ($modifier eq '^' and "$prefix$suffix" =~ /#/ and $format =~ /Z$/) {
                $str = lc($str);
            }
            elsif ($modifier eq '^' and $format !~ /[pP]$/) {
                $str = uc($str);
            }
            elsif ($modifier eq '#' and $format =~ /[aAbBh]$/) {
                $str = uc($str);
            }
            elsif ($modifier eq '#' and $format =~ /[pZ]$/) {
                $str = lc($str);
            };

            last unless $prefix =~ s/(.)$//;
            $suffix = "$modifier$suffix";
            $modifier = $1;
        };

        return $str;
    };

    my $strftime_0z = sub {
        my ($digits, $format, @t) = @_;
        $digits --;
        my $str = strftime($format, @t);
        $str =~ /^([+-])(.*)$/ or return $format;
        return $1 . sprintf "%0${digits}s", $2;
    };

    # recursively handle modifiers
    $fmt =~ s/%([_0\^#-]*)([_0\^#-])((?:[1-9][0-9]*)?:*[EO]?[a-zA-Z])/$strftime_modifier->($1, $2, $3, @t)/ge;
    $fmt =~ s/%([_0\^#-]*)([_0\^#-])((?:[1-9][0-9]*)?[%])/$strftime_modifier->($1, $2, $3, @t) . '%'/ge;

    # numbers before character
    $fmt =~ s/%([1-9][0-9]*)([EO]?[aAbBDeFhklnpPrRtTxXZ])/sprintf("%$1s", strftime("%$2", @t))/ge;
    $fmt =~ s/%([1-9][0-9]*)([%])/sprintf("%$1s%%", '%')/ge;
    $fmt =~ s/%([1-9][0-9]*)([EO]?[CdGgHIjmMsSuUVwWyY])/sprintf("%0$1s", strftime("%$2", @t))/ge;
    $fmt =~ s/%([1-9][0-9]*)([N])/sprintf("%0$1.$1s", strftime("%$2", @t))/ge;
    $fmt =~ s/%([1-9][0-9]*)(:*[z])/$strftime_0z->($1, "%$2", @t)/ge;

    # "E", "O", ":" modifiers
    $fmt =~ s/%E([CcXxYy])/%$1/;
    $fmt =~ s/%O([deHIMmSUuVWwy])/%$1/;
    $fmt =~ s/%(:{0,3})?(z)/$format{$2}->(length $1, @t)/ge;

    # supported by Pure Perl
    $fmt =~ s/%([$formats])/$format{$1}->(@t)/ge;

    # as-is if there is some modifiers left
    $fmt =~ s/%([_0\^#-]+(?:[1-9][0-9]*)?|[_0\^#-]?(?:[1-9][0-9]*))([a-zA-Z%])/%%$1$2/;

    return strftime_orig($fmt, @t);
};

1;


=head1 PERFORMANCE

The PP module is about 10 times slower than XS module.

=head1 SEE ALSO

L<POSIX::strftime::GNU>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012-2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

ISO 8601 functions:

Copyright (c) 1991-2001, 2003-2007, 2009-2012 Free Software Foundation, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

See L<http://dev.perl.org/licenses/artistic.html>
