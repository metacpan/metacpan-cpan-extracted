use strict;
use warnings;
use Test::More;
use POSIX qw(mktime strftime);
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use_ok 'NBI::EcoScheduler';

# ---------------------------------------------------------------------------
# Helper: build an epoch for a given date/time without depending on the clock.
# mktime args: (sec, min, hour, mday, mon0, year_since_1900)
# ---------------------------------------------------------------------------
sub epoch_for {
    my ($year, $mon, $day, $h, $m, $s) = @_;
    return mktime($s // 0, $m // 0, $h // 0, $day, $mon - 1, $year - 1900);
}

# Verify day-of-week for our fixed dates (sanity check on the test framework)
{
    my $mon = epoch_for(2026, 3, 16, 7, 0);   # Monday
    my $fri = epoch_for(2026, 3, 20, 18, 0);  # Friday
    my $sat = epoch_for(2026, 3, 21, 2, 0);   # Saturday
    my $sun = epoch_for(2026, 3, 22, 14, 0);  # Sunday
    is( (localtime($mon))[6], 1, "2026-03-16 is Monday (dow=1)" );
    is( (localtime($fri))[6], 5, "2026-03-20 is Friday (dow=5)" );
    is( (localtime($sat))[6], 6, "2026-03-21 is Saturday (dow=6)" );
    is( (localtime($sun))[6], 0, "2026-03-22 is Sunday (dow=0)" );
}

# ---------------------------------------------------------------------------
# _parse_window_string
# ---------------------------------------------------------------------------
{
    my $midnight = epoch_for(2026, 3, 16, 0, 0);
    my @w = NBI::EcoScheduler::_parse_window_string('00:00-06:00', $midnight);
    is(scalar @w, 1, "_parse_window_string: single window");
    is($w[0][0], $midnight,           "window start = midnight");
    is($w[0][1], $midnight + 6*3600,  "window end = 06:00");

    my @w2 = NBI::EcoScheduler::_parse_window_string('00:00-07:00,11:00-16:00', $midnight);
    is(scalar @w2, 2, "_parse_window_string: two windows");
    is($w2[1][0], $midnight + 11*3600, "second window start = 11:00");
    is($w2[1][1], $midnight + 16*3600, "second window end = 16:00");
}

# ---------------------------------------------------------------------------
# _job_overlaps_avoid
# ---------------------------------------------------------------------------
{
    my $midnight = epoch_for(2026, 3, 16, 0, 0);
    my @avoid = NBI::EcoScheduler::_parse_window_string('17:00-20:00', $midnight);

    # 2-hour job starting at 02:00 — no overlap
    ok( !NBI::EcoScheduler::_job_overlaps_avoid($midnight + 2*3600,  2, \@avoid),
        "2h job at 02:00 does not overlap 17:00-20:00" );

    # 20-hour job starting at 00:00 — ends 20:00, touches avoid window
    ok(  NBI::EcoScheduler::_job_overlaps_avoid($midnight,          20, \@avoid),
        "20h job at 00:00 overlaps 17:00-20:00" );

    # 16-hour job starting at 01:00 — ends 17:00, boundary: end==avoid_start
    # overlap = start < avoid_end AND end > avoid_start → 17:00 > 17:00 is FALSE
    ok( !NBI::EcoScheduler::_job_overlaps_avoid($midnight + 1*3600, 16, \@avoid),
        "16h job ending exactly at 17:00 does NOT overlap avoid window" );

    # 17-hour job starting at 01:00 — ends 18:00
    ok(  NBI::EcoScheduler::_job_overlaps_avoid($midnight + 1*3600, 17, \@avoid),
        "17h job ending at 18:00 overlaps avoid window" );
}

# ---------------------------------------------------------------------------
# epoch_to_slurm / format_delay
# ---------------------------------------------------------------------------
{
    my $epoch = epoch_for(2026, 3, 17, 0, 0);
    is( NBI::EcoScheduler::epoch_to_slurm($epoch),
        '2026-03-17T00:00:00', "epoch_to_slurm round-trips correctly" );

    is( NBI::EcoScheduler::format_delay($epoch, $epoch),         "now",     "delay=0 -> 'now'" );
    is( NBI::EcoScheduler::format_delay($epoch + 45,   $epoch),  "now",     "delay=45s -> 'now'" );
    is( NBI::EcoScheduler::format_delay($epoch + 2700, $epoch),  "45m",     "delay=45m" );
    is( NBI::EcoScheduler::format_delay($epoch + 7500, $epoch),  "2h 05m",  "delay=2h 5m" );
    is( NBI::EcoScheduler::format_delay($epoch + 90000,$epoch),  "1d 1h 00m","delay=1d 1h" );
}

# ---------------------------------------------------------------------------
# find_eco_begin — Tier 1 scenarios
# ---------------------------------------------------------------------------

# Monday 07:00 — just AFTER the weekday window (00:00-06:00).
# Expected: Tuesday 2026-03-17 00:00:00  (Tier 1, 2h job fits in 6h window)
{
    my $now  = epoch_for(2026, 3, 16, 7, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(2, {}, $now);
    ok( defined $e, "Monday 07:00: slot found" );
    is( $tier, 1,   "Monday 07:00: Tier 1" );
    is( NBI::EcoScheduler::epoch_to_slurm($e),
        '2026-03-17T00:00:00', "Monday 07:00 -> Tuesday midnight" );
}

# Friday 18:00 — after weekday window, weekend is next.
# Expected: Saturday 2026-03-21 00:00:00  (Tier 1)
{
    my $now  = epoch_for(2026, 3, 20, 18, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(2, {}, $now);
    ok( defined $e, "Friday 18:00: slot found" );
    is( $tier, 1,   "Friday 18:00: Tier 1" );
    is( NBI::EcoScheduler::epoch_to_slurm($e),
        '2026-03-21T00:00:00', "Friday 18:00 -> Saturday midnight" );
}

# Wednesday 02:00 — INSIDE weekday window.
# Expected: essentially now (within ~2 min of $now)
{
    my $now  = epoch_for(2026, 3, 18, 2, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(2, {}, $now);
    ok( defined $e,         "Wednesday 02:00 (inside window): slot found" );
    is( $tier, 1,           "Wednesday 02:00: Tier 1" );
    ok( $e - $now <= 120,   "Wednesday 02:00: starts within 2 minutes" );
    ok( $e >= $now,         "Wednesday 02:00: start not in the past" );
}

# Sunday 14:00 — inside weekend window 11:00-16:00.
# 1h job: fits entirely (14:01-15:01 <= 16:00) → Tier 1, start ~now
{
    my $now  = epoch_for(2026, 3, 22, 14, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(1, {}, $now);
    ok( defined $e,       "Sunday 14:00 1h job (inside window): slot found" );
    is( $tier, 1,         "Sunday 14:00 1h job: Tier 1" );
    ok( $e - $now <= 120, "Sunday 14:00 1h job: starts within 2 minutes" );
}

# Sunday 14:00, 2h job — ends 16:01, 1 minute past window close.
# Tier 2 (avoids peak but overruns window); same-day preferred over Mon T1.
{
    my $now  = epoch_for(2026, 3, 22, 14, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(2, {}, $now);
    ok( defined $e,       "Sunday 14:00 2h job: slot found" );
    is( $tier, 2,         "Sunday 14:00 2h job: Tier 2 (barely overruns window)" );
    ok( $e - $now <= 120, "Sunday 14:00 2h job: same-day start preferred (within 2 min)" );
}

# ---------------------------------------------------------------------------
# find_eco_begin — Tier 2 (job overruns window but avoids peak)
# ---------------------------------------------------------------------------

# Monday 07:00, 8-hour job.
# The job would run 00:00-08:00 on Tuesday, overrunning the 06:00 window
# end, but 08:00 < 17:00 so it avoids the avoid window.  Tier 2.
{
    my $now  = epoch_for(2026, 3, 16, 7, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(8, {}, $now);
    ok( defined $e, "8h job Monday 07:00: slot found" );
    is( $tier, 2,   "8h job Monday 07:00: Tier 2 (overruns window)" );
    is( NBI::EcoScheduler::epoch_to_slurm($e),
        '2026-03-17T00:00:00', "8h job Monday 07:00 -> Tuesday midnight" );
}

# ---------------------------------------------------------------------------
# find_eco_begin — Tier 3 (overlaps avoid window, no better option)
# ---------------------------------------------------------------------------

# Monday 07:00, 20-hour job.
# Any eco-window start for a 20h job will overlap 17:00-20:00.
# Best we can do is start at next eco-window open (Tuesday 00:00) as Tier 3.
{
    my $now  = epoch_for(2026, 3, 16, 7, 0);
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(20, {}, $now);
    ok( defined $e, "20h job Monday 07:00: slot found" );
    is( $tier, 3,   "20h job Monday 07:00: Tier 3 (unavoidable overlap)" );
    is( NBI::EcoScheduler::epoch_to_slurm($e),
        '2026-03-17T00:00:00', "20h job Monday 07:00 -> Tuesday midnight" );
}

# ---------------------------------------------------------------------------
# find_eco_begin — config overrides
# ---------------------------------------------------------------------------

# Custom narrow weekday window 03:00-04:00, now=Monday 07:00.
# Should skip to Tuesday 03:00.
{
    my $now  = epoch_for(2026, 3, 16, 7, 0);
    my $cfg  = { eco_windows_weekday => '03:00-04:00' };
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(0.5, $cfg, $now);
    ok( defined $e, "custom window: slot found" );
    is( NBI::EcoScheduler::epoch_to_slurm($e),
        '2026-03-17T03:00:00', "custom 03:00-04:00 window -> Tuesday 03:00" );
}

# eco_lookahead_days=0 and already past today's window — should return undef
{
    my $now = epoch_for(2026, 3, 16, 7, 0);
    my $cfg = { eco_lookahead_days => 0 };
    my ($e, $tier) = NBI::EcoScheduler::find_eco_begin(2, $cfg, $now);
    ok( !defined $e, "lookahead=0, window passed: returns undef" );
}

# ---------------------------------------------------------------------------
# DEFAULTS hash is accessible and correct
# ---------------------------------------------------------------------------
{
    is( $NBI::EcoScheduler::DEFAULTS{eco_default},          1,                       "eco_default hardcoded to 1" );
    is( $NBI::EcoScheduler::DEFAULTS{eco_lookahead_days},   3,                       "lookahead default = 3" );
    is( $NBI::EcoScheduler::DEFAULTS{eco_windows_weekday},  '00:00-06:00',           "weekday window default" );
    is( $NBI::EcoScheduler::DEFAULTS{eco_windows_weekend},  '00:00-07:00,11:00-16:00', "weekend window default" );
    is( $NBI::EcoScheduler::DEFAULTS{eco_avoid},            '17:00-20:00',           "avoid window default" );
}

done_testing();
