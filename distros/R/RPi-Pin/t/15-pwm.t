use strict;
use warnings;

use RPi::Pin;
use Test::More;

my $mod = 'RPi::Pin';

if (! $ENV{RPI_SUBMODULE_TESTING}){
    plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
}

if ($> == 0){
    $ENV{PI_BOARD} = 1;
}

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

if ($> != 0){
    print "enforcing sudo for PWM tests...\n";
    system('sudo', 'perl', $0);
    exit;
}

{# pwm

    if (! $ENV{NO_BOARD}) {
        my $pin = $mod->new(18);
        $pin->mode(2);
        is $pin->mode, 2, "pin mode set to PWM ok, and we can read it";
        $pin->mode(0);
        is $pin->mode, 0, "pin mode set back to INPUT";
    }
}

done_testing();
