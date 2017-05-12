#!/usr/bin/perl -c

package POSIX::strftime::GNU;

=head1 NAME

POSIX::strftime::GNU - strftime with GNU extensions

=head1 SYNOPSIS

  use POSIX::strftime::GNU;
  use POSIX 'strftime';
  print POSIX::strftime('%a, %d %b %Y %T %z', localtime);

command line:

  C:\> set PERL_ANYEVENT_LOG=filter=debug
  C:\> perl -MPOSIX::strftime::GNU -MAnyEvent -e "AE::cv->send"

=head1 DESCRIPTION

This is a wrapper for L<POSIX::strftime|POSIX/strftime> which implements more
character sequences compatible with GNU systems.

The module is 100% compatible with format of date(1) command from GNU
coreutils package.

It can be helpful if you run some software on operating system where these
extensions, especially C<%z> sequence, are not supported, i.e. on Microsoft
Windows. On such system some software can work incorrectly, i.e. logging for
L<Plack> and L<AnyEvent> modules might be broken.

Even GNU C Library's strftime(3) function does not provide 100% compatibility
with date(1) command so this module can be useful also on Linux.

The XS module is used if compiler is available and can module can be loaded.
The XS is mandatory if C<PERL_POSIX_STRFTIME_GNU_XS> environment variable is
true.

The PP module is used when XS module can not be loaded or
C<PERL_POSIX_STRFTIME_GNU_PP> environment variable is true.

None of these modules are loaded if both C<PERL_POSIX_STRFTIME_GNU_PP> and
C<PERL_POSIX_STRFTIME_GNU_XS> environment variables are defined and false.

=for readme stop

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.0305';

use Carp ();
use POSIX ();

=head1 FUNCTIONS

=head2 strftime

  $str = strftime($format, @time)

This is replacement for L<POSIX::strftime|POSIX/strftime> function.

The nanoseconds can be given as a fraction of seconds.

  use POSIX::strftime::GNU;
  use Time::HiRes qw(gettimeofday);
  my ($t, $nsec) = gettimeofday;
  my @t = localtime $t;
  $t[0] += $nsec / 10e5;
  print strftime('%N', @t);

=cut

my ($xs_loaded, $pp_loaded);

my $xs_env = $ENV{PERL_POSIX_STRFTIME_GNU_XS};
my $pp_env = $ENV{PERL_POSIX_STRFTIME_GNU_PP};

if (
     (not defined $xs_env or defined $xs_env and $xs_env )
        and
     (not defined $pp_env or defined $pp_env and not $pp_env )
) {
    $xs_loaded = eval {
        require POSIX::strftime::GNU::XS;
        no warnings 'once';
        *strftime = *POSIX::strftime::GNU::XS::strftime;
        1;
    };
    die $@ if $@ and $ENV{PERL_POSIX_STRFTIME_GNU_XS};
};

if (not $xs_loaded and (not defined $pp_env or defined $pp_env and $pp_env)) {
    require POSIX::strftime::GNU::PP;
    no warnings 'once';
    *strftime = *POSIX::strftime::GNU::PP::strftime;
    $pp_loaded = 1;
};

sub import {
    my ($class) = @_;
    *POSIX::strftime = *strftime if $xs_loaded or $pp_loaded;
    return 1;
};

1;


=head1 FORMAT

The format argument is composed of zero or more conversion specifications.
Each conversion specification is composed of a C<%> (percent) character
followed by one or two conversion characters which specify the replacement
required.

There are some extensions of ANSI C (unmarked): those given in the Single UNIX
Specification (marked SU), those given in Olson's timezone package (marked
TZ), and those given in glibc (marked GNU).

The following conversion specifications are supported:

=over

=item C<%a>

The abbreviated weekday name according to the current locale.

=item C<%A>

The full weekday name according to the current locale.

=item C<%b>

The abbreviated month name according to the current locale.

=item C<%B>

The full month name according to the current locale.

=item C<%c>

The preferred date and time representation for the current locale.

=item C<%C>

The century number (year/100) as a 2-digit integer. (SU)

=item C<%d>

The day of the month as a decimal number (range 01 to 31).

=item C<%D>

Equivalent to C<%m/%d/%y>. (for Americans only: Americans should note that in
other countries C<%d/%m/%y> is rather common. This means that in international
context this format is ambiguous and should not be used.) (SU)

=item C<%e>

Like C<%d>, the day of the month as a decimal number, but a leading zero is
replaced by a space. (SU)

=item C<%E>

Modifier: use alternative format, see below. (SU)

=item C<%F>

Equivalent to C<%Y-%m-%d> (the ISO 8601 date format). (C99)

=item C<%G>

The ISO 8601 week-based year (see NOTES) with century as a decimal number. The
4-digit year corresponding to the ISO week number (see C<%V>). This has the
same format and value as %Y, except that if the ISO week number belongs to the
previous or next year, that year is used instead. (TZ)

=item C<%g>

Like C<%G>, but without century, that is, with a 2-digit year (00-99). (TZ)

=item C<%h>

Equivalent to C<%b>. (SU)

=item C<%H>

The hour as a decimal number using a 24-hour clock (range 00 to 23).

=item C<%I>

The hour as a decimal number using a 12-hour clock (range 01 to 12).

=item C<%j>

The day of the year as a decimal number (range 001 to 366).

=item C<%k>

The hour (24-hour clock) as a decimal number (range 0 to 23); single digits
are preceded by a blank. (See also C<%H>.) (TZ)

=item C<%l>

The hour (12-hour clock) as a decimal number (range 1 to 12); single digits
are preceded by a blank. (See also C<%I>.) (TZ)

=item C<%m>

The month as a decimal number (range 01 to 12).

=item C<%M>

The minute as a decimal number (range 00 to 59).

=item C<%n>

A newline character. (SU)

=item C<%N>

Nanoseconds (range 000000000 to 999999999). It is a non-POSIX extension and
outputs a nanoseconds if there is floating seconds argument.

=item C<%O>

Modifier: use alternative format, see below. (SU)

=item C<%p>

Either "AM" or "PM" according to the given time value, or the corresponding
strings for the current locale. Noon is treated as "PM" and midnight as "AM".

=item C<%P>

Like C<%p> but in lowercase: "am" or "pm" or a corresponding string for the
current locale. (GNU)

=item C<%r>

The time in a.m. or p.m. notation. In the POSIX locale this is equivalent to
C<%I:%M:%S %p>. (SU)

=item C<%R>

The time in 24-hour notation (%H:%M). (SU) For a version including the
seconds, see C<%T> below.

=item C<%s>

The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC). (TZ)

=item C<%S>

The second as a decimal number (range 00 to 60). (The range is up to 60 to
allow for occasional leap seconds.)

=item C<%t>

A tab character. (SU)

=item C<%T>

The time in 24-hour notation (C<%H:%M:%S>). (SU)

=item C<%u>

The day of the week as a decimal, range 1 to 7, Monday being 1. See also
C<%w>. (SU)

=item C<%U>

The week number of the current year as a decimal number, range 00 to 53,
starting with the first Sunday as the first day of week 01. See also C<%V> and
C<%W>.

=item C<%V>

The ISO 8601 week number (see NOTES) of the current year as a decimal number,
range 01 to 53, where week 1 is the first week that has at least 4 days in the
new year. See also C<%U> and C<%W>. (SU)

=item C<%w>

The day of the week as a decimal, range 0 to 6, Sunday being 0. See also
C<%u>.

=item C<%W>

The week number of the current year as a decimal number, range 00 to 53,
starting with the first Monday as the first day of week 01.

=item C<%x>

The preferred date representation for the current locale without the time.

=item C<%X>

The preferred time representation for the current locale without the date.

=item C<%y>

The year as a decimal number without a century (range 00 to 99).

=item C<%Y>

The year as a decimal number including the century.

=item C<%z>

The C<+hhmm> or C<-hhmm> numeric timezone (that is, the hour and minute offset
from UTC). (SU)

=item C<%Z>

The timezone or name or abbreviation.

=item C<%+>

The date and time in date(1) format. (TZ) (Not supported in glibc2.)

=item C<%%>

A literal C<%> character.

=back

Some conversion specifications can be modified by preceding the conversion
specifier character by the C<E> or C<O> modifier to indicate that an
alternative format should be used. If the alternative format or specification
does not exist for the current locale, the behavior will be as if the
unmodified conversion specification were used. (SU) The Single UNIX
Specification mentions C<%Ec>, C<%EC>, C<%Ex>, C<%EX>, C<%Ey>, C<%EY>, C<%Od>,
C<%Oe>, C<%OH>, C<%OI>, C<%Om>, C<%OM>, C<%OS>, C<%Ou>, C<%OU>, C<%OV>,
C<%Ow>, C<%OW>, C<%Oy>, where the effect of the C<O> modifier is to use
alternative numeric symbols (say, roman numerals), and that of the C<E>
modifier is to use a locale-dependent alternative representation.

C<%G>, C<%g>, and C<%V> yield values calculated from the week-based year
defined by the ISO 8601 standard. In this system, weeks start on a Monday, and
are numbered from 01, for the first week, up to 52 or 53, for the last week.
Week 1 is the first week where four or more days fall within the new year (or,
synonymously, week 01 is: the first week of the year that contains a Thursday;
or, the week that has 4 January in it). When three of fewer days of the first
calendar week of the new year fall within that year, then the ISO 8601
week-based system counts those days as part of week 53 of the preceding year.
For example, 1 January 2010 is a Friday, meaning that just three days of that
calendar week fall in 2010. Thus, the ISO 8601 week- based system considers
these days to be part of week 53 (C<%V>) of the year 2009 (C<%G>) ; week 01 of
ISO 8601 year 2010 starts on Monday, 4 January 2010.

Glibc provides some extensions for conversion specifications. (These
extensions are not specified in POSIX.1-2001, but a few other systems provide
similar features.) Between the C<%> character and the conversion specifier
character, an optional flag and field width may be specified. (These precede
the C<E> or C<O> modifiers, if present.)

The following flag characters are permitted:

=over

=item C<_>

(underscore) Pad a numeric result string with spaces.

=item C<->

(dash) Do not pad a numeric result string.

=item C<0>

Pad a numeric result string with zeros even if the conversion specifier
character uses space-padding by default.

=item C<^>

Convert alphabetic characters in result string to upper case.

=item C<#>

Swap the case of the result string. (This flag only works with certain
conversion specifier characters, and of these, it is only really useful with
C<%Z>.)

=back

=for readme continue

=head1 INSTALLING

=head2 Cygwin

This module requires C<libcrypt-devel> package.

=head1 BUGS

Timezone name is guessed with several heuristics so it can differ from
timezone name returned by date(1) command.

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-POSIX-strftime-GNU/issues>

The code repository is available at
L<http://github.com/dex4er/perl-POSIX-strftime-GNU>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012-2014 Piotr Roszatycki <dexter@cpan.org>.

Format specification is based on strftime(3) manual page which is a part of
the Linux man-pages project.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
