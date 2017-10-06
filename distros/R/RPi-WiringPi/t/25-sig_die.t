use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

my $pi = $mod->new(fatal_exit => 0);
my $pin = $pi->pin(21);

$pin->mode(OUTPUT);

is ${ $pi->registered_pins }[0], '21', "pin registered ok";

eval { die "intentional die()"; };

is $pin->mode, INPUT, "pin reset to INPUT after die()";

$pi->cleanup;

check_pin_status();

done_testing();
