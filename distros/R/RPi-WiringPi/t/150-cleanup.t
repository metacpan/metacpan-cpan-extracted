use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(label => 't/150-cleanup.t', shm_key => 'rpit');

my $pin26 = $pi->pin(26);
my $pin12 = $pi->pin(12);
my $pin18 = $pi->pin(18);

my @pins = $pi->registered_pins;

my @pnums = qw(26 12 18);
my $c = 0;

for ($pin26, $pin12, $pin18){
    isa_ok $_, 'RPi::Pin';
    is $_->num, $pnums[$c], "pin $pnums[$c] has correct num";
    $c++;
}

$pi->unregister_pin($pin18);

is((grep {$_ == 26} @{ $pi->registered_pins }), 1, "after removing 18, pin 26 ok"); 
is((grep {$_ == 12} @{ $pi->registered_pins }), 1, "after removing 18, pin 12 ok"); 

$pi->register_pin($pin18);
is @{ $pi->registered_pins }, 3, "registered pin ok";

$pi->cleanup;

#is @{ $pi->registered_pins }, 0, "cleanup() ok";

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
