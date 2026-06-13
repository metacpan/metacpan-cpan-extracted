package RPi::WiringPi::Core;

use strict;
use warnings;

# Parent order matters: WiringPi::API is listed first, so under the
# default depth-first MRO every WiringPi::API method is found before
# anything in Meta, Util or RPi::SysInfo. See the MRO note atop
# RPi::WiringPi before adding any method whose name exists in another
# parent branch.
use parent 'WiringPi::API';
use parent 'RPi::WiringPi::Meta';
use parent 'RPi::WiringPi::Util';
use parent 'RPi::SysInfo';

use Carp qw(croak);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use RPi::Const qw(:all);

our $VERSION = '3.1802';

sub gpio_layout {
    return $_[0]->SUPER::gpio_layout;
}
sub identify {
    my ($self, $time) = @_;

    $time //= 5;

    $self->io_led(1);
    $self->pwr_led(1);

    sleep $time;

    $self->io_led(0);
    $self->pwr_led(0);
}
sub io_led {
    my ($self, $tweak) = @_;

    my $led  = $self->_led('io');
    my $path = "/sys/class/leds/$led->{name}";

    if ($tweak){
        # Stop disk activity from operating the green LED
        $self->_led_cmd("echo none | sudo tee $path/trigger");
        # Turn on the green LED full-time
        $self->_led_cmd("echo 1 | sudo tee $path/brightness");
    }
    else {
        # Turn off the green LED from being on full-time
        $self->_led_cmd("echo 0 | sudo tee $path/brightness");
        # Restore disk activity operating the green LED
        $self->_led_cmd("echo $led->{trigger} | sudo tee $path/trigger");
    }
}
sub pwr_led {
    my ($self, $tweak) = @_;

    my $led  = $self->_led('pwr');
    my $path = "/sys/class/leds/$led->{name}";

    if ($tweak){
        # Turn off the red power LED
        $self->_led_cmd("echo 0 | sudo tee $path/brightness");
    }
    else {
        # Restore the red power LED to its default behavior
        $self->_led_cmd("echo $led->{trigger} | sudo tee $path/trigger");
    }
}
sub label {
    my ($self, $label) = @_;
    $self->{label} = $label if defined $label;
    return $self->{label} // '';
}
sub pin_to_gpio {
    my ($self, $pin, $scheme) = @_;

    $scheme = defined $scheme
        ? $scheme
        : $self->pin_scheme;

    if ($scheme == RPI_MODE_WPI){
        return $self->wpi_to_gpio($pin);
    }
    elsif ($scheme == RPI_MODE_GPIO){
        return $pin;
    }

    # Catch-all: an uninitialized (or unrecognized/corrupted) scheme can't
    # map pins; never fall through to an implicit undef

    croak "Setup not run; pin mapping scheme not initialized\n";
}
sub pin_scheme {
    my ($self, $scheme) = @_;

    if (defined $scheme){
        $ENV{RPI_PIN_MODE} = $scheme;
    }
    
    return defined $ENV{RPI_PIN_MODE}
        ? $ENV{RPI_PIN_MODE}
        : RPI_MODE_UNINIT;
}
sub pwm_range {
    my ($self, $range) = @_;

    if ($> != 0) {
        die "\nPWM requires your script to be run as the 'root' user (sudo)\n";
    }

    if (defined $range){
        $self->{pwm_range} = $range;
        $self->pwm_set_range($range);
    }

    $self->_pwm_in_use(1);

    return defined $self->{pwm_range} ? $self->{pwm_range} : PWM_DEFAULT_RANGE;
}
sub pwm_clock {
    my ($self, $divisor) = @_;

    if ($> != 0) {
        die "\nPWM requires your script to be run as the 'root' user (sudo)\n";
    }

    if (defined $divisor) {
        $self->{pwm_clock} = $divisor;
        $self->pwm_set_clock($divisor);
    }

    $self->_pwm_in_use(1);

    return defined $self->{pwm_clock} ? $self->{pwm_clock} : PWM_DEFAULT_CLOCK;
}
sub pwm_mode {
    my ($self, $mode) = @_;

    if ($> != 0) {
        die "\nPWM requires your script to be run as the 'root' user (sudo)\n";
    }

    if (defined $mode) {
        if ($mode == PWM_MODE_MS || $mode == PWM_MODE_BAL) {
            $self->{pwm_mode} = $mode;
            $self->pwm_set_mode($mode);
        }
        else {
            croak "pwm_mode() requires either 0 or 1 if a param is sent in\n";
        }

        $self->_pwm_in_use(1);
    }

    return defined $self->{pwm_mode} ? $self->{pwm_mode} : PWM_DEFAULT_MODE;
}
sub registered_pins {
    return $_[0]->_pin_registration;
}
sub register_pin {
    my ($self, $pin, $comment) = @_;

    return if ! $self->_rpi_register_pins || ! $self->_rpi_register;

    $self->_pin_registration(
        pin         => $pin,
        alt         => $pin->mode_alt,
        state       => $pin->read,
        mode        => $pin->mode,
        comment     => $comment //= '',
        operation   => 'register',
        requester   => $self->uuid,
    );
}
sub unregister_pin {
    my ($self, $pin) = @_;

    return if ! $self->_rpi_register_pins || ! $self->_rpi_register;

    $self->_pin_registration(
        pin         => $pin,
        operation   => 'unregister',
        requester   => $self->uuid
    );
}
sub unregister_object {
    my ($self) = @_;

    return if ! $self->_rpi_register;

    $self->_meta_txn(sub {
        my $meta = $self->meta_fetch;

        delete $meta->{objects}->{$self->uuid};
        $meta->{object_count} = keys %{ $meta->{objects} };

        $self->meta_store($meta);
    });
}
sub cleanup {
    my ($self) = @_;

    # Only the process that created this object may tear it down. A forked child
    # (eg. background_interrupt(), or any user fork) shares the object but must
    # not reset pins, mutate the shared meta, or stop interrupts on the parent's
    # behalf when it exits.

    return if defined $self->{proc} && $self->{proc} != $$;

    if ($self->_rpi_register_pins) {

        $self->_meta_txn(sub {
            my $meta = $self->meta_fetch;

            if ($meta->{pwm}{in_use} && $meta->{pwm}{users}{$self->uuid}) {
                delete $meta->{pwm}{users}{$self->uuid};

                if (! keys %{ $meta->{pwm}{users} }){
                    WiringPi::API::pwmSetMode(PWM_DEFAULT_MODE);
                    WiringPi::API::pwmSetClock(PWM_DEFAULT_CLOCK);
                    WiringPi::API::pwmSetRange(PWM_DEFAULT_RANGE);

                    $meta->{pwm}->{in_use} = 0;
                }
            }

            for my $pin (keys %{$meta->{pins}}) {
                if (exists $meta->{pins}->{$pin}{users}{$self->uuid}) {
                    delete $meta->{pins}->{$pin}{users}{$self->uuid};

                    # Reset and drop the pin only when no other object still owns it

                    if (! keys %{ $meta->{pins}->{$pin}{users} }) {
                        $self->_restore_pin_alt($pin, $meta->{pins}->{$pin}{alt});
                        WiringPi::API::digitalWrite($pin, $meta->{pins}->{$pin}{state});
                        delete $meta->{pins}->{$pin};
                    }
                }
            }

            $self->meta_store($meta);
        });
    }

    # Release any armed interrupts: stops the wiringPi ISR threads and closes
    # the self-pipe so we don't leak the kernel ISR + fds at teardown

    WiringPi::API::stop_interrupts();

    # Stop any background workers started via $pi->worker. stop() is idempotent
    # (a no-op on an already-stopped handle), and the forked-child proc guard
    # above keeps a child from reaping the parent's workers.

    for my $worker (@{ $self->{workers} || [] }) {
        $worker->stop if $worker;
    }
    $self->{workers} = [];

    $self->unregister_object if $self->_rpi_register;

    # Drop this object's signal-cleanup entries (and restore the original
    # handlers once the last object is gone)

    if ($self->_rpi_register && $self->can('_release_signal_handlers')) {
        $self->_release_signal_handlers;
    }

    $self->{clean} = 1;
}

sub _led {
    my ($self, $led) = @_;

    # Pi 5 / RP1 exposes its LEDs as ACT (activity) and PWR (power); earlier
    # boards use led0 and led1. The default restore trigger differs too

    my %map = WiringPi::API::pi_rp1_model()
        ? (
            io  => { name => 'ACT', trigger => 'mmc0' },
            pwr => { name => 'PWR', trigger => 'none' },
        )
        : (
            io  => { name => 'led0', trigger => 'mmc0' },
            pwr => { name => 'led1', trigger => 'input' },
        );

    return $map{$led};
}
sub _led_cmd {
    # Runs an LED sysfs write via the shell, surfacing failures instead of
    # silently no-opping (eg. when sudo isn't available or isn't passwordless)

    my ($self, $cmd) = @_;

    if (system("$cmd > /dev/null") != 0) {
        warn "LED command '$cmd' failed; is sudo configured on this system?\n";
    }
}
sub _rpi_register {
    # Allow defeating the entire registration process (objects and pins)
    return $_[0]->{rpi_register} // 1;
}
sub _rpi_register_pins {
    # Allow defeating the shared memory pin registration
    return $_[0]->{rpi_register_pins} // 1;
}
sub _pin_registration {
    # Manages the registration duties for pins

    my ($self, %param) = @_;

    return if ! $self->_rpi_register_pins || ! $self->_rpi_register;

    my $pin = $param{pin};

    # The whole transaction runs under _meta_txn so the lock is released even
    # if a croak (or a die from a pin method) fires mid-section

    return $self->_meta_txn(sub {
        my $meta = $self->meta_fetch;

        if (! defined $pin){
            my @registered_pins = keys %{ $meta->{pins} };
            return \@registered_pins;
        }

        my $pin_num = $self->pin_to_gpio($pin->num);

        if ($param{operation} eq 'unregister'){
            if (! exists $meta->{pins}{$pin_num}{users}{$param{requester}}) {
                return;
            }
            if (exists $meta->{pins}{$pin_num}) {
                $pin->mode_alt($meta->{pins}{$pin_num}{alt});
                $pin->write($meta->{pins}{$pin_num}{state});
                $pin->mode($meta->{pins}{$pin_num}{mode});

                delete $meta->{pins}{$pin_num};

                $self->meta_store($meta);

                return;
            }
        }

        if (! exists $param{state} && ! exists $param{alt}) {
            croak "_pin_registration() requires both 'alt' and 'state' params\n";
        }

        if ($param{operation} eq 'register'){
            if (exists $meta->{pins}{$pin_num}){
                croak "pin $pin_num is already in use, can't continue...\n";
            }

            $meta->{pins}{$pin_num}{alt} = $param{alt};
            $meta->{pins}{$pin_num}{state} = $param{state};
            $meta->{pins}{$pin_num}{mode} = $param{mode};
            $meta->{pins}{$pin_num}{comment} = $pin->comment;
            $meta->{pins}{$pin_num}{users}{$param{requester}}++;
        }

        my @registered_pins = keys %{ $meta->{pins} };

        $self->meta_store($meta);

        return \@registered_pins;
    });
}
sub _restore_pin_alt {
    # Restores a pin to a previously captured alt mode. On the Raspberry Pi 5 /
    # RP1, get_alt() returns a *mode* enum rather than a classic alt-function
    # number, so pinModeAlt() can't round-trip the simple cases: INPUT (0) and
    # OUTPUT (1) must be restored via pinMode(), and "no function" (31, which
    # pinModeAlt rejects outright) via pinctrl. Real alt functions still
    # round-trip through pinModeAlt(). Off the RP1, get_alt()'s classic encoding
    # lines up with pinModeAlt(), so legacy Pi 3/4 behaviour is unchanged.

    my ($self, $pin_num, $alt) = @_;

    if (WiringPi::API::pi_rp1_model()) {
        if ($alt == 0 || $alt == 1) {
            WiringPi::API::pinMode($pin_num, $alt); # 0 = INPUT, 1 = OUTPUT
            return;
        }
        if ($alt == 31) {
            # Localize $?/$! so this shell-out (which often runs from cleanup at
            # program exit) can't clobber the script's own exit status.

            local ($?, $!);

            if (system('pinctrl', 'set', $pin_num, 'no') != 0) {
                warn "Couldn't restore GPIO $pin_num to 'no function' (alt 31) via " .
                     "pinctrl; is pinctrl installed and are you in the 'gpio' group?\n";
            }
            return;
        }
    }

    WiringPi::API::pinModeAlt($pin_num, $alt);
}
sub _pwm_in_use {
    my $self = shift;

    return if ! $self->_rpi_register_pins || ! $self->_rpi_register;

    if ($_[0]){
        $self->_meta_txn(sub {
            my $meta = $self->meta_fetch;
            $meta->{pwm}{in_use} = 1;
            $meta->{pwm}{users}{$self->uuid} = 1;
            $self->meta_store($meta);
        });
    }
}

sub _vim{1;};

1;

__END__

=head1 NAME

RPi::WiringPi::Core - Core methods for RPi::WiringPi Raspberry Pi
interface

=head1 DESCRIPTION

This module contains various utilities for L<RPi::WiringPi> that don't
necessarily fit anywhere else. It is a base class, and is not designed to be
used independently.

=head1 METHODS

Besides the methods listed below, we also make available through inheritance
all methods provided by L<RPi::SysInfo>. Please see that documentation for
usage details.

=head2 gpio_layout

Returns the GPIO layout which indicates the board revision number.

=head2 identify($seconds)

This method wraps the L<io_led()|/io_led($tweak)> and
L<pwr_led()|/pwr_led($tweak)> methods.

Parameters:

    $seconds

Optional, Integer: The number of seconds to remain in "identify" state. Defaults
to C<5>.

In "identify" state, the green disk I/O LED will remain on constantly, and the
red power LED will stay off for the duration.

=head2 io_led($tweak)

This is a helper method to better help you identify which Raspberry Pi board
you're currently working on, by allowing you to turn the green disk IO LED
on constantly.

WARNING: This method calls system command line commands using C<sudo>
internally.

Parameters:

    $tweak

Optional: Sending in a true value (eg C<1>) will turn the green disk activity
LED on constantly (ie. no blinking on activity). Sending in a false value or
omitting the parameter will restore the disk activity LED back to default state.

=head2 pwr_led($tweak)

This is a helper method to better help you identify which Raspberry Pi board
you're currently working on, by allowing you to turn the red power LED off.

WARNING: This method calls system command line commands using C<sudo>
internally.

Parameters:

    $tweak

Optional: Sending in a true value (eg: C<1>) will turn the red power LED off.
Sending in a false value (or omitting the parameter) will restore the power LED
back to default state.

=head2 label($label)

Allows you to set and retrieve a label (aka name) for your Raspberry Pi object.

Parameters:

    $label

Optional, String: Send in a string parameter to set a label/name for your Pi
object.

Return: The label/name you've previously set. If one has not been set, return
will be the empty string.

=head2 pin_scheme([$scheme])

Returns the current pin mapping in use. Returns C<0> for C<wiringPi> scheme,
C<1> for GPIO, and C<-1> if a scheme has not yet been configured (ie. one of
the C<setup*()> methods has not yet been called).

If using L<RPi::Const>, these map out to:

    0  => RPI_MODE_WPI
    1  => RPI_MODE_GPIO
    -1 => RPI_MODE_UNINIT

=head2 pin_to_gpio($pin, [$scheme])

Dynamically converts the specified pin from the specified scheme
C<RPI_MODE_WPI> (wiringPi) to the GPIO number format.

If C<$scheme> is not sent in, we'll attempt to fetch the scheme currently in
use and use that.

Example:

    my $num = pin_to_gpio(6, RPI_MODE_WPI);

That will understand the pin number C<6> to be the wiringPi representation, and
will return the GPIO representation.

=head2 wpi_to_gpio($pin_num)

Converts a pin number from C<wiringPi> notation to GPIO notation.

Parameters:

    $pin_num

Mandatory: The C<wiringPi> representation of a pin number.

=head2 phys_to_gpio($pin_num)

Converts a pin number as physically documented on the Raspberry Pi board
itself to GPIO notation, and returns it.

Parameters:

    $pin_num

Mandatory: The pin number printed on the physical Pi board.

=head2 pwm_range($range)

Changes the range of Pulse Width Modulation (PWM). The default is C<0> through
C<1023>.

Parameters:

    $range

Mandatory: An integer specifying the high-end of the range. The range always
starts at C<0>. Eg: if C<$range> is C<359>, if you incremented PWM by C<1>
every second, you'd rotate a step motor one complete rotation in exactly one
minute.

=head2 pwm_mode($mode)

Each PWM channel can run in either Balanced or Mark-Space mode. In Balanced
mode, the hardware sends a combination of clock pulses that results in an
overall DATA pulses per RANGE pulses. In Mark-Space mode, the hardware sets the
output HIGH for DATA clock pulses wide, followed by LOW for RANGE-DATA clock
pulses.

Raspberry Pi's default mode is balanced mode.

Parameters:

    $mode

Mandatory, Integer: C<0> for Mark-Space mode, or C<1> for Balanced mode.
Note: If using L<RPi::Const>, you can use C<PWM_MODE_MS> or
C<PWM_MODE_BAL>.

=head2 pwm_clock($divisor)

The PWM clock can be set to control the PWM pulse widths. The PWM clock is
derived from a 19.2MHz clock. You can set any divider.

For example, say you wanted to drive a DC motor with PWM at about 1kHz, and
control the speed in 1/1024 increments from 0/1023 (stopped) through to
1023/1023 (full on). In that case you might set the clock divider to be 16, and
the RANGE to 1023. The pulse repetition frequency will be
1.2MHz/1024 = 1171.875Hz.

Parameters:

    $divisor

Mandatory, Integer: An unsigned integer to set the pulse width to.

=head2 registered_pins()

Returns an array reference where each element is the GPIO pin number of each
currently registerd pin.

=head2 register_pin($pin_obj, $comment)

Registers a pin within the system for error checking, and proper resetting of
the pins in use when required.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::Pin> class.

    $comment

Optional, String: A descriptive string to help identify the pin's purpose.

=head2 unregister_pin($pin_obj)

Removes an already registered pin from the registry. This method shouldn't be
used in the normal course of operation, but is available for convenience
anyhow.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::Pin> class.

=head2 unregister_object

Removes an object from the shared memory data store.

B<NOTE>: This should only be used for testing purposes. It's simply a way to
remove objects from the register while bypassing the entire C<cleanup()>
routine.

=head2 cleanup

Resets all registered pins back to default settings as they were before your
program started. It also stops and cleans up any active interrupt handlers and
worker threads.

B<Note>: It's important that this method be called in each application.

=head1 ENVIRONMENT VARIABLES

There are certain environment variables available to aid in testing on
non-Raspberry Pi boards.

=head2 NO_BOARD

Set to true, will bypass the C<wiringPi> board checks. False will re-enable
them.

=head2 RPI_BOARD

Useful only for unit testing. Tells us that we're on Pi hardware.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
