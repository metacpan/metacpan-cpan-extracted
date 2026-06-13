use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{RPI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

# pi_details() concatenates the devicetree model, os-release, uname and the
# tail of /proc/cpuinfo. We assert on board-agnostic invariants present on every
# Pi rather than a specific SoC string (modern /proc/cpuinfo no longer carries a
# "BCM2835"-style Hardware line).

my $sys = RPi::SysInfo->new;

for my $case (['method', $sys->pi_details], ['function', pi_details()]){
    my ($form, $d) = @$case;

    ok length $d, "pi_details() $form returns data";

    like $d, qr/Raspberry Pi/,   "pi_details() $form includes the model name";
    like $d, qr/Revision\s*:/,   "pi_details() $form includes the cpuinfo Revision";
    like $d, qr/Serial\s*:/,     "pi_details() $form includes the cpuinfo Serial";
    like $d, qr/Model\s*:/,      "pi_details() $form includes the cpuinfo Model";
    like $d, qr/Throttled flag/, "pi_details() $form includes the throttled flag";
}

done_testing();
