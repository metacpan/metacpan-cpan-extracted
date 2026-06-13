use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

# The interrupt proxies are pure pass-throughs (no redundant validation layer);
# this file asserts the croaks PROPAGATED from RPi::Pin / WiringPi::API. Every
# bad call is rejected before any hardware is touched or any child is forked,
# so there are no side effects to clean up. Regexes are anchored to the real
# croak strings in RPi/Pin.pm (2.3609) and WiringPi/API.pm.

my $pi = $mod->new(
    label => 't/211-interrupt_validation.t',
    shm_key => 'rpit',
    shared => 0
);

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # $pin->set_interrupt (RPi::Pin)

    eval { $pin->set_interrupt(9, sub {}) };
    like $@, qr/set_interrupt\(\) \$edge must be EDGE_FALLING/,
        "set_interrupt() rejects a bad edge ok";

    eval { $pin->set_interrupt(EDGE_RISING, 'not a coderef') };
    like $@, qr/set_interrupt\(\) requires \$callback to be a CODE reference/,
        "set_interrupt() rejects a non-CODE callback ok";

    eval { $pin->set_interrupt(EDGE_RISING, sub {}, 'x') };
    like $@, qr/set_interrupt\(\) \$debounce_us must be a non-negative integer/,
        "set_interrupt() rejects a non-numeric debounce ok";

    # $pi->interrupt_buffer

    for my $bad (0, -5, 'x'){
        eval { $pi->interrupt_buffer($bad) };
        like $@, qr/interrupt_buffer\(\) requires a positive integer size/,
            "interrupt_buffer($bad) rejected ok";
    }

    # $pi->run_interrupt_loop - timeout then max

    for my $bad (0, 'x'){
        eval { $pi->run_interrupt_loop($bad) };
        like $@, qr/run_interrupt_loop\(\) \$timeout_ms must be a positive integer/,
            "run_interrupt_loop($bad) rejects a bad timeout ok";
    }

    for my $bad (0, 'x'){
        eval { $pi->run_interrupt_loop(100, $bad) };
        like $@, qr/run_interrupt_loop\(\) \$max must be a positive integer/,
            "run_interrupt_loop(100, $bad) rejects a bad max ok";
    }

    # $pi->auto_dispatch_interrupts - bad boolean then unknown signal

    for my $bad (2, 'x'){
        eval { $pi->auto_dispatch_interrupts($bad) };
        like $@, qr/auto_dispatch_interrupts\(\) requires a boolean first argument/,
            "auto_dispatch_interrupts($bad) rejects a bad boolean ok";
    }

    eval { $pi->auto_dispatch_interrupts(1, 'NOPE') };
    like $@, qr/auto_dispatch_interrupts\(\) unknown signal 'NOPE'/,
        "auto_dispatch_interrupts(1, 'NOPE') rejects an unknown signal ok";

    # $pi->background_interrupts - spec-level validation (all pre-fork)

    eval { $pi->background_interrupts() };
    like $@, qr/background_interrupts\(\) requires at least one/,
        "background_interrupts() rejects an empty spec list ok";

    eval { $pi->background_interrupts('not a ref') };
    like $@, qr/background_interrupts\(\) each spec must be an array reference/,
        "background_interrupts() rejects a non-arrayref spec ok";

    eval { $pi->background_interrupts(['x', EDGE_RISING, sub {}, 0]) };
    like $@, qr/background_interrupts\(\) each \$pin must be a positive integer/,
        "background_interrupts() rejects a bad pin ok";

    eval { $pi->background_interrupts([18, 9, sub {}, 0]) };
    like $@, qr/background_interrupts\(\) each \$edge must be INT_EDGE_FALLING/,
        "background_interrupts() rejects a bad edge ok";

    eval { $pi->background_interrupts([18, EDGE_RISING, 'nope', 0]) };
    like $@, qr/background_interrupts\(\) each \$callback must be a CODE reference/,
        "background_interrupts() rejects a non-CODE callback ok";

    eval { $pi->background_interrupts([18, EDGE_RISING, sub {}, 'x']) };
    like $@, qr/background_interrupts\(\) each \$debounce_us must be a/,
        "background_interrupts() rejects a bad debounce ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
