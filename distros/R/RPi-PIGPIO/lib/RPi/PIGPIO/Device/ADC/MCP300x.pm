package RPi::PIGPIO::Device::ADC::MCP300x;

=head1 NAME

RPi::PIGPIO::Device::ADC::MCP300x - access the ADC convertor MCP3004 or MCP3008

=head1 DESCRIPTION

Communicate with the MCP3004 or MCP3008 analog-to-digital convertors

This convertors offer 10 bit conversions (range 0-1023) for 4 or 8 chanels

Comunication is done via harware SPI so MAKE SURE YOU ENABLED SPI on your RPi (use C<raspi-config> command and go to "Advanced")

See https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus 

=head1 SYNOPSIS
    
    use feature 'say';
    use RPi::PIGPIO;
    use RPi::PIGPIO::Device::ADC::MCP300x;

    my $pi = RPi::PIGPIO->connect('192.168.1.10');

    my $mcp = RPi::PIGPIO::Device::ADC::MCP300x->new(0);

    say "Sensor 1: " .$mcp->read(0);
    say "Sensor 2: " .$mcp->read(1);
=cut

use strict;
use warnings;

use Carp;

=head1 METHODS

=head2 new

Create a new object

Usage:

    my $mcp = RPi::PIGPIO::Device::ADC::MCP300x->new(0);

Arguments: 
$pi - an instance of RPi::PIGPIO
$spi_channel - SPI channel from which you want to read (0 or 1 corresponding to SPI CE0 / GPIO8 or SPI CE1 / GPIO 7)
$baud - clock speed for SPI communication (optional, defaults to 32K)

=cut
sub new {
    my ($class,$pi,$spi_channel, $baud) = @_;
    
    if (! defined $spi_channel) {
        croak "new() expects the second argument to be the SPI controll channel to which the device is connected!";
    }
    
    if (! $pi || ! ref($pi) || ref($pi) ne "RPi::PIGPIO") {
        croak "new expectes the first argument to be a RPi::PIPGIO object!";
    }
        
    my $self = {
        pi => $pi,
        spi_channel => $spi_channel,
        baud => $baud // 32_000,
    };
    
    bless $self, $class;
    
    return $self;
}

=head2 read

Read the value for a sensor connected to MCP3004 or MCP3008

Usage :

    my $value = $mcp->read(0);

=cut
sub read {
    my ($self,$ch) = @_;
    
    my $spi = $self->{pi}->spi_open($self->{spi_channel}, $self->{baud}, 0);
    
    croak "Failed to get handle for SPI communication with MCP300x device!" unless $spi >=0 && $spi < 100_000;
    
    my $command = 3 << 6;           # Start bit, single channel read
    $command |= ($ch & 0x07) << 3;   # Channel number (in 3 bits)
    
    my $response = $self->{pi}->spi_xfer($spi, [$command, 0, 0]);
    
    $self->{pi}->spi_close($spi);
    
    my @resp = unpack('L L L', $response);
    
    my $result = $resp[0];
    
    $result = $result & (0b1111111111 << 7);
    
    $result = $result >> 7;
        
    return $result;
}


1;