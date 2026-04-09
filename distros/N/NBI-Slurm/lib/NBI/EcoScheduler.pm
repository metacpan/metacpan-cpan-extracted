package NBI::EcoScheduler;
#ABSTRACT: Find energy-efficient SLURM job start times
#
# NBI::EcoScheduler - Selects low-energy-price windows for SLURM jobs.
#
# DESCRIPTION:
#   Given a job's walltime (hours) and an optional config hash, returns the
#   next available epoch timestamp that falls within a "cheap energy" window.
#   Three tiers of slots are considered:
#     Tier 1 - job fits entirely inside an eco window AND avoids peak hours
#     Tier 2 - job starts in an eco window, avoids peak hours, but overruns the window
#     Tier 3 - job starts in an eco window but overlaps peak hours (fallback)
#
#   Public functions:
#     - find_eco_begin($duration_h, $config, $now) -> ($epoch, $tier) or (undef,undef)
#     - epoch_to_slurm($epoch)   -> "YYYY-MM-DDTHH:MM:SS"
#     - format_delay($epoch, $now) -> "2h 05m" / "now"
#
#   Private helpers:
#     - _windows_for_day($midnight, $dow, $cfg) -> list of [start,end] epochs
#     - _avoid_for_day($midnight, $cfg)         -> list of [start,end] epochs
#     - _parse_window_string($str, $midnight)   -> list of [start,end] epochs
#     - _job_overlaps_avoid($start, $dur_h, \@avoid) -> bool
#
# RELATIONSHIPS:
#   - Called by bin/runjob when eco mode is active.
#   - Results fed into NBI::Opts->{start_date} / NBI::Opts->{start_time}.
#   - Config hash comes from NBI::Slurm::load_config().
#

use strict;
use warnings;
use POSIX qw(mktime strftime);
use Carp qw(carp);

$NBI::EcoScheduler::VERSION = $NBI::Slurm::VERSION // '0.17.0';

# ---------------------------------------------------------------------------
# Hardcoded defaults - used when config keys are absent.
# Mon-Fri: 00:00-06:00  (night window before peak morning commute)
# Sat-Sun: 00:00-07:00 and 11:00-16:00  (weekend has longer cheap windows)
# Avoid every day: 17:00-20:00  (evening peak)
# ---------------------------------------------------------------------------
our %DEFAULTS = (
    eco_windows_weekday => '00:00-06:00',
    eco_windows_weekend => '00:00-07:00,11:00-16:00',
    eco_avoid           => '17:00-20:00',
    eco_lookahead_days  => 3,
    eco_default         => 1,
);

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

sub find_eco_begin {
    # Find the next eco-friendly start epoch for a job of $duration_h hours.
    #
    # Parameters:
    #   $duration_h  - job walltime in hours (default: 1)
    #   $config      - hashref from load_config(), may be empty or undef
    #   $now         - current epoch (defaults to time(); injectable for testing)
    #
    # Returns: ($begin_epoch, $tier)  or  (undef, undef) if nothing found.
    #   $tier 1 = perfect: fits in window, avoids peak
    #   $tier 2 = acceptable: avoids peak but overruns eco window
    #   $tier 3 = fallback: starts in eco window but overlaps peak hours
    my ($duration_h, $config, $now) = @_;
    $duration_h //= 1;
    $config     //= {};
    $now        //= time();

    # Caller config overrides defaults
    my %cfg = (%DEFAULTS, %$config);
    my $lookahead = int($cfg{eco_lookahead_days});

    my ($best_epoch, $best_tier) = (undef, undef);
    my @now_tm = localtime($now);

    for my $day_offset (0 .. $lookahead) {
        my $day_midnight = mktime(0, 0, 0,
            $now_tm[3] + $day_offset, $now_tm[4], $now_tm[5]);

        my $dow   = (localtime($day_midnight))[6];   # 0=Sun … 6=Sat
        my @eco   = _windows_for_day($day_midnight, $dow, \%cfg);
        my @avoid = _avoid_for_day($day_midnight, \%cfg);

        my ($day_t1, $day_t2, $day_t3);

        for my $window (@eco) {
            my ($w_start, $w_end) = @$window;

            # Earliest possible candidate: 1-minute safety buffer from "now"
            my $candidate = ($w_start > $now + 60) ? $w_start : $now + 60;
            next if $candidate >= $w_end;   # window already past

            my $fits     = ($candidate + $duration_h * 3600) <= $w_end;
            my $overlaps = _job_overlaps_avoid($candidate, $duration_h, \@avoid);

            if    ($fits && !$overlaps) { $day_t1 //= $candidate }
            elsif (!$overlaps)          { $day_t2 //= $candidate }
            else                        { $day_t3 //= $candidate }
        }

        my $day_best = $day_t1 // $day_t2 // $day_t3;
        my $day_tier = defined $day_t1 ? 1
                     : defined $day_t2 ? 2
                     : defined $day_t3 ? 3
                     : undef;
        next unless defined $day_best;

        # First candidate found - record it
        if (!defined $best_epoch) {
            ($best_epoch, $best_tier) = ($day_best, $day_tier);
        } elsif ($day_tier < $best_tier) {
            # A later day offers a better tier - upgrade
            ($best_epoch, $best_tier) = ($day_best, $day_tier);
        }

        # Prefer starting sooner over waiting for a "perfect" distant slot:
        # once we have a T1 or T2 (avoids peak hours) stop scanning -
        # a slightly imperfect slot today beats a perfect slot in 3 days.
        last if $best_tier <= 2;
    }

    return ($best_epoch, $best_tier) if defined $best_epoch;
    return (undef, undef);
}

sub epoch_to_slurm {
    # Convert a Unix epoch to the SLURM --begin format "YYYY-MM-DDTHH:MM:SS".
    my $epoch = shift;
    return strftime("%Y-%m-%dT%H:%M:%S", localtime($epoch));
}

sub format_delay {
    # Return a human-readable string describing how far in the future $begin_epoch is.
    # e.g. "now", "45m", "6h 05m", "1d 2h 30m"
    my ($begin_epoch, $now) = @_;
    $now //= time();
    my $secs = $begin_epoch - $now;
    return "now" if $secs <= 60;
    my $days  = int($secs / 86400);
    my $hours = int(($secs % 86400) / 3600);
    my $mins  = int(($secs % 3600)  / 60);
    return sprintf("%dd %dh %02dm", $days, $hours, $mins) if $days;
    return sprintf("%dh %02dm",           $hours, $mins)  if $hours;
    return sprintf("%dm", $mins);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _windows_for_day {
    # Return eco windows for a given day midnight + day-of-week.
    my ($day_midnight, $dow, $cfg) = @_;
    my $is_weekend = ($dow == 0 || $dow == 6);
    my $str = $is_weekend
        ? ($cfg->{eco_windows_weekend} // $DEFAULTS{eco_windows_weekend})
        : ($cfg->{eco_windows_weekday} // $DEFAULTS{eco_windows_weekday});
    return _parse_window_string($str, $day_midnight);
}

sub _avoid_for_day {
    # Return avoid windows for a given day midnight.
    my ($day_midnight, $cfg) = @_;
    my $str = $cfg->{eco_avoid} // $DEFAULTS{eco_avoid};
    return _parse_window_string($str, $day_midnight);
}

sub _parse_window_string {
    # Parse "HH:MM-HH:MM,HH:MM-HH:MM,..." anchored to $day_midnight.
    # Returns a list of [start_epoch, end_epoch] pairs.
    my ($str, $day_midnight) = @_;
    my @windows;
    for my $part (split /,/, $str) {
        $part =~ s/^\s+|\s+$//g;
        if ($part =~ /^(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})$/) {
            my ($sh, $sm, $eh, $em) = ($1, $2, $3, $4);
            push @windows, [
                $day_midnight + $sh * 3600 + $sm * 60,
                $day_midnight + $eh * 3600 + $em * 60,
            ];
        } else {
            carp "NBI::EcoScheduler: cannot parse window spec '$part', skipping\n";
        }
    }
    return @windows;
}

sub _job_overlaps_avoid {
    # Return 1 if a job starting at $start_epoch running for $duration_h hours
    # overlaps any of the avoid windows.
    my ($start, $duration_h, $avoid_windows) = @_;
    my $end = $start + $duration_h * 3600;
    for my $w (@$avoid_windows) {
        my ($a, $b) = @$w;
        return 1 if ($start < $b && $end > $a);
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::EcoScheduler - Find energy-efficient SLURM job start times

=head1 VERSION

version 0.19.1

=head1 SYNOPSIS

  use NBI::EcoScheduler;

  my $config = NBI::Slurm::load_config();    # or {}

  my ($epoch, $tier) = NBI::EcoScheduler::find_eco_begin(4, $config);
  if (defined $epoch) {
      my $begin = NBI::EcoScheduler::epoch_to_slurm($epoch);
      my $delay = NBI::EcoScheduler::format_delay($epoch);
      print "Schedule job for $begin (in $delay) - tier $tier\n";
  }

=head1 DESCRIPTION

C<NBI::EcoScheduler> finds the next time window when running a SLURM job is
likely to consume cheap or low-carbon energy. It walks forward from the
current time in window-boundary steps, scoring each candidate slot:

=over 4

=item * B<Tier 1> - Job fits entirely inside an eco window and avoids peak hours.

=item * B<Tier 2> - Job avoids peak hours but overruns the eco window.

=item * B<Tier 3> - Job starts in an eco window but overlaps peak hours (last resort).

=back

The first tier-1 slot is returned immediately. If the lookahead period is
exhausted without finding one, the first tier-2 slot is returned, then
tier-3.  C<(undef, undef)> is returned only if no eco window exists at all
in the lookahead period.

=head1 NAME

NBI::EcoScheduler - Find energy-efficient start times for SLURM jobs

=head1 DEFAULT WINDOWS

  Mon-Fri:  00:00-06:00
  Sat-Sun:  00:00-07:00  and  11:00-16:00
  Avoid:    17:00-20:00  (every day)

These are overridden by the corresponding keys in C<~/.nbislurm.config>.

=head1 CONFIGURATION

The following keys are read from the config hash (all optional):

  eco_windows_weekday   HH:MM-HH:MM                  (default: 00:00-06:00)
  eco_windows_weekend   HH:MM-HH:MM[,HH:MM-HH:MM]    (default: 00:00-07:00,11:00-16:00)
  eco_avoid             HH:MM-HH:MM[,HH:MM-HH:MM]    (default: 17:00-20:00)
  eco_lookahead_days    integer                        (default: 3)
  eco_default           0 or 1                         (default: 1)

=head1 FUNCTIONS

=head2 find_eco_begin($duration_h, $config, $now)

  my ($epoch, $tier) = NBI::EcoScheduler::find_eco_begin($hours, $config);

Finds the best eco start time for a job of C<$duration_h> hours.
C<$config> is a hashref (may be empty); C<$now> is an optional epoch
timestamp (defaults to C<time()>; useful for testing).

Returns C<($begin_epoch, $tier)> or C<(undef, undef)>.

=head2 epoch_to_slurm($epoch)

  my $str = NBI::EcoScheduler::epoch_to_slurm($epoch);
  # "2026-03-17T00:00:00"

Converts a Unix epoch to the SLURM C<--begin> format.

=head2 format_delay($epoch, $now)

  my $str = NBI::EcoScheduler::format_delay($epoch);
  # "6h 05m", "1d 2h 30m", "now"

Returns a human-readable string describing the delay until C<$epoch>.

=head1 INTERNAL FUNCTIONS

=head2 _windows_for_day($midnight, $dow, $cfg)

Returns the eco windows for a given day as C<[$start_epoch, $end_epoch]> pairs.

=head2 _avoid_for_day($midnight, $cfg)

Returns the avoid windows for a given day.

=head2 _parse_window_string($str, $midnight)

Parses a comma-separated list of C<HH:MM-HH:MM> ranges anchored to C<$midnight>.

=head2 _job_overlaps_avoid($start, $duration_h, \@avoid)

Returns 1 if a job of C<$duration_h> hours starting at C<$start> overlaps
any avoid window.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
