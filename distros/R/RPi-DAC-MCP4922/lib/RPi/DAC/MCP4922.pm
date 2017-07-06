package RPi::DAC::MCP4922;

use strict;
use warnings;

our $VERSION = '2.3605';

use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:all);

require XSLoader;
XSLoader::load('RPi::DAC::MCP4922', $VERSION);

my $model_map = {
    4902    => 8,
    4912    => 10,
    4922    => 12,
};

# public methods

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;
    $self->_buf($args{buf});
    $self->_channel($args{channel});
    $self->_cs($args{cs});
    $self->_gain($args{gain});
    $self->_model($args{model});
    $self->_shdn_pin($args{shdn});

    wiringPiSetupGpio();
    spi_setup($self->_channel);

    pinMode($self->_cs, OUTPUT);
    digitalWrite($self->_cs, HIGH);

    if (defined $self->_shdn_pin){
        pinMode($self->_shdn_pin, OUTPUT);
        digitalWrite($self->_shdn_pin, LOW);
    }

    my $buf = _reg_init($self->_buf, $self->_gain);
    
    $self->register($buf);

    return $self;
}
sub disable_hw {
    my ($self) = shift;
    die "no SHDN pin has been spedified\n" if ! defined $self->_shdn_pin;
    _disable_hw($self->_shdn_pin);
}
sub disable_sw {
    my ($self, $dac) = @_;
    die "no DAC specified\n" if ! defined $dac;
    _disable_sw($self->_channel, $self->_cs, $dac, $self->register);

}
sub enable_hw {
    my ($self) = shift;
    die "no SHDN pin has been spedified\n" if ! defined $self->_shdn_pin;
    _enable_hw($self->_shdn_pin);
}
sub enable_sw {
    my ($self, $dac) = @_;
    die "no DAC specified\n" if ! defined $dac;
    _enable_sw($self->_channel, $self->_cs, $dac, $self->register);
}
sub register {
    my ($self, $buf) = @_;
    $self->{register} = $buf if defined $buf;
    return $self->{register} || 0;
}
sub set {
    #_set (channel, cs, dac, lsb, buf, data)

    my ($self, $dac, $value) = @_;

    my $buf =_set(
        $self->_channel, 
        $self->_cs, 
        $dac, 
        $self->_lsb, 
        $self->register,
        $value
    );
}

# private methods

sub _buf {
    my ($self, $buf) = @_;

    if (defined $buf && ($buf < 0 || $buf > 1)){
        die "buf must be either 0 or 1\n";
    }

    $self->{buf} = $buf if defined $buf;
    $self->{buf} = 0 if ! defined $self->{buf};

    return $self->{buf};
}
sub _channel {
    my ($self, $chan) = @_;

    if (defined $chan && ($chan < 0 || $chan > 1)){
        die "channel must be either 0 or 1\n";
    }

    $self->{chan} = $chan if defined $chan;

    return $self->{chan};
}
sub _cs {
    my ($self, $cs) = @_;

    if (defined $cs && ($cs < 0 || $cs > 63)){
        die "cs param is not a valid GPIO pin number\n";
    }

    $self->{cs} = $cs if defined $cs;

    return $self->{cs};
}
sub _data_lsb {
    # return the data LSB for a model of DAC

    my $self = shift;
    my $bits = $self->_model;

    return 12 - $bits;
}
sub _gain {
    my ($self, $gain) = @_;

    if (defined $gain && ($gain < 0 || $gain > 1)){
        die "gain must be either 0 or 1\n";
    }

    $self->{gain} = $gain if defined $gain;
    $self->{gain} = 1 if ! defined $self->{gain};

    return $self->{gain};
}
sub _model {
    my ($self, $model) = @_;

    if (defined $model && $model =~ /(\d{4})$/){
        my $model_num = $1;

        if (! exists $model_map->{$model_num}){
            die "invalid model param specified\n";
        }

        $self->{model} = $model_map->{$model_num};
    }

    die "no model specified!\n" if ! defined $self->{model};

    return $self->{model};
}
sub _shdn_pin {
    my ($self, $sd) = @_;

    if (defined $sd && ($sd < 0 || $sd > 63)){
        die "shdn param is not a valid GPIO pin number\n";
    }

    $self->{shdn} = $sd if defined $sd;

    return $self->{shdn};
}
sub _lsb {
    my $self = shift;
    return 12 - $self->{model};
}
sub _vim{};

1;
__END__

=head1 NAME

RPi::DAC::MCP4922 - Interface to the MCP49x2 series digital to analog converters
(DAC) over the SPI bus

=head1 DESCRIPTION

Interface to the MCP49x2 series Digital to Analog Converters (DAC) over the SPI
bus. These units have two onboard DACs, which are modified independently.

The MCP4902 has 8-bit resolution (max 255 data value), the MCP4912 has 10-bit
resolution (max val 1023), and the MCP4922 has 12-bit resolution (max val
4095).

=head1 SYNOPSIS

    my $dac = RPi::DAC::MCP4922->new(

        model   => 'MCP4922', # mandatory
        channel => 0,         # mandatory (SPI channel)
        cs      => 18,        # mandatory (GPIO pin num)
        buf     => 0,         # optional, default
        gain    => 1,         # optional, default
    );

    my ($dacA, $dacB) = (0, 1);

    $dac->set($dacA, 4095); # 100% output
    $dac->set($dacB, 0);    # 0% output

    $dac->disable_sw($dacB); # shuts onboard DAC B down
    $dac->enable_sw($dacB);  # turns it back on

    # NOTE

    # the SHDN pin on the IC is normally tied to 3.3v+ or 5v+ which
    # signifies that the DACs are always available. This SHDN pin
    # enables you to disable both DACs by pulling this pin LOW

    # to enable this functionality, connect the ICs SHDN pin to a GPIO
    # pin, then in the new() call, add the following param:

    shdn => 19 # GPIO pin num

    # if you do use this hardware feature, you MUST make a call to
    # enable_hw() after initialization of the object before you can
    # use either of the onboard DACs

    $dac->enable_hw;

    ...

=head1 METHODS

=head2 new

Instantiates a new L<RPi::DAC::MCP4922> object, sets up the GPIO and SPI, and
returns the object.

Parameters:

All parameters are sent in within a single hash.

There are three mandatory parameters, the rest are optional with very sane
defaults that shouldn't be used unless you understand the ramifications.

    model => $str

Mandatory: String. The model number of the MCP49xx DAC you're controlling.

    channel => $int

Mandatory: Integer. C<0> for SPI channel 0, or C<1> for SPI channel 1.

    cs => $int

Mandatory: Integer. The GPIO pin number connected to the DACs chip select (CS)
pin.

    buf => $int

Optional: Integer. C<0> for unbuffered output, and C<1> for buffered. This
software does not at this time use the C<LDAC> latch pin (and should be tied to
C<Gnd>), so although this param won't have any meaning, best to leave it set to
the default, C<0>.

    gain => $int

Optional: Integer. Sets the gain amplifier. C<1> for 1x gain (0v to 255/256 *
Vref), and C<0> for 2x gain (0v to 255/256 * 2 * Vref). Defaults to C<1>, or 1x
gain.

    shdn => $int

Optional: Integer. This is the GPIO pin number if you decide to use the C<SHDN>
(hardware shutdown pin #9) on the chip. Typically, this can simply be tied to
3.3v or 5v which means the DACs will always be active. If you do use this pin,
you *MUST* make a specific call to C<$dac->enable_hw()> before using either of
the onboard DACs.

=head2 set

Writes a new analog output value to one of the onboard DACs.

Parameters:

    $dac

Mandatory: Integer. C<0> for DAC A, or C<1> for DAC B.

    $value

Mandatory: Integer. The new value to write to the DAC. See L</DESCRIPTION> for
the respective values for each IC model.

=head2 disable_sw

Disables a specified onboard DAC's output via software. Both DACs are enabled
by default.

Parameters:

    $dac

Mandatory: Integer. C<0> for DAC A, or C<1> for DAC B.

=head2 enable_sw

Re-enables a specified onboard DAC's output via software.

Parameters:

    $dac

Mandatory: Integer. C<0> for DAC A, or C<1> for DAC B.

=head2 enable_hw

NOTE: The MCP49xx DAC IC chips have a C<SHDN> pin, which when pulled LOW,
disables via hardware the output on both onboard DACs. Normally, this pin is
simply tied to 3.3v+ or 5v+ which informs the hardware that both DACs will
always be active.

If you decide you want to tie the C<SHDN> pin to a GPIO pin and control this
feature manually, you have to initialize your L<RPi::DAC::MCP4922> object by
setting the C<shdn => $gpio_pin_num> in your call to C<new()>. Then, before
either of the DACs can be used, this method (C<enable_hw()>) MUST be called.

Takes no parameters.

=head2 disable_hw

Disables, via the hardware's C<SHDN> pin, the outputs of both onboard DACs.

See L</enable_hw> for more information on this feature.

Takes no parameters.

=head2 register

This is a helper function which allows you to view the configuration register at
various stages of this software's operation. I tend to use it to ensure I'm
getting proper bit strings back from the various inner operations:

    printf("%b\n", $dac->register);

Takes no parameters, returns the decimal value of the register as it's currently
configured.

=head1 TECHNICAL INFORMATION

=head2 DEVICE SPECIFICS

The MCP49x2 series chips have two onboard DACs (referred to as DAC A and DAC B).

The 4902 unit provides 8-bit output resolution (value 0-255), the 4912, 10-bit
(0-1023), and the 4922, 12-bit (0-4095).

=head2 DEVICE OPERATION

The MCP49x2 series digital to analog converters (DAC) operate as follows:

    - SHDN pin is an override to physically disable the DACs. It can be tied to
      3.3v+ or 5v+ for always-on, or tied to any GPIO pin so you can control the
      physical shutdown by putting the GPIO pin LOW
    - on startup, put the CS pin to HIGH. This indicates that there is no
      conversation occuring
    - turn the CS pin to LOW to start a conversation
    - send 16 bits (the write register) over the SPI bus while CS is LOW
    - turn the CS pin HIGH to end the conversation
    - as soon as the last bit is clocked in, the specified DAC will update its
      output level

=head2 DEVICE REGISTER

The write register is the same for all devices under the MCP49x2 umbrella, with
the differing devices having differing sizes for the data portion. Following is
a diagram that depicts the register for the different devices, where C<x> shows
that the bit is available, with a C<-> signifying that this bit will be ignored.
Note that a full 16-bits needs to be sent in regardless of chip type.

            |<---------------- Write Command Register --------------->|
            |                   |                                     |
            |<---- control ---->|<------------ data ----------------->|
            ] 15 | 14 | 13 | 12 | 11 10 09 08 07 06 05 04 03 02 01 00 |
            -----------------------------------------------------------
            | ^  |  ^ |  ^ |  ^ |               ^                     |
            |    |    |    |    |                                     |
            |A/B | BUF|GAIN|SHDN|              DATA                   |
            |---------------------------------------------------------|
    MCP4922 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  x  x | 12-bit
    MCP4912 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  x  x  -  - | 10-bit
    MCP4902 | x  |  x |  x |  x |  x  x  x  x  x  x  x  x  -  -  -  - |  8-bit
            -----------------------------------------------------------

=head2 REGISTER BITS

The device register is 16-bits wide.

=head3 DAC SELECT BITS

    bit 15

Specifies which DAC we're writing to with this write.

    Param   Value   DAC
    -------------------

    0       0b0     A
    1       0b1     B

=head3 BUFFERED BITS

    bit 14

Specifies whether to buffer the data (for use with the LATCH pin, if used) or
simply send it straight through to the DAC.

    Param   Value   Result
    ----------------------

    0       0b0     Unbuffered (default)
    1       0b1     Buffered

=head3 GAIN BITS

    bit 13

Specifies the value of the gain amplifier.

    Param   Value   Gain
    --------------------

    0       0b0     2x (Vout = 2 * Vref * D/4096)
    1       0b1     1x (Vout = Vref * D/4096) (default)

=head3 SHUTDOWN BITS

    bit 12

Allows you to programmatically shut down both DACs on the chip.

     Param  Value   Result
     ----------------------

     0      0b0     DACs active (default)
     1      0b1     DACs shut down

=head3 DATA BITS

    bits 11-0

These bits are used to set the output level.

    Model   Value   Bits
    --------------------

    MCP4922 0-4095  12
    MCP4912 0-1023  10
    MCP4902 0-255   8

The 10-bit and 8-bit models simply ignore the last 2 and 4 bits respectively.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
