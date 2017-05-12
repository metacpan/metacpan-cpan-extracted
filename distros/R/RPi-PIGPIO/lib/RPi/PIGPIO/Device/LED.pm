package RPi::PIGPIO::Device::LED;

=head1 NAME

RPi::PIGPIO::Device::LED - Turn on and off a LED

=head1 DESCRIPTION

Turn on and off a led connected to a local or remote RapsberryPi

What this actually does is set the GPIO to output and allow you to set the levels to HI or LOW

=head1 SYNOPSIS

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::LED;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $led = RPi::PIGPIO::Device::LED->new($pi,17);

    $led->on;

    sleep 3;

    $led->off;

=cut

use strict;
use warnings;

use base 'RPi::PIGPIO::Device::Switch';

=head1 METHODS

=head2 new

Create a new object

Usage:

    my $led = RPi::PIGPIO::Device::LED->new($pi,$gpio);

Arguments: 

=over 4

=item * $pi - an instance of RPi::PIGPIO

=item * $gpio - GPIO number to which the LED is connected

=back

=head2 on

Turn on the led

Usage :

    $led->on();

=head2 off

Turn off the led

Usage :

    $led->off();

=head2 status

Returns the status of the led (checks if the GPIO is set to HI or LOW)

=cut


1;