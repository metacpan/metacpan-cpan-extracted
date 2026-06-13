# NAME

RPi::Pin - Access and manipulate Raspberry Pi GPIO pins

# SYNOPSIS

    use RPi::Pin;
    use RPi::Const qw(:all);

    my $pin = RPi::Pin->new(5, "Optional descriptive pin label");

    $pin->mode(INPUT);
    $pin->write(LOW);

    my $num = $pin->num;
    my $mode = $pin->mode;
    my $state = $pin->read;

    print "pin number $num is in mode $mode with state $state\n";

    # As of WiringPi::API 3.18 the callback fires only while dispatch is
    # serviced; { auto_dispatch => 1 } services it for you (fire and forget).

    $pin->set_interrupt(EDGE_RISING, \&pin5_interrupt_handler, { auto_dispatch => 1 });

    sub pin5_interrupt_handler {
        my ($edge, $timestamp_us) = @_;
        print "in interrupt handler\n";
    }

# DESCRIPTION

An object that represents a physical GPIO pin.

Using the pin object's methods, the GPIO pins can be controlled and monitored.

This distribution can be accessed through [RPi::WiringPi](https://metacpan.org/pod/RPi%3A%3AWiringPi). Using that
distribution provides safety and cleanup procedures. Using this module directly
requires you to reset your pins manually.

We use the `BCM` (`GPIO`) pin numbering scheme.

# METHODS

## new($pin\_num, $comment)

Takes the number representing the Pi's GPIO pin you want to use, and returns
an object for that pin.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

    $comment

Optional, String: A custom name or purpose description to associate this pin
with.

## comment($comment)

Sets/gets a description or name for the pin.

Parameters:

    $comment

Optional, String: If sent in, we'll set the pin's comment to this value.

Return: The currently set comment for the pin.

## mode($mode)

Puts the pin into either `INPUT`, `OUTPUT`, `PWM_OUT` or `GPIO_CLOCK`
mode. If `$mode` is not sent in, we'll return the pin's current mode.

Parameters:

    $mode

Optional: If not sent in, we'll simply return the current mode of the pin.
Otherwise, send in: `0` for `INPUT`, `1` for `OUTPUT`, `2` for `PWM_OUT`
and `3` for `GPIO_CLOCK` mode.

## mode\_alt($alt)

Allows you to set any pin to any mode.

Parameters:

    $alt

Optional: If not sent in, we'll simply return the current mode of the pin. The
possible values of this method are as follows:

    Value   Mode
    ------------
    0       INPUT
    1       OUTPUT
    4       ALT0
    5       ALT1
    6       ALT2
    7       ALT3
    3       ALT4
    2       ALT5

[Here's](https://elinux.org/RPi_BCM2835_GPIOshttps://elinux.org/RPi_BCM2835_GPIOs)
a decent guide to the various ALT settings for each pin.

## read()

Returns `1` if the pin is `HIGH` (on) and `0` if the pin is `LOW` (off).

## write($state)

For pins in `OUTPUT` mode, will turn `HIGH` (on) the pin, or `LOW` (off).

Parameters:

    $state

Send in `1` to turn the pin on, and `0` to turn it off.

## pull($direction)

Used to set the internal pull-up or pull-down resistor for a pin. Calling this
method on a pin will automatically set the pin to `INPUT` mode.

Parameter:

    $direction

Mandatory: `2` for `PUD_UP`, `1` for `PUD_DOWN` and `0` for `PUD_OFF`
(disabled the resistor).

## background\_interrupt($edge, $callback, $debounce\_us, \\%opts)

Interrupts are armed on the pin but driven through the Pi object. For the
per-method reference see ["INTERRUPT METHODS" in RPi::WiringPi](https://metacpan.org/pod/RPi%3A%3AWiringPi#INTERRUPT-METHODS), and for full
runnable examples - driving dispatch, auto-dispatch, the background results
channel and teardown - see [RPi::WiringPi::INTERRUPTS](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AINTERRUPTS).

Like `set_interrupt()`, but handles the interrupt in a **background process**:
the library forks, arms the interrupt in the child, and runs `$callback` there
on each edge while your main program carries on - so it fires even while your
main code is busy in a long blocking call.

Takes the same arguments as `set_interrupt()` (`$debounce_us` optional), all
validated before forking. Because the callback runs in a separate process it
**cannot** see or change your main program's variables; use it for independent
handlers (drive a pin, log, notify).

Returns a handle:

    my $h = $pin->background_interrupt(EDGE_RISING, \&handler);

    $h->stop;        # Stop + reap the background handler (idempotent)
    $h->pid;         # The child PID
    $h->running;     # True while the child is alive

A handle going out of scope stops its child, and a forgotten `stop` is reaped
at program exit.

An optional trailing options hash reference is forwarded to [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI);
`{ results => 1 }` ships the handler's defined return value back to the
parent, drained with `$h->read` (and `$h->fh` for `select`):

    my $h = $pin->background_interrupt(
        EDGE_RISING,
        sub { return "hit" },
        { results => 1 }
    );

    while (defined(my $msg = $h->read)) { print "$msg\n" }

## set\_interrupt($edge, $callback, $debounce\_us, \\%opts)

Listen for an interrupt on a pin, and do something if it is triggered.

Interrupts are armed on the pin but driven through the Pi object. For the
per-method reference see ["INTERRUPT METHODS" in RPi::WiringPi](https://metacpan.org/pod/RPi%3A%3AWiringPi#INTERRUPT-METHODS), and for full
runnable examples - driving dispatch, auto-dispatch, the background results
channel and teardown - see [RPi::WiringPi::INTERRUPTS](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AINTERRUPTS).

Parameters:

    $edge

Mandatory: `1` for `EDGE_FALLING`, `2` for `EDGE_RISING`, or `3` for
`EDGE_BOTH`.

    $callback

Mandatory: a code reference (eg: `\&my_handler` or `sub {...}`) to run when
the interrupt fires. The callback receives `($edge, $timestamp_us)`.

**Note:** as of `WiringPi::API` 3.18 the interrupt is dispatched in Perl rather
than from the wiringPi ISR thread, so the callback **must** be a code reference;
a string sub name is no longer accepted. The callback also only runs when your
program services the interrupt file descriptor, so you must drive dispatch (eg.
`$pi->wait_interrupts($timeout_ms)` in a loop, or
`$pi->dispatch_interrupts`).

    $debounce_us

Optional: debounce window in microseconds. Edges arriving within this window of
the previous accepted edge are ignored. Defaults to `0` (no debounce).

    \%opts

Optional: a trailing options hash reference, forwarded to [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI). The
`auto_dispatch` option turns on auto-dispatch as part of arming so the callback
fires without your own dispatch loop (process-wide; see
`$pi->auto_dispatch_interrupts`):

    $pin->set_interrupt(EDGE_RISING, \&handler, { auto_dispatch => 1 });

    # Or choose the delivery signal:

    $pin->set_interrupt(EDGE_RISING, \&handler, { auto_dispatch => 'USR1' });

`1` uses the default `SIGIO`; a signal name (eg `'USR1'`) delivers via that
signal instead, avoiding clashes with other `SIGIO` users in your program.

## interrupt\_set

DEPRECATED; See `set_interrupt()`.

## pwm($value)

Sets the level of the Pulse Width Modulation (PWM) of the pin. Dies if the
pin's `mode()` is not set to PWM (`2`). Note that only physical pin 12
(wiringPi pin 1, GPIO pin 18) is PWM hardware capable. 

Parameter:

    $value

Mandatory: values range from 0-1023. `0` for 0% (off) and `1023` for 100%
(fully on).

See ["pwm\_range-range" in RPi](https://metacpan.org/pod/RPi#pwm_range-range) for details on how to modify the range to
something other than `0-1023`.

## num()

Returns the pin number associated with the pin object.

# SEE ALSO

# AUTHOR

Steve Bertrand, <steveb@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
