package RPi::SPI;

use strict;
use warnings;

use WiringPi::API qw(:wiringPi);

our $VERSION = '2.3609';

sub new {
    my ($class, $channel, $speed) = @_;

    my $self = bless {}, $class;

    $self->_channel($channel);
    $self->_speed($speed);

    # check if we're in bit-banging mode

    if ($self->_cs){
        pin_mode($self->_cs, 1);
        write_pin($self->_cs, 1);
    }

    if (wiringPiSPISetup($self->_channel, $self->_speed) < 0){
        die "couldn't establish communication on the SPI bus\n";
    }

    return $self;
}
sub rw {
    my ($self, $buf, $len) = @_;

    if ($self->_cs){
        pin_mode($self->_cs, 0);
        @$buf = spiDataRW($self->_channel, $buf, $len);
        pin_mode($self->_cs, 1);
    }
    else {
        @$buf = spiDataRW($self->_channel, $buf, $len);
    }

    return @$buf;
}
sub _channel {
    my ($self, $chan) = @_;

    if (defined $chan){
        if ($chan > 1){
            $self->_cs($chan);
            $self->{channel} = 0;
        }
        else {
            $self->{channel} = $chan;
        }
    }

    return $self->{channel};
}
sub _cs {
    my ($self, $cs) = @_;

    $self->{cs} = $cs if defined $cs;
    return $self->{cs};
}
sub _speed {
    my ($self, $speed) = @_;
    $self->{speed} = $speed if defined $speed;
    return $self->{speed} || 1000000;
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::SPI - Communicate with devices over the Serial Peripheral Interface (SPI)
bus on Raspberry Pi

=head1 SYNOPSIS

    # channel 0 and 1 are the hardware SPI pins
    # CE0 and CE1

    my $spi = RPi::SPI->new(0);

    my $buf = [0x01, 0x02];
    my $len = 2;

    my @data = $spi->rw($buf, $len);

    # use a GPIO pin to expand the number of SPI
    # channels. We'll bit-bang automatically. The
    # GPIO pin must connect to the CS/SS pin on the
    # IC you're using

    $spi = RPi::SPI->new(26); # GPIO 26 is the CS

=head1 DESCRIPTION

This distribution provides you the ability to communicate with devices attached
to the channels on the Serial Peripheral Interface (SPI) bus. Although it was
designed for the Raspberry Pi, that's not a hard requirement, and it should work
on any Unix-type system that has support for SPI.

You can use the hardware SPI pins CE0 and CE1 on the Raspberry Pi, but if you
need more SPI slaves, we'll also automatically bit-bang the SPI bus using
a standard GPIO pin for the Slave Select instead.

=head1 METHODS

=head2 new

Instantiates a new L<RPi::SPI> instance, prepares a specific SPI bus channel for
use, then returns the object.

Parameters:

    $channel

The SPI bus channel to initialize.

Mandatory: Integer, C<0> for C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>.
You can also send in any number above C<1>. If so, we'll treat it as a GPIO
pin (connected to the CS/SS pin of the IC), and we'll bit-bang the CS
automatically as to free up the onboard hardware channels.

    $speed

Optional, Integer. The data rate to communicate on the bus using. Defaults to
C<1000000> (1MHz).

Dies if we can't open the SPI bus.

=head2 rw

Writes specified data to the bus on the channel specified in C<new()>, then
after completion, does a read of the bus and re-populates the write buffer with
the freshly read data, and returns it as an array.

Parameters:

    $buf

Mandatory: Array reference where each element is an unsigned char (0-255). This
array is the write buffer; the data we'll be sending to the SPI bus.

    $len

Mandatory: Integer, the number of array elements in the C<$buf> parameter sent
in above.

Return: The write buffer, after being re-populated with the read data, as a Perl
array.

Dies if we can't open the SPI bus.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017,2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
