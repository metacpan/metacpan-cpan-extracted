package RPi::HCSR04;

use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('RPi::HCSR04', $VERSION);

BEGIN {
    no strict 'refs';

    my @subs = qw(_trig _echo);

    for my $sub (@subs){
        *$sub = sub {
            my ($self, $p) = @_;

            if (defined $p){
                if ($p < 0 && $p > 40){
                    die "$sub pin number '$p' is out of range\n";
                }
                $self->{$sub} = $p;
            }
            return $self->{$sub};
        }
    }
}

sub new {
    # trig, echo pins
    my ($self, $t, $e) = @_;

    if (! defined $t || ! defined $e){
        die "new() requires both a trig and echo pin number sent in\n";
    }

    $self->_trig($t);
    $self->_echo($e);

    setup($t, $e);

    return $self;
}
sub inch {
    my $self = shift;
    return inch_c($self->_trig, $self->_echo);
}
sub cm {
    my $self = shift;
    return cm_c($self->_trig, $self->_echo);
}
sub raw {
    my $self = shift;
    return raw_c($self->_trig, $self->_echo);
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::HCSR04 - Interface to the HC-SR04 ultrasonic distance measurement sensor
on the Raspberry Pi

=head1 SYNOPSIS

    use RPi::HCSR04;

    my $trig_pin = 23;
    my $echo_pin = 24;

    my $sensor = RPi::HCSR04->new($trig_pin, $echo_pin);

    my $inches = $sensor->inch;
    my $cm     = $sensor->cm;
    my $raw    = $sensor->raw;

    ...

=head1 DESCRIPTION

Easy to use interface to retrieve distance measurements from the HC-SR04
ultrasonic distance measurement sensor.    

Requires L<wiringPi|http://wiringpi.com> to be installed.

=head1 VOLTAGE DIVIDER

The HC-SR04 sensor requires 5V input, and that is returned back to a Pi GPIO
pin from the C<ECHO> output on the sensor. The GPIO on the Pi can only handle
a maximum of 3.3V in, so either a voltage regulator or a voltage divider must
be used to ensure you don't damage the Pi.

L<Here's|https://stevieb9.github.io/rpi-hcsr04/hcsr04.png> a diagram showing
how to create a voltage divider with a 1k and a 2k Ohm resistor to lower the
C<ECHO> voltage output down to a safe ~3.29V. In this case, C<TRIG> is
connected to GPIO 18, and C<ECHO> is connected to GPIO 23.

=head1 METHODS

=head2 new

Instantiates and returns a new L<RPi::HCSR04> object.

Parameters:

    $trig

Mandatory: Integer, the GPIO pin number of the Raspberry Pi that the C<TRIG>
pin is connected to.

    $echo

Mandatory: Integer, the GPIO pin number of the Raspberry Pi that the C<ECHO>
pin is connected to.

=head2 inch

Returns a floating point number containing the distance in inches. Takes no
parameters.

=head2 cm

Returns a floating point number containing the distance in centemetres. Takes
no parameters.

=head2 raw

Returns an integer representing the return from the sensor in raw original
form. Takes no parameters.

=head1 C FUNCTIONS

These are to be only used within the module itself.

=head2 setup

Performs the wiringPi setup routine.

=head2 raw_c

Called by C<raw()>.

=head2 inch_c

Called by C<inch()>.

=head2 cm_c

Called by C<cm()>.

=head1 REQUIREMENTS

* L<wiringPi|http://wiringpi.com> must be installed.
* At this time, your program will have to be run as root (under C<sudo>).
* You must regulate the voltage from the C<ECHO> pin down to a safe 3.3V from
the 5V input. See L</VOLTAGE DIVIDER> for details.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
