package RPi::WiringPi::Util;

use strict;
use warnings;

use parent 'WiringPi::API';

use RPi::WiringPi::Constant qw(:all);

our $VERSION = '2.3613';

sub gpio_layout {
    return $_[0]->gpio_layout;
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
sub pwm_range {
    my ($self, $range) = @_;
    if (defined $range){
       $self->{pwm_range} = $range;
        $self->pwm_set_range($range);
    }
    return defined $self->{pwm_range} ? $self->{pwm_range} : 1023;
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
    my ($self, $env) = @_;
    return $ENV{RPI_PINS};
}
sub register_pin {
    my ($self, $pin) = @_;

    my $gpio_num = $self->pin_to_gpio($pin->num);

    if (defined $ENV{RPI_PINS} && grep {$gpio_num == $_} split /,/, $ENV{RPI_PINS}){
        die "\npin $pin is already in use... can't re-register it\n";
    }

    $ENV{RPI_PINS} = ! defined $ENV{RPI_PINS}
        ? $gpio_num
        : "$ENV{RPI_PINS},$gpio_num";
}
sub unregister_pin {
    my ($self, $pin) = @_;

    my @pin_nums = split /,/, $self->registered_pins;

    my @updated_list;

    for my $pin_num (@pin_nums){
        if ($pin->num == $pin_num){
            $pin->mode(INPUT);
        }
        else {
            push @updated_list, $pin_num;
        }
    }

    $ENV{RPI_PINS} = join ",", @updated_list;
}
sub cleanup{
    my $pins = $ENV{RPI_PINS};
    return if ! $ENV{RPI_PINS};

    for (split /,/, $pins){
        `gpio -g mode $_ in`;
        `gpio -g mode $_ tri`;
        delete $ENV{RPI_PINS};
    }
}
sub _vim{1;};
1;

__END__

=head1 NAME

RPi::WiringPi::Util - Utility methods for RPi::WiringPi Raspberry Pi
interface

=head1 DESCRIPTION

This module contains various utilities for L<RPi::WiringPi> that don't
necessarily fit anywhere else. It is a base class, and is not designed to be
used independently.

=head1 METHODS

=head2 gpio_layout()

Returns the GPIO layout which indicates the board revision number.

=head2 pin_scheme()

Returns the current pin mapping in use. Returns C<0> for C<wiringPi> scheme,
C<1> for GPIO, C<2> for System GPIO, C<3> for physical board and C<-1> if a
scheme has not yet been configured (ie. one of the C<setup*()> methods has
not yet been called).

If using L<RPi::WiringPi::Constant>, these map out to:

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

=head2 pin_to_gpio($pin, $scheme)

Dynamically converts the specified pin from the specified scheme
(C<RPI_MODE_WPI> (wiringPi), or C<RPI_MODE_PHYS> (physical board numbering
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

=head2 export_pin($pin_num)

Exports a pin. Only needed if using the C<setup_sys()> initialization method.

Pin number must be the C<GPIO> pin number representation.

=head2 unexport_pin($pin_num)

Unexports a pin. Only needed if using the C<setup_sys()> initialization method.

Pin number must be the C<GPIO> pin number representation.

=head2 registered_pins()

Returns a list of comma-separated pin numbers in GPIO scheme that have been used
in your program run.

=head2 register_pin($pin_obj)

Registers a pin within the system for error checking, and proper resetting of
the pins in use when required.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::WiringPi::Pin> class.

=head2 unregister_pin($pin_obj)

Removes an already registered pin from the registry. This method shouldn't be
used in the normal course of operation, but is available for convenience
anyhow.

Parameters:

    $pin_obj

Mandatory: An object instance of L<RPi::WiringPi::Pin> class.

=head2 cleanup()

Resets all registered pins back to default settings (off). It's important that
this method be called in each application.

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

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
