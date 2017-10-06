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

my $pi = $mod->new;

{ # alt modes

    my $pin = $pi->pin(21);

    my $default = $pin->mode;

    is $default, INPUT, "default pin mode is INPUT ok";

    for (0..7){
        my $alt = "ALT$_";
        $pin->mode_alt($_);
        is $pin->mode_alt eq $_, 1, "pin in alt mode $alt ok";
        $pin->mode($default);
        is $pin->mode_alt, 0, "pin back to INPUT";
        is $pin->mode, INPUT, "...confirmed";
    }
}

$pi->cleanup;

check_pin_status();

done_testing();
