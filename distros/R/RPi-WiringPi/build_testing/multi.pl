use strict;
use warnings;

use RPi::WiringPi;

my $pi_a = RPi::WiringPi->new(label => "pi_A");
my $pi_b = RPi::WiringPi->new(label => "pi B");

$pi_a->dump_metadata;
#$pi_a->dump_handlers;

$pi_b->dump_metadata;
#$pi_b->dump_handlers;

die "hello\n";

print "shouldn't see this if fatal_exit\n";
$pi_a->cleanup;
$pi_b->cleanup;

