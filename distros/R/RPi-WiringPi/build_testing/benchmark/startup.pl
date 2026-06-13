use warnings;
use strict;

use Benchmark qw(timethis timethese cmpthese);
use Data::Dumper;
use RPi::WiringPi;

die "need run count" if ! $ARGV[0];

timethis $ARGV[0], 'startup';

sub startup {
    my $pi = RPi::WiringPi->new(label => 'startup benchmark');
    $pi->cleanup;
}

__END__

# before lazy loading

timethis 30000: 17 wallclock secs (16.34 usr +  1.54 sys = 17.88 CPU) @ 1677.85/s (n=30000)
timethis 30000: 19 wallclock secs (17.82 usr +  1.62 sys = 19.44 CPU) @ 1543.21/s (n=30000)

# after lazy loading

timethis 30000: 15 wallclock secs (13.80 usr +  1.04 sys = 14.84 CPU) @ 2021.56/s (n=30000)
timethis 30000: 15 wallclock secs (13.61 usr +  1.17 sys = 14.78 CPU) @ 2029.77/s (n=30000)

