package RPi::PIGPIO::Device::Switch;

=head1 NAME

RPi::PIGPIO::Device::Switch - Turn on and off a switch

=head1 DESCRIPTION

Turn on and off a device connected to a local or remote RapsberryPi

What this actually does is set the GPIO to output and allow you to set the levels to HI or LOW

The device can be enything that accept TTL signal as a command (eg: relay, LED )

=head1 SYNOPSIS

    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::Switch;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $switch = RPi::PIGPIO::Device::Switch->new($pi,4);

    $switch->on;

    sleep 3;

    $switch->off;

=cut

use strict;
use warnings;

use Carp;
use RPi::PIGPIO qw/PI_OUTPUT LOW HI PI_CMD_BR1/;

=head1 METHODS

=head2 new

Create a new object

Usage:

    my $switch = RPi::PIGPIO::Device::Switch->new($pi,$gpio);

Arguments: 

=over 4

=item * $pi - an instance of RPi::PIGPIO

=item * $gpio - GPIO number to which the LED is connected

=back

=cut
sub new {
    my ($class,$pi,$gpio) = @_;
    
    if (! $gpio) {
        croak "new() expects the second argument to be the GPIO number to which the device is connected!";
    }
    
    if (! $pi || ! ref($pi) || ref($pi) ne "RPi::PIGPIO") {
        croak "new expectes the first argument to be a RPi::PIPGIO object!";
    }
    
    my $self = {
        pi => $pi,
        gpio => $gpio,
        status => undef,
    };
    
    $self->{pi}->set_mode($self->{gpio},PI_OUTPUT);
    
    bless $self, $class;
    
    return $self;
}

=head2 on

Turn on the connected device (set the TTL level to HI on the GPIO)

Usage :

    $switch->on();

=cut
sub on {
    my $self = shift;
    
    $self->{pi}->write($self->{gpio},HI);
}


=head2 off

Turn off the led (set the TTL level to LOW on the GPIO)

Usage :

    $switch->off();

=cut
sub off {
    my $self = shift;
    
    $self->{pi}->write($self->{gpio},LOW);
}


=head2 status

Returns the status of the device (checks if the GPIO is set to HI or LOW)

=cut
sub status {
    my $self = shift;
    
    my $gpio_levels = $self->{pi}->send_command(PI_CMD_BR1, 0, 0);
    
    my $status = $gpio_levels & (1<<$self->{gpio});
    
    return $status ? 1 : 0;
}

1;