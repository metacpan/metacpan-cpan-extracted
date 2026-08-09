#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use POSIX ();
use Punk::Queue;

# The cron parser and the occurrence walk, table-driven. Everything here
# is pure arithmetic - no database, no supervisor. The scheduler's use of
# these results is t/81-83's problem.
#
# Epochs are computed with Time::Local-free arithmetic: every `from` and
# expected occurrence below is written as a UTC epoch built by hand via
# POSIX::mktime in a UTC frame, so the table stays readable.

sub utc {
    my ($y, $mo, $d, $h, $mi, $s) = @_;
    # timegm without Time::Local: mktime in a forced-UTC frame
    local $ENV{TZ} = 'UTC';
    POSIX::tzset();
    my $t = POSIX::mktime($s // 0, $mi, $h, $d, $mo - 1, $y - 1900);
    POSIX::tzset();
    return $t;
}

my $next = sub { Punk::Queue::Cron->next_after(@_) };

# ---- the walk, UTC ----------------------------------------------------------

my @cases = (
    # expr, from, expected, name
    ['* * * * *',   utc(2026, 8, 7, 12, 30, 30), utc(2026, 8, 7, 12, 31),
     'every minute: next minute boundary'],
    ['*/15 * * * *', utc(2026, 8, 7, 12, 1),     utc(2026, 8, 7, 12, 15),
     'step minutes'],
    ['0 3 * * *',   utc(2026, 8, 7, 4, 0),       utc(2026, 8, 8, 3, 0),
     'daily, already past today'],
    ['0 3 * * *',   utc(2026, 8, 7, 2, 59),      utc(2026, 8, 7, 3, 0),
     'daily, still ahead today'],
    ['30 2 1 * *',  utc(2026, 8, 7, 0, 0),       utc(2026, 9, 1, 2, 30),
     'first of the month'],
    ['0 0 29 2 *',  utc(2026, 3, 1, 0, 0),       utc(2028, 2, 29, 0, 0),
     'Feb 29 waits for the leap year'],
    ['0 12 * * 1',  utc(2026, 8, 7, 0, 0),       utc(2026, 8, 10, 12, 0),
     'Monday noon (Aug 7 2026 is a Friday)'],
    ['0 12 * * 7',  utc(2026, 8, 7, 0, 0),       utc(2026, 8, 9, 12, 0),
     'dow 7 is Sunday'],
    ['0 12 * * 0',  utc(2026, 8, 7, 0, 0),       utc(2026, 8, 9, 12, 0),
     'dow 0 is also Sunday'],
    ['5-10 4 * * *', utc(2026, 8, 7, 4, 7),      utc(2026, 8, 7, 4, 8),
     'ranges'],
    ['0 0 * 1,7 *', utc(2026, 8, 7, 0, 0),       utc(2027, 1, 1, 0, 0),
     'month lists wrap the year'],
    ['59 23 31 12 *', utc(2026, 1, 1, 0, 0),     utc(2026, 12, 31, 23, 59),
     'last minute of the year'],
);

for my $c (@cases) {
    my ($expr, $from, $want, $name) = @$c;
    is($next->($expr, $from), $want, $name);
}

# the exclusive lower bound: an occurrence exactly at `from` is not next
is($next->('0 3 * * *', utc(2026, 8, 7, 3, 0)), utc(2026, 8, 8, 3, 0),
   'from is exclusive');

# ---- the vixie dom/dow OR rule ----------------------------------------------
#
# When BOTH day fields are restricted, a day matching EITHER fires. This
# is the most-misimplemented rule in cron; it gets its own block.

{
    # Aug 2026: the 8th is a Saturday, the 9th a Sunday.
    my $from = utc(2026, 8, 7, 13, 0);
    is($next->('0 12 8 * 0', $from), utc(2026, 8, 8, 12, 0),
       'restricted dom OR restricted dow: dom side fires first');
    is($next->('0 12 20 * 0', $from), utc(2026, 8, 9, 12, 0),
       'and the dow side when it comes sooner');
    is($next->('0 12 8 * *', $from), utc(2026, 8, 8, 12, 0),
       'dom restricted, dow free: dom is a filter');
    is($next->('0 12 * * 0', $from), utc(2026, 8, 9, 12, 0),
       'dow restricted, dom free: dow is a filter');
}

# ---- aliases and @every -----------------------------------------------------

{
    my $from = utc(2026, 8, 7, 13, 30);
    is($next->('@daily',  $from), utc(2026, 8, 8, 0, 0), '@daily');
    is($next->('@midnight', $from), utc(2026, 8, 8, 0, 0), '@midnight');
    is($next->('@hourly', $from), utc(2026, 8, 7, 14, 0), '@hourly');
    is($next->('@weekly', $from), utc(2026, 8, 9, 0, 0),
       '@weekly is Sunday midnight');
    is($next->('@monthly', $from), utc(2026, 9, 1, 0, 0), '@monthly');
    is($next->('@yearly', $from), utc(2027, 1, 1, 0, 0), '@yearly');

    # @every is interval arithmetic from the epoch, not field matching
    is($next->('@every 15m', 900),  1800, '@every 15m');
    is($next->('@every 1h',  3599), 7199,
       '@every 1h is an interval from the last occurrence, not a grid');
    is($next->('@every 30s', 30),   60,   '@every 30s');
    is($next->('@every 1d',  0),    86400, '@every 1d');
}

# ---- fixed offsets ----------------------------------------------------------

{
    # 03:00 at +0530 is 21:30 UTC the previous day
    is($next->('0 3 * * *', utc(2026, 8, 7, 12, 0), '+0530'),
       utc(2026, 8, 7, 21, 30), 'positive offset shifts the boundary');
    is($next->('0 3 * * *', utc(2026, 8, 7, 12, 0), '-0400'),
       utc(2026, 8, 8, 7, 0), 'negative offset too');
}

# ---- rejections -------------------------------------------------------------

my @bad = (
    ['',              qr/empty cron/,               'empty'],
    ['* * * *',       qr/has 4 field\(s\)/,         'four fields'],
    ['* * * * * *',   qr/more than 5 fields/,       'six fields'],
    ['61 * * * *',    qr/bad cron minute/,          'minute out of range'],
    ['* 25 * * *',    qr/bad cron hour/,            'hour out of range'],
    ['* * 0 * *',     qr/bad cron day-of-month/,    'dom 0'],
    ['* * 32 * *',    qr/bad cron day-of-month/,    'dom 32'],
    ['* * * 13 *',    qr/bad cron month/,           'month 13'],
    ['* * * * 8',     qr/bad cron day-of-week/,     'dow 8'],
    ['0 0 L * *',     qr/token 'L' is not supported/, 'L by name'],
    ['0 0 15W * *',   qr/token 'W' is not supported/, 'W by name'],
    ['0 0 * * 5#3',   qr/token '#' is not supported/, '# by name'],
    ['0 0 ? * *',     qr/token '\?' is not supported/, '? by name'],
    ['@fortnightly',  qr/unknown cron alias/,       'unknown alias'],
    ['@every 5x',     qr/\@every wants/,            'bad @every unit'],
    ['0 0 30 2 *',    qr/can never fire/,           'Feb 30 never fires'],
    ['0 0 31 4 *',    qr/can never fire/,           'Apr 31 never fires'],
);

for my $b (@bad) {
    my ($expr, $re, $name) = @$b;
    my $ok = eval { Punk::Queue::Cron->check($expr); 1 };
    ok(!$ok, "rejected: $name");
    like($@, $re, "  with the right message");
}

{
    my $ok = eval { $next->('0 3 * * *', 0, 'PST8PDT'); 1 };
    ok(!$ok, 'a tz that is not UTC/local/+HHMM is rejected');
    like($@, qr/cron tz must be/, '  by the tz parser');
}

# ---- the horizon ------------------------------------------------------------

# 2032-02-29 is within five years of 2028 - the horizon only bites
# expressions that cannot fire at all, which check() already rejects
is($next->('0 0 29 2 *', utc(2028, 2, 29, 0, 1)), utc(2032, 2, 29, 0, 0),
   'the walk crosses years to the next leap day inside the horizon');

# ---- DST, tz local ----------------------------------------------------------
#
# Only 'local' touches libc time and only 'local' has DST. Force the zone
# for this block and put it back after; every assertion re-derives its
# expectations through localtime in the same forced zone.

SKIP: {
    skip 'zoneinfo not usable on this platform', 6
        unless -e '/usr/share/zoneinfo/America/New_York';

    local $ENV{TZ} = 'America/New_York';
    POSIX::tzset();

    my $local = sub {
        my ($y, $mo, $d, $h, $mi, $isdst) = @_;
        POSIX::mktime(0, $mi, $h, $d, $mo - 1, $y - 1900, 0, 0,
                      $isdst // -1);
    };

    # Spring forward, 2026-03-08: 02:00 EST jumps to 03:00 EDT and the
    # 02:xx wall hour does not exist. A 02:30 daily cron must not fire
    # that day - and must not fire twice the next.
    my $from = $local->(2026, 3, 7, 23, 0);
    my $got  = Punk::Queue::Cron->next_after('30 2 * * *', $from, 'local');
    my @lt   = localtime $got;
    is_deeply([@lt[1, 2, 3, 4]], [30, 2, 9, 2],
              'spring forward: the skipped hour does not fire; next is '
            . 'Mar 9 02:30');

    # Fall back, 2026-11-01: 02:00 EDT returns to 01:00 EST and the
    # 01:xx wall hour happens twice. A 01:30 daily cron fires ONCE.
    $from = $local->(2026, 10, 31, 23, 0);
    my $first = Punk::Queue::Cron->next_after('30 1 * * *', $from, 'local');
    @lt = localtime $first;
    is_deeply([@lt[1, 2, 3, 4]], [30, 1, 1, 10],
              'fall back: fires at the first 01:30');
    is($lt[8], 1, 'which is the DST one');

    my $second = Punk::Queue::Cron->next_after('30 1 * * *', $first, 'local');
    @lt = localtime $second;
    is_deeply([@lt[1, 2, 3, 4]], [30, 1, 2, 10],
              'and the repeated wall hour does not fire again - next is '
            . 'Nov 2');

    # an ordinary local day still works
    $from = $local->(2026, 6, 1, 12, 0);
    $got = Punk::Queue::Cron->next_after('0 15 * * *', $from, 'local');
    @lt = localtime $got;
    is_deeply([@lt[1, 2, 3]], [0, 15, 1], 'plain local afternoon');

    POSIX::tzset();
    ok(Punk::Queue::Cron->check('30 2 * * *', 'local'),
       'check accepts local');
}

done_testing();
