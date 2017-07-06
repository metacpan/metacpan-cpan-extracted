use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

my $pi = $mod->new;

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

print "$ENV{RPI_PINS}\n"; 
$pi->unregister_pin($pin18);
print "$ENV{RPI_PINS}\n";
is ((grep {$_ == 26} @{ $pi->registered_pins }), 1, "after removing 18, pin 26 ok"); 
is ((grep {$_ == 12} @{ $pi->registered_pins }), 1, "after removing 12, pin 26 ok"); 

$pi->register_pin($pin18);
is @{ $pi->registered_pins }, 3, "registered pin ok";

$pi->cleanup;

is @{ $pi->registered_pins }, 0, "cleanup() ok";

check_pin_status();

done_testing();
