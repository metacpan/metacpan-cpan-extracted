package RPi::DigiPot::MCP4XXXX;

use warnings;
use strict;

our $VERSION = '2.3604';

use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:all);

sub new {
    if (@_ !=3 && @_ != 4){
        die "new() requires \$cs and \$channel at minimum\n";
    }

    my ($class, $cs, $channel, $speed) = @_;

    my $self = bless {}, $class;
    $self->_cs($cs);
    $self->{len} = 2;

    wiringPiSetupGpio();

    wiringPiSPISetup(
        $self->_channel($channel),
        $self->_speed($speed)
    );

    pinMode($self->_cs, OUTPUT);
    digitalWrite($self->_cs, HIGH);

    return $self;
}
sub set {
    my ($self, $data, $pot) = @_;

    if ($data < 0 || $data > 255){
        die "set() requires 0-255 as the data param\n";
    }

    if (defined $pot){
        if ($pot !=1 && $pot != 2 && $pot != 3){
            die "set() \$pot param must be 1-3\n";
        }
    }
   
    my $cmd = 0x01;
    $pot = 1 if ! defined $pot;

    my $bytes = $self->_bytes($cmd, $pot, $data);

    digitalWrite($self->_cs, LOW);
    spiDataRW($self->_channel, $bytes, $self->_len);
    digitalWrite($self->_cs, HIGH);
}
sub shutdown {
    my ($self, $pot) = @_;

    if (defined $pot){
        if ($pot !=1 && $pot != 2 && $pot != 3){
            die "set() \$pot param must be 1-3\n";
        }
    }

    my $data = 0;
    my $cmd = 0x02; # shutdown bit
    $pot = 1 if ! defined $pot;
    
    my $bytes = $self->_bytes($cmd, $pot, $data);

    spiDataRW($self->_channel, $bytes, $self->_len);
}
sub _bytes {
    
    # calculates and returns an aref of control/data bytes

    my ($self, $cmd, $chan, $data) = @_;

    if (! defined $cmd || ! defined $chan || ! defined $data){
        die "_bytes() requires \$cmd, \$chan (pot) and \$data params\n";
    }

    # shift the command byte left to get a nibble,
    # then OR the channel nibble to it

    my $cntl = ($cmd << 4) | $chan;
   
    return [$cntl, $data];
}
sub _channel {

    # sets/gets the SPI channel

    my ($self, $chan) = @_;
    $self->{channel} = $chan if defined $chan;

    if ($self->{channel} != 0 && $self->{channel} != 1){
        die "\$channel param must be 0 or 1\n";
    }

    return $self->{channel};
}
sub _cs {

    # sets/gets the chip select (CS) pin

    my ($self, $pin) = @_;

    if (defined $pin && ($pin < 0 || $pin > 63)){
        die "cs() param must be a valid GPIO pin number\n";
    }

    $self->{cs} = $pin if defined $pin;

    if (! defined $self->{cs}){
        die "cs() can't continue, we're not configured with a pin\n";
    }

    return $self->{cs};
}
sub _len {
    
    # returns the number of bytes to send to SPI
    # this number is hardcoded in new()

    my $self = shift;
    return $self->{len};
}
sub _speed {

    # sets/gets the SPI bus speed

    my ($self, $speed) = @_;
    $self->{speed} = $speed if defined $speed;
    $self->{speed} = 1000000 if ! defined $self->{speed}; # 1 MHz
    return $self->{speed};
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::DigiPot::MCP4XXXX - Interface to the MCP4xxxx series digital potentiometers
on the Raspbery Pi

=head1 DESCRIPTION

This distribution allows you to interface directly with the MCP41xxx and
MCP42xxx series digital potentiomenters attached to the SPI bus on the
Raspberry Pi.

The MCP41xxx units have a single built-in potentiometer, where the MCP42xxx
units have two.

Both series will operate on either 3.3V or 5V, as the potentiometers do not send
anything back to the Pi's GPIO.

This software requires L<wiringPi|http://wiringpi.com> to be installed, as we
use its L<SPI library|http://wiringpi.com/reference/spi-library> to communicate
to the potentiometer over the SPI bus.

=head1 SYNOPSIS

    # GPIO pin number connected to the potentiometer's
    # CS (Chip Select) pin

    my $cs = 18;  

    # SPI bus channel

    my $chan = 0;

    my $dpot = RPi::DigiPot::MCP4XXXX->new($cs, $chan);

    # potentiometer's output level (0-255).
    # 127 == ~50% output

    my $output = 127; 

    # set the output level

    $dpot->set($output);

    # shutdown (put to sleep) the potentiometer

    $dpot->shutdown;

=head1 METHODS

=head2 new

Instantiates a new L<RPi::DigiPot::MCP4XXXX> object, initiates communication
with the SPI bus, and returns the object.

Parameters:

    $cs

Mandatory: Integer, the GPIO pin number that connects to the potentiometer's
Chip Select C<CS> pin. This is the pin we use to start and finish communication
with the device over the SPI bus.

    $channel

Mandatory: Integer, represents the SPI bus channel that the potentiometer is
connected to. C<0> for C</dev/spidev0.0> or C<1> for C</dev/spidev0.1>.

    $speed

Optional: Integer. The clock speed to communicate on the SPI bus at. Defaults
to C<1000000> (ie: C<1MHz>).

=head2 set

This method allows you to set the variable output on the potentiometer(s).
These units have 256 taps, allowing that many different output levels.

Parameters:

    $data

Mandatory: Integer bewteen C<0> for 0% output and C<255> for 100% output.

    $pot

Optional: Integer, instructs the software which of the onboard potentiometers
to set the output voltage on. C<1> for the first potentiometer, C<2> for the second, and C<3> to change the value on both. Defaults to C<1>.

NOTE: Only the MCP42xxx units have dual built-in potentiometers, so if you have
an MCP41xxx unit, leave the default C<1> set for this parameter.

=head2 shutdown

The onboard potentiometers allow you to shut them down when not in use,
resulting in electricity usage. Using C<set()> will bring it out of sleep.

Parameters:

    $pot

Optional: Integer, the built-in potentiometer to shut down. C<1> for the first
potentiometer, C<2> for the second, and C<3> to change the value on both.
Defaults to C<1>.

NOTE: Only the MCP42xxx units have dual built-in potentiometers, so if you have
an MCP41xxx unit, leave the default C<1> set for this parameter.

=head1 TECHNICAL INFORMATION

View the MCP4XXX L<datasheet|https://stevieb9.github.io/rpi-digipot-mcp4xxxx/datasheet/mcp4xxxx.pdf>.

=head2 OVERVIEW

The MCP4xxxx series digital potentiometers operate as follows:

    - CS pin goes LOW, signifying data is about to be sent
    - exactly 16 bits are sent over SPI to the digipot (first 8 bits for control
      second 8 bits for data)
    - CS pin goes HIGH, signifying communication is complete

There must be exactly 16 bits of data clocked in, or the commands and data will
be thrown away, and nothing accomplished.

Here's a diagram of the two bytes combined into a single bit string, showing the
respective positions of the bits, and their function:

         |<-Byte 1: Control->|<-Byte 0: Data->|
         |                   |                |
    fcn: | command | channel |      data      |
         |---------|---------|----------------|
    bit: | 7 6 5 4 | 3 2 1 0 | 7 6 5 4 3 2 1 0|
         --------------------------------------
           ^                                 ^
           |                                 |
       MSB (bit 15)                      LSB (bit 0)

=head2 CONTROL BYTE

The control byte is the most significant byte of the overall data being clocked
into the potentiometer, and consists of a command nibble and a channel nibble.

=head3 COMMAND

The command nibble is the most significant (leftmost) 4 bits of the control
byte (bits 7-4 in the above diagram). The following diagram describes all
possible valid values.

    Bits    Value
    -------------

    0000    NOOP
    0001    set a new resistance value
    0010    put potentiometer into 'shutdown' mode
    0011    NOOP

=head3 CHANNEL

The channel nibble is the least significant 4 bits (rightmost) of the control
byte (bits 3-0 in the above diagram). Valid values follow. Note that the
MCP41xxx series units have only a single potentiometer built in, there's but
one valid value for them.

    Bits    Value
    -------------

    0001    potentiometer 0
    0010    potentiometer 1 (MCP42xxx only)
    0011    both 0 and 1    (MCP42xxx only)

=head2 DATA BYTE

The data byte consists of the least significant 8 bits (rightmost) of the 16 bit
combined data destined to the potentiometer. Both the MCP41xxx and MCP42xxx
series potentiometers contain 256 taps, so the mapping of this byte is simple:
valid values are C<0> (0% output) through C<255> (100% output).

=head2 REGISTER BIT SEQUENCE

Here's an overview of the bits in order:

C<15-14>: Unused ("Don't Care Bits", per the datasheet)

C<13-12>: Command bits

C<11-10>: Unused

C<9-8>: Channel (built-in potentiomenter) select bits

C<7-0>: Potentiometer tap setting data (0-255)

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

