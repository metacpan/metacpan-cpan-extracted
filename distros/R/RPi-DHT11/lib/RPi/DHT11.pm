package RPi::DHT11;
use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '1.03';

require XSLoader;
XSLoader::load('RPi::DHT11', $VERSION);

sub new {
    my ($class, $pin, $debug) = @_;

    croak "you must supply a pin number\n" if ! defined $pin;

    my $self = bless {}, $class;
    $self->_pin($pin);

    setup();

    defined $debug
        ? c_debug($debug)
        : c_debug(0);

    return $self;
}
sub temp {
    my ($self, $want) = @_;

    # periodically, we get a strange return from the sensor,
    # where the temp is ~490. This is a dirty check to avoid
    # that

    my $temp = -100;

    until ($temp > -100 && $temp < 100){
        $temp = c_temp($self->_pin);
    }

    if (defined $want && $want =~ /f/i){
        $temp = $temp * 9 / 5 + 32;
    }
    return int($temp + 0.5);
}
sub humidity {
    my $self = shift;

    # same sanity check as temp()

    my $humidity = -1;

    until ($humidity > -1 && $humidity < 101){
        $humidity = c_humidity($self->_pin);
    }
    return $humidity;
}
sub cleanup {
    my $self = shift;
    return c_cleanup($self->_pin);
}
sub _pin {
    # set/get the pin number
    if (@_ == 2){
        $_[0]->{pin} = $_[1];
    }
    return $_[0]->{pin};
}
sub DESTROY {
    my $self = shift;
    $self->cleanup;
}
1;
__END__

=head1 NAME

RPi::DHT11 - Fetch the temperature/humidity from the DHT11 hygrometer sensor on
Raspberry Pi

=head1 SYNOPSIS

    use RPi::DHT11;

    my $pin = 18;

    my $env = RPi::DHT11->new($pin);

    my $temp     = $env->temp;
    my $humidity = $env->humidity;

=head1 DESCRIPTION

This module is an interface to the DHT11 temperature/humidity sensor when
connected to a Raspberry Pi's GPIO pins. We use the BCM GPIO pin numbering
scheme.

If you create an L<RPi::WiringPi> object before creating an object in this
class, you can set up the C<RPi::WiringPi> object with whichever pin
numbering scheme you choose, and this module will follow suit. Eg: if you
set C<RPi::WiringPi> to C<wpi> pin scheme, we'll use it here as well. Note,
though, that you MUST create the C<RPi::WiringPi> object before you create one
of this class!

This module requires the L<wiringPi|http://wiringpi.com/> library to be
installed, and uses WiringPi's GPIO pin numbering scheme (see C<gpio readall>
at the command line).

=head1 METHODS

=head2 new($pin, $debug)

Parameters:

    $pin

Mandatory. BCM GPIO pin number for the DHT11 sensor's DATA pin..

    $debug

Optional: Bool. True, C<1> to enable debug output, False, C<0> to disable.

=head2 temp('f')

Fetches the current temperature.

Returns an integer of the temperature, in Celcius by default.

Parameters:

    'f'

Optional: Send in the string char C<'f'> to receive the temp in Farenheit.

=head2 humidity

Fetches the current humidity.

Returns the current humidity percentage as an integer.

=head2 cleanup

Returns the pin back to default state if it's not already. Called automatically
by C<DESTROY()>.

=head1 ENVIRONMENT VARIABLES

There are a couple of env vars to help prototype and run unit tests when not on
a RPi board.

=head2 RDE_HAS_BOARD

Set to C<1> to tell the unit test runner that we're on a Pi.

=head2 RDE_NOBOARD_TEST

Set to C<1> to tell the system we're not on a Pi. Most methods/functions will
return default (ie. non-live) data when in this mode.

=head1 SEE ALSO

- L<wiringPi|http://wiringpi.com/>, L<WiringPi::API>, L<RPi::WiringPi>

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.org<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
