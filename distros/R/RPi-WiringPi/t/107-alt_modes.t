use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(label => 't/107-alt_modes.t', shm_key => 'rpit');

{ # alt modes

    my $pin = $pi->pin(21);

    my $default = $pin->mode;

    # Pin 21's pristine mode differs by board: INPUT (0) on the BCM Pi 3/4, but
    # "no function" (alt 31) on the Pi 5 / RP1.
    my $board_default = rpi_default_pin_config()->{21}{alt};
    is $default, $board_default, "default pin mode matches the board default ($board_default)";

    SKIP: {
        # wiringPi's RP1 funcsel numbering doesn't match the classic ALT0-5
        # scheme: mode_alt(1)/(2) don't take, and an arbitrary alt on an
        # unconnected pin maps to nothing meaningful, so this round-trip isn't
        # valid on the Pi 5 (see B6/B9 in plans/shareable-refactor.md).
        skip "alt-mode round-trip is not supported on the Pi 5 / RP1", 24
            if rpi_board_tag() eq 'pi5';

        for (0..7){
            my $alt = "ALT$_";
            $pin->mode_alt($_);
            is $pin->mode_alt, $_, "pin in alt mode $alt ok";
            $pin->mode($default);
            is $pin->mode_alt, 0, "pin back to INPUT";
            is $pin->mode, INPUT, "...confirmed";
        }
    }
}

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
