#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Queue;
use FindBin ();
use lib "$FindBin::Bin/lib";
use PQTest;

# A cron's tz as a zone name, walked by Time::Keeper::Recurrence when it is
# installed: the same grammar, the zone database, and the DST answers the
# 'local' path gives. Without the module (or with PUNK_QUEUE_NO_RECURRENCE)
# nothing changes; that case runs in a child process, since the module is
# looked for once per process.

plan skip_all => 'Time::Keeper::Recurrence is not installed'
    unless eval { require Time::Keeper::Recurrence; 1 };
plan skip_all => 'PUNK_QUEUE_NO_RECURRENCE is set' if $ENV{PUNK_QUEUE_NO_RECURRENCE};

my $next = sub { Punk::Queue::Cron->next_after(@_) };
sub tk { Time::Keeper->new(zone => 'America/New_York', @_)->epoch }
sub tkr { my ($expr, $from, $zone) = @_; my $t = Time::Keeper::Recurrence->cron($expr, zone => $zone)->next(Time::Keeper->from_epoch($from)); $t ? $t->epoch : undef }

# ---- accepted, and walked in the zone ----------------------------------------
ok(Punk::Queue::Cron->check('0 3 * * *', 'America/New_York'), 'check takes an IANA name');
ok(Punk::Queue::Cron->check('0 3 * * *', 'PST8PDT'), 'and the POSIX-style names tzdata keeps');
ok(Punk::Queue::Cron->check('0 3 * * *', 'UTC'), 'UTC is still the built-in one');

my $from = tk(year => 2026, month => 3, day => 7, hour => 7);
is($next->('0 3 * * *', $from, 'America/New_York'), tk(year => 2026, month => 3, day => 8, hour => 3), '03:00 on the spring-forward day fires, in EDT');
is($next->('30 2 * * *', $from, 'America/New_York'), tk(year => 2026, month => 3, day => 9, hour => 2, minute => 30),
   '02:30 on the spring-forward day did not happen and does not fire, as with local');
my $nov = tk(year => 2026, month => 11, day => 1, hour => 0, minute => 45);
my $first = $next->('30 1 * * *', $nov, 'America/New_York');
is($first, Time::Keeper->parse('2026-11-01T01:30:00-04:00')->epoch, 'the doubled 01:30 fires at the first (DST) instance');
is($next->('30 1 * * *', $first, 'America/New_York'), Time::Keeper->parse('2026-11-02T01:30:00-05:00')->epoch, 'once: next is the following night');
my @sweep;
my $t = $first - 60;
for (1 .. 120) { $t = $next->('* * * * *', $t, 'America/New_York'); push @sweep, $t; last if $t >= Time::Keeper->parse('2026-11-01T02:00:00-05:00')->epoch }
my %seen;
is(scalar(grep { $seen{$_}++ } @sweep), 0, 'an every-minute spec never repeats an instant');
is($sweep[-1] - $sweep[0], 60 * (@sweep - 1), 'and fires every real minute through the doubled hour');
is($next->('@every 1h', 3599, 'America/New_York'), 7199, '@every is an interval in any zone');
is($next->('@daily', $from, 'Asia/Tokyo'), Time::Keeper->new(year => 2026, month => 3, day => 8, zone => 'Asia/Tokyo')->epoch, 'aliases in a zone');

# ---- the same answers as Time::Keeper::Recurrence's own cron ------------------
srand(20261019);
my @zones = qw(America/New_York Europe/London Australia/Lord_Howe Asia/Kolkata America/Sao_Paulo);
my ($agree, $total) = (0, 0);
for my $i (1 .. 300) {
    my @f = (int rand 60, rand() < 0.5 ? '*' : int rand 24, rand() < 0.7 ? '*' : 1 + int rand 28, '*', rand() < 0.6 ? '*' : int rand 7);
    my $expr = join ' ', @f;
    my $zone = $zones[int rand @zones];
    my $f0 = 1767225600 + int rand(3 * 365 * 86400);
    my $mine = $next->($expr, $f0, $zone);
    $total++;
    $agree++ if defined $mine && $mine == tkr($expr, $f0, $zone);
}
is($agree, $total, "next_after in a zone is Time::Keeper::Recurrence's next on $total random crons");

# ---- stored: the scheduler computes the next run through the same path ----------
SKIP: {
    skip 'DBI and DBD::SQLite required', 3 unless has_dbd();
    my ($q) = make_queue();
    $q->upsert_cron({ name => 'ny-three', expr => '0 3 * * *', task => 't.task', tz => 'America/New_York' });
    my $c = $q->cron_info('ny-three');
    is($c->{tz}, 'America/New_York', 'upsert_cron keeps the zone name');
    my $want = Time::Keeper::Recurrence->cron('0 3 * * *', zone => 'America/New_York')->next(Time::Keeper->from_epoch(time))->epoch;
    ok(abs($c->{next_run} - $want) < 1 && Time::Keeper->from_epoch($c->{next_run})->in_zone('America/New_York')->hour == 3, 'and its next run is 03:00 in New York');
    ok(!eval { $q->upsert_cron({ name => 'nowhere', expr => '0 3 * * *', task => 't.task', tz => 'Narnia/Lamppost' }); 1 }, 'a cron in a zone that is none is refused at upsert');
}

# ---- refused, in words that say why --------------------------------------------
{
    my $ok = eval { Punk::Queue::Cron->check('0 3 * * *', 'Narnia/Lamppost'); 1 };
    ok(!$ok, 'a name that is no zone is refused');
    like($@, qr/cron tz must be 'UTC', 'local', '\+HHMM' or a time zone name, not 'Narnia\/Lamppost'/, '  naming the choices, zone names among them');
    ok(!eval { Punk::Queue::Cron->check('0 0 30 2 *', 'Asia/Tokyo'); 1 }, 'a spec that can never fire is refused in a zone too');
    like($@, qr/can never fire/, '  in the parser\'s words');
    my $kept = `"$^X" -Mblib -MPunk::Queue -e "\\\$\@ = q{kept}; Punk::Queue::Cron->check(q{0 3 * * *}, q{Europe/Paris}); print \\\$\@" 2>&1`;
    is($kept, 'kept', 'looking for the module the first time leaves the caller\'s $@ alone');
}

# ---- and without it, nothing changes ------------------------------------------------
{
    local $ENV{PUNK_QUEUE_NO_RECURRENCE} = 1;
    my $out = `"$^X" -Mblib -MPunk::Queue -e "eval { Punk::Queue::Cron->check(q{0 3 * * *}, q{America/New_York}) }; print \\\$\@" 2>&1`;
    like($out, qr/cron tz must be 'UTC', 'local' or '\+HHMM', not 'America\/New_York'/, 'PUNK_QUEUE_NO_RECURRENCE: the built-in parser and its own words');
    my $utc = `"$^X" -Mblib -MPunk::Queue -e "print Punk::Queue::Cron->next_after(q{0 3 * * *}, 0, q{+0530})" 2>&1`;
    is($utc, 77400, '  and the built-in zones as before');
}

done_testing;
