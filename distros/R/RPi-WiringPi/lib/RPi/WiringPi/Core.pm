package RPi::WiringPi::Core;

use strict;
use warnings;

use parent 'WiringPi::API';
use parent 'RPi::SysInfo';
use JSON;
use RPi::Const qw(:all);

our $VERSION = '2.3633';

sub gpio_layout {
    return $_[0]->gpio_layout;
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

    if ($tweak){
        # stop disk activity from operating the green LED
        `echo none | sudo tee /sys/class/leds/led0/trigger`;
        # turn on the green LED full-time
        `echo 1 | sudo tee /sys/class/leds/led0/brightness`;
    }
    else {
        # turn off the green LED from being on full-time
        `echo 0 | sudo tee /sys/class/leds/led0/brightness`;
        # start disk activity operating the green LED
        `echo mmc0 | sudo tee /sys/class/leds/led0/trigger`;
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
    elsif ($scheme == RPI_MODE_PHYS){
        return $self->phys_to_gpio($pin);
    }
    elsif ($scheme == RPI_MODE_GPIO){
        return $pin;
    }
    if ($scheme == RPI_MODE_UNINIT){
        die "setup not run; pin mapping scheme not initialized\n";
    }
}
sub pin_map {
    my ($self, $scheme) = @_;

    $scheme = $self->pin_scheme if ! defined $scheme;

    return {} if $scheme eq RPI_MODE_UNINIT;

    if (defined $self->{pin_map_cache}{$scheme}){
        return $self->{pin_map_cache}{$scheme};
    }

    my %map;

    for (0..63){
        my $pin;
        if ($scheme == RPI_MODE_WPI) {
            $pin = $self->phys_to_wpi($_);
        }
        elsif ($scheme == RPI_MODE_GPIO){
            $pin = $self->phys_to_gpio($_);
        }
        elsif ($scheme == RPI_MODE_PHYS){
            $pin = $_;
        }
        $map{$_} = $pin;
    }
    $self->{pin_map_cache}{$scheme} = \%map;

    return \%map;
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
sub pwr_led {
    my ($self, $tweak) = @_;

    if ($tweak){
        # turn off the red power LED
        `echo 0 | sudo tee /sys/class/leds/led1/brightness`;
    }
    else {
        # low power input to operate the red power LED
        `echo input | sudo tee /sys/class/leds/led1/trigger`;
    }
}
sub pwm_range {
    my ($self, $range) = @_;
    if (defined $range){
        $self->{pwm_range} = $range;
        $self->pwm_set_range($range);
    }
    #FIXME: add const
    return defined $self->{pwm_range} ? $self->{pwm_range} : 1023;
}
sub pwm_clock {
    my ($self, $divisor) = @_;
    if (defined $divisor){
        $self->{pwm_clock} = $divisor;
        $self->pwm_set_clock($divisor);
    }
    return defined $self->{pwm_clock} ? $self->{pwm_clock} : PWM_DEFAULT_CLOCK;
}
sub pwm_mode {
    my ($self, $mode) = @_;
    if (defined $mode && ($mode == 0 || $mode == PWM_DEFAULT_MODE)){
        $self->{pwm_mode} = $mode;
        $self->pwm_set_mode($mode);
    }
    else {
        die "pwm_mode() requires either 0 or 1 if a param is sent in\n";
    }
    return defined $self->{pwm_mode} ? $self->{pwm_mode} : 1;
}
sub export_pin {
    my ($self, $pin) = @_;
    system "sudo", "gpio", "export", $self->pin_to_gpio($pin), "in";
}
sub unexport_pin {
    my ($self, $pin) = @_;
    system "sudo", "gpio", "unexport", $self->pin_to_gpio($pin);
}
sub registered_pins {
    return $_[0]->_pin_registration;
}
sub register_pin {
    my ($self, $pin) = @_;
    $self->_pin_registration($pin, $pin->mode_alt, $pin->read, $pin->mode);
}
sub unregister_pin {
    my ($self, $pin) = @_;
    $self->_pin_registration($pin);
}
sub cleanup{
    if ($ENV{PWM_IN_USE}){
        WiringPi::API::pwm_set_mode(PWM_DEFAULT_MODE);
        WiringPi::API::pwm_set_clock(PWM_DEFAULT_CLOCK);
        WiringPi::API::pwm_set_range(PWM_DEFAULT_RANGE);
    }

    return if ! $ENV{RPI_PINS};

    my $pins = decode_json $ENV{RPI_PINS};

    for my $pin (keys %{ $pins }){
        WiringPi::API::pin_mode_alt($pin, $pins->{$pin}{alt});
        WiringPi::API::write_pin($pin, $pins->{$pin}{state});
        WiringPi::API::pin_mode($pin, $pins->{$pin}{mode});
    }
    delete $ENV{RPI_PINS};
}
sub _pin_registration {
    # manages the registration duties for pins

    my ($self, $pin, $alt, $state, $mode) = @_;

    my $json = $ENV{RPI_PINS};
    my $perl = defined $json ? decode_json $json : {};

    if (! defined $pin){
        my @registered_pins = keys %{ $perl };
        return \@registered_pins;
    }

    if (! defined $alt){
        if (defined $perl->{$self->pin_to_gpio($pin->num)}){
            $pin->mode_alt($perl->{$pin->num}{alt});
            $pin->write($perl->{$pin->num}{state});
            $pin->mode($perl->{$pin->num}{mode});
            delete $perl->{$self->pin_to_gpio($pin->num)};
            $ENV{RPI_PINS} = encode_json $perl;
            return;
        }
    }

    die "_pin_registration() requires both \$alt and \$state params\n"
      if ! defined $state;

    if (exists $perl->{$self->pin_to_gpio($pin->num)}){
        my $gpio_pin_num = $self->pin_to_gpio($pin->num);
        die "pin $gpio_pin_num is already in use, can't continue...\n";
    }

    $perl->{$self->pin_to_gpio($pin->num)}{alt} = $alt;
    $perl->{$self->pin_to_gpio($pin->num)}{state} = $state;
    $perl->{$self->pin_to_gpio($pin->num)}{mode} = $mode;

    my @registered_pins = keys %{ $perl };

    $json = encode_json $perl;
    
    $ENV{RPI_PINS} = $json;

    return \@registered_pins;
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

=head2 gpio_layout()

Returns the GPIO layout which indicates the board revision number.

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

=head2 identify($seconds)

This method wraps the L<io_led()|/io_led($tweak)> and
L<pwr_led()|/pwr_led($tweak)> methods.

Parameters:

    $seconds

Optional, Integer: The number of seconds to remain in "identify" state. Defaults
to C<5>.

In "identify" state, the green disk I/O LED will remain on constantly, and the
red power LED will stay off for the duration.

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
C<1> for GPIO, C<2> for System GPIO, C<3> for physical board and C<-1> if a
scheme has not yet been configured (ie. one of the C<setup*()> methods has
not yet been called).

If using L<RPi::Const>, these map out to:

    0  => RPI_MODE_WPI
    1  => RPI_MODE_GPIO
    2  => RPI_MODE_GPIO_SYS # unused in RPi::WiringPi
    3  => RPI_MODE_PHYS
    -1 => RPI_MODE_UNINIT

=head2 pin_map($scheme)

Returns a hash reference in the following format:

    $map => {
        phys_pin_num => pin_num,
        ...
    };

If no scheme is in place or one isn't sent in, return will be an empty hash
reference.

Parameters:

    $scheme

Optional: By default, we'll check if you've already run a setup routine, and
if so, we'll use the scheme currently in use. If one is not in use and no
C<$scheme> has been sent in, we'll return an empty hash reference, otherwise
if a scheme is sent in, the return will be:

For C<'wiringPi'> scheme:

    $map = {
        phys_pin_num => wiringPi_pin_num,
        ....
    };

For C<'GPIO'> scheme:

    $map = {
        phys_pin_num => gpio_pin_num,
        ...
    };

=head2 pin_to_gpio($pin, [$scheme])

Dynamically converts the specified pin from the specified scheme
C<RPI_MODE_WPI> (wiringPi), or C<RPI_MODE_PHYS> (physical board numbering
scheme) to the GPIO number format.

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

=head2 export_pin($pin_num)

Exports a pin. Only needed if using the C<setup_sys()> initialization method.

Pin number must be the C<GPIO> pin number representation.

=head2 unexport_pin($pin_num)

Unexports a pin. Only needed if using the C<setup_sys()> initialization method.

Pin number must be the C<GPIO> pin number representation.

=head2 registered_pins()

Returns an array reference where each element is the GPIO pin number of each
currently registerd pin.

=head2 register_pin($pin_obj)

Registers a pin within the system for error checking, and proper resetting of
the pins in use when required.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::Pin> class.

=head2 unregister_pin($pin_obj)

Removes an already registered pin from the registry. This method shouldn't be
used in the normal course of operation, but is available for convenience
anyhow.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::Pin> class.

=head2 cleanup()

Resets all registered pins back to default settings as they were before your
program started. It's important that this method be called in each application.

=head1 ENVIRONMENT VARIABLES

There are certain environment variables available to aid in testing on
non-Raspberry Pi boards.

=head2 NO_BOARD

Set to true, will bypass the C<wiringPi> board checks. False will re-enable
them.

=head2 PI_BOARD

Useful only for unit testing. Tells us that we're on Pi hardware.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2019 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
