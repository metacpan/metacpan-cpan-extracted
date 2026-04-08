use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

my $loaded = do "$RealBin/../bin/session";
ok($loaded, 'session script loads for helper testing') or diag($@ || $!);

is(
    session_hours_to_slurm(12),
    '0-12:00:00',
    '12 hours converts to SLURM time',
);

is(
    session_hours_to_slurm(26.5),
    '1-02:30:00',
    'fractional hours convert to day/hour/minute SLURM time',
);

is_deeply(
    session_resolve_time(hours => 8, default_hours => 4, days => 0),
    { total_hours => 8, slurm => '0-08:00:00' },
    '--hours remains supported',
);

is_deeply(
    session_resolve_time(time_string => '12h', default_hours => 4, days => 0),
    { total_hours => 12, slurm => '0-12:00:00' },
    '--time accepts runjob-style hours',
);

is_deeply(
    session_resolve_time(time_string => '1d', default_hours => 4, days => 0),
    { total_hours => 24, slurm => '1-00:00:00' },
    '--time accepts days',
);

is_deeply(
    session_resolve_time(time_string => '2h30m', default_hours => 4, days => 1),
    { total_hours => 26.5, slurm => '1-02:30:00' },
    '--days is added on top of --time',
);

eval { session_resolve_time(hours => 4, time_string => '12h', default_hours => 4, days => 0) };
like($@, qr/mutually exclusive/, '--hours and --time together are rejected');

done_testing();
