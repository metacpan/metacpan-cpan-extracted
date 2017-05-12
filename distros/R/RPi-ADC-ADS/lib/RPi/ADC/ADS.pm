package RPi::ADC::ADS;

use strict;
use warnings;

our $VERSION = '1.01';

require XSLoader;
XSLoader::load('RPi::ADC::ADS', $VERSION);

use constant {

    DEFAULT_QUEUE       => 0x03,  # bits 1-0 (0-3)
    MAX_QUEUE           => 0x03,

    DEFAULT_POLARITY    => 0x00,  # bit  3
    MAX_POLARITY        => 0x08,

    DEFAULT_RATE        => 0x00,  # bits 7-5
    MAX_RATE            => 0xE0,

    DEFAULT_MODE        => 0x100, # bit  8
    MAX_MODE            => 0x100,

    DEFAULT_GAIN        => 0x200, # bits 11-9
    MAX_GAIN            => 0xE00,

    DEFAULT_CHANNEL     => 0x4000, # bits 14-12
    MAX_CHANNEL         => 0x7000,
};

# channel multiplexer

my %mux = (
    # bit 14-12 (most significant bit shown)

    # single-ended
    0 => 0x4000, # 01000000, 16384
    1 => 0x5000, # 01010000, 20480
    2 => 0x6000, # 01100000, 24576
    3 => 0x7000, # 01110000, 28672

    # differential
    4 => 0x0,    # 00000000, 0
    5 => 0x1000, # 00100000, 4096
    6 => 0x2000, # 00100000, 8192
    7 => 0x3000, # 00110000, 12288
);

# comparitor queue

my %queue = (
    # bit 1-0 (least significant bit shown)

    0 => 0x00, # 00000000, 0
    1 => 0x01, # 00000001, 1
    2 => 0x02, # 00000010, 2
    3 => 0x03, # 00000011, 3
);

# comparator polarity

my %polarity = (
    # bit 3 (least significant bit shown)

    0 => 0x00, # 00000000, 0
    1 => 0x08, # 00000001, 8
);

# data rate

my %rate = (
    # bit 7-5 (least significant bit shown)

    0 => 0x00, # 00000000, 0
    1 => 0x20, # 00100000, 32
    2 => 0x40, # 01000000, 64
    3 => 0x60, # 01100000, 96
    4 => 0x80, # 10000000, 128
    5 => 0xA0, # 10100000, 160
    6 => 0xC0, # 00000001, 192
    7 => 0xE0, # 00000001, 224
);

# operating mode

my %mode = (
    # bit 8 (both bits shown)

    0 => 0x00,  # 0|00000000, 0
    1 => 0x100, # 1|00000000, 256
);

# amplifier gain

my %gain = (
    # bit 11-9 (most significant bit shown)

    0 => 0x00,  # 00000000, 0
    1 => 0x200, # 00000010, 512
    2 => 0x400, # 00000100, 1024
    3 => 0x600, # 00000110, 1536
    4 => 0x800, # 00001000, 2048
    5 => 0xA00, # 00001010, 2560
    6 => 0xC00, # 00001100, 3072
    7 => 0xE00, # 00001110, 3584
);

# map of all the above config register maps

my $param_map;

BEGIN {

    $param_map = {
        channel  => \%mux,
        queue    => \%queue,
        polarity => \%polarity,
        rate     => \%rate,
        mode     => \%mode,
        gain     => \%gain,
    };

    no strict 'refs';

    for my $sub (keys %$param_map) {

        *$sub = sub {

            my ($self, $opt) = @_;

            if (defined $opt) {
                if (! exists $param_map->{$sub}{$opt}) {
                    die "$sub param requires an integer\n";
                }
                $self->{$sub} = $param_map->{$sub}{$opt};
            }

            my $default = "DEFAULT_" . uc $sub;
            my $max     = "MAX_"     . uc $sub;

            $self->{$sub} = __PACKAGE__->$default if ! defined $self->{$sub};
            $self->_bit_set($self->{$sub}, __PACKAGE__->$max);
            return $self->{$sub};
        }
    }
}

# object methods (public)

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    # set up the initial default config register

    $self->register(0x80, 0x00);

    # primary C args

    $self->model($args{model});
    $self->addr($args{addr});
    $self->device($args{device});

    # control register switches

    $self->channel($args{channel});
    $self->queue($args{queue});
    $self->polarity($args{polarity});
    $self->mode($args{mode});
    $self->gain($args{mode});

    return $self;
}
sub addr {
    my ($self, $addr) = @_;

    if (defined $addr){
        if (! grep {$addr eq $_} qw(72 73 74 75)){
            die "invalid address. " .
                "Use 0x48 (72), 0x49 (73), 0x4A (74) or 0x4B (75)\n";
        }
        $self->{addr} = $addr;
    }

    $self->{addr} = 0x48 if ! defined $self->{addr};

    return $self->{addr};
}
sub device {
    my ($self, $dev) = @_;

    if (defined $dev){
        if ($dev !~ m|/dev/i2c-\d|){
            die "invalid device name: $dev. " .
                "Must be /dev/i2c-N, where N is 0-9\n";
        }
        $self->{device} = $dev;
    }

    $self->{device} = '/dev/i2c-1' if ! defined $self->{device};

    return $self->{device};
}
sub model {
    my ($self, $model) = @_;

    if (defined $model){
        if ($model !~ /^ADS1[01]1[3458]/){
            die "invalid model name: $model. " .
                "Must be 'ADS1x1y' where x is 1 or 0, and y is 3, 4, 5 or 8\n";
        }
        $self->{model} = $model
    }

    $self->{model} = 'ADS1015' if ! defined $self->{model};

    my ($model_num) = $self->{model} =~ /(\d+)/;

    $self->_resolution($model_num);

    return $self->{model};
}

# operational methods (public)

sub bits {
    my $self = shift;

    my @bytes = $self->register;

    my $bits = ($bytes[0] << 8) | $bytes[1];

    return $bits;
}
sub register {
    my ($self, $msb, $lsb) = @_;

    # config register

    if (defined $msb){
        if (! defined $lsb){
            die "register() requires \$msb and \$lsb params\n";
        }
        if (! grep {$msb == $_} (0..255)){
            die "msg param requires an int 0..255\n";
        }
        if (! grep {$lsb == $_} (0..255)){
            die "lsb param requires an int 0..255\n";
        }

        $self->{register_data} = [$msb, $lsb];
    }

    return @{ $self->{register_data} };
}

# private methods

sub _bit_set {
    # unset and set config register bits

    my ($self, $value, $max) = @_;

    my $bits = $self->bits;

    # unset
    $bits &= ~$max;

    # set
    $bits |= $value;

    my $lsb = $bits & 0xFF;
    my $msb = $bits >> 8;

    $self->register($msb, $lsb);
}
sub _register_data {

    # for testing/validation purposes

    my $tables = {
        mux         => \%mux,
        queue       => \%queue,
        polarity    => \%polarity,
        rate        => \%rate,
        mode        => \%mode,
        gain        => \%gain,
    };

    return $tables;
}
sub _resolution {
    # decides/sets resolution to 12 or 16 bits

    my ($self, $model) = @_;

    if (defined $model){
        if ($model =~ /11\d{2}/){
            $self->{resolution} = 16;
        }
        else {
            $self->{resolution} = 12;
        }
    }
    return $self->{resolution};
}

# device methods

sub volts {
    my ($self, $channel) = @_;

    if (defined $channel){
        $self->channel($channel);
    }

    my $addr = $self->addr;
    my $dev = $self->device;
    my @write_buf = $self->register;

    return voltage_c(
        $addr, $dev, $write_buf[0], $write_buf[1], $self->_resolution
    );
}
sub raw {
    my ($self, $channel) = @_;

    if (defined $channel){
        $self->channel($channel);
    }

    my $addr = $self->addr;
    my $dev = $self->device;
    my @write_buf = $self->register;

    return raw_c($addr, $dev, $write_buf[0], $write_buf[1], $self->_resolution);
}
sub percent {
    my ($self, $channel) = @_;

    if (defined $channel){
        $self->channel($channel);
    }

    my $addr = $self->addr;
    my $dev = $self->device;
    my @write_buf = $self->register;

    my $percent = percent_c(
        $addr, $dev, $write_buf[0], $write_buf[1], $self->_resolution
    );

    $percent = 100 if $percent > 100;
    
    return sprintf("%.2f", $percent);
}

sub _vim {}

1;

__END__

=head1 NAME

RPi::ADC::ADS - Interface to ADS 1xxx series analog to digital converters (ADC)
on Raspberry Pi

=head1 SYNOPSIS

    use RPi::ADC::ADS;

    # instantiation of the object, shown with optional parameters
    # with their defaults if you don't specify them

    my $adc = RPi::ADC::ADS->new(
        model    => 'ADS1015',
        addr     => 0x48,
        device   => '/dev/i2c-1',
        channel  => 0,
        gain     => 1,
        mode     => 1,
        rate     => 0,
        polarity => 0,
        queue    => 3,
    );

    my $volts   = $adc->volts;
    my $percent = $adc->percent;
    my $int     = $adc->raw;

    # all retrieval methods allow you to specify the channel (0..3) in the call
    # instead of using the default, or the one set in new()

    my $percent = $adc->percent(3);
    ...

=head1 DESCRIPTION

Perl interface to the Texas Instruments/Adafruit ADS 1xxx series Analog to
Digital Converters (ADC) on the Raspberry Pi.

Provides access via the i2c bus to all four input channels on each ADC, while
performing correct bit-shifting between the 12-bit and 16-bit resolution on
the differing models.

=head1 PHYSICAL SETUP

List of pinout connections between the ADC and the Raspberry Pi.

    ADC     Pi
    -----------
    VDD     Vcc
    GND     Gnd
    SCL     SCL
    SDA     SDA
    ADDR    Gnd (see below for more info)
    ALRT    NC  (no connect)

Pinouts C<A0> through C<A3> on the ADC are the analog pins used to connect to
external peripherals (specified in this software as C<0> through C<3>).

The C<ADDR> pin specifies the memory address of the ADC unit. Four ADCs can be
connected to the i2c bus at any one time. By default, this software uses
address C<0x48>, which is the address when the C<ADDR> pin is connected to
C<Gnd> on the Raspberry Pi. Here are the addresses for the four Pi pins:

    Pin     Address
    ---------------
    Gnd     0x48
    VDD     0x49
    SDA     0x4A
    SCL     0x4B

=head1 OBJECT METHODS

=head2 new

Instantiates a new L<RPi::ADC::ADS> object. All parameters are optional, and are
all sent in as a single hash.

Parameters:

    model => $string

Optional. The model number of the ADC. If not specified, we use C<ADS1015>.
Models that start with C<ADS11> have 16-bit accuracy resolution, and models
that start with C<ADS10> have 12-bit resolution.

    addr => $hex

Optional. The hex location of the ADC. If the pinout in L</PHYSICAL SETUP> is
used, this will be C<0x48> (which is the default if not supplied).

    device => $string

Optional. The filesystem path to the i2c device file. Defaults to C</dev/i2c-1>

    channel => $int

Optional. See L</INPUT CHANNELS> for parameter values and details.

    gain => $int

Optional. See L</GAIN AMPLIFIER> for parameter values and details.

    mode => $int

Optional. See L</OPERATION MODE> for parameter values and details.

    rate => $int

Optional. See L</DATA RATE> for parameter values and details.

    polarity => $int

Optional. See L</COMPARATOR POLARITY> for parameter values and details.

    queue => $int

Optional. See L</COMPARATOR QUEUE> for parameter values and details.

=head2 addr

Sets/gets the ADC memory address. After object instantiation, this method
should only be used to get (ie. don't send in any parameters).

Parameters:

    $hex

Optional: A memory address in the form C<0xNN>. See L</PHYSICAL SETUP> for full
details.

=head2 device

Sets/gets the file path information for the i2c device. This shouldn't be used
as a setter after object instantiation. It defaults to C</dev/i2c-1> if not set
in the C<new()> call (or with this method thereafter).

Parameters:

    $dev

Optional: String, the full path of the i2c device in use. Defaults to
C</dev/i2c-1>.

=head2 model

Sets/gets the model of the ADC chip that we're connected to. This shouldn't be
set after object instantiation. Defaults to C<ADS1015> if not set in the
C<new()> call, or later with this method.

Parameters:

    $model

Optional: String, the model name of the ADC unit. Defaults to C<ADS1015>. Valid
values are C</ADS1[01]1[3458]/>.

=head2 channel

Sets/gets the currently registered ADC input channel within the object. Both
single-ended and differential operation mode are available.

Parameters:

    $channel

Optional: See L</INPUT CHANNELS> for the parameter values and details.

=head2 gain

Sets/gets the programmable gain amplifier.

Parameters:

    $int

Optional: See L</GAIN AMPLIFIER> for the parameter values and details.

=head2 mode

Sets/gets the conversion operation mode, either single conversion or continuous
conversion.

Parameters:

    $int

Optional: See L</OPERATION MODE> for the parameter values and details.

=head2 rate

Sets/gets the data rate.

Parameters:

    $int

Optional: See L</DATA RATE> for the parameter values and details.

=head2 polarity

Sets/gets the comparitor polarity.

Parameters:

    $int

Optional: See L</COMPARATOR POLARITY> for the parameter values and details.  

=head2 queue

Sets/gets the comparator queue configuration.

Parameters:

    $int

Optional: See L</COMPARATOR QUEUE> for the parameter values and details.  

=head1 OPERATIONAL METHODS

These methods are for core operation, but are left public as they may be of use
for those who want to tinker with the innards.

=head2 bits

Separates the 16-bit wide configuration register and returns an array
containing the Most Significant Byte as the first element, and the Least
Significant Byte as the second element.

Parameters: None

Return: Array of two elements (MSB, LSB).

=head2 register 

Sets/gets the ADC's config register. This has been left public for convenience
for those who understand the hardware very well. It really shouldn't be used
otherwise.

Parameters:
    
    $msb, $lsb

Optional: If one is sent in, both must be sent in. C<$msb> is the most
significant byte of the config register, an integer between 0-255. C<$lsb> is
the least significant byte of the config register, and must be in the same
format as the C<$msb>.

Return: Array with two elements. First element is the MSB, and the second
element is the LSB.

=head1 DATA RETRIEVAL METHODS

=head2 volts

Retrieves the voltage level of the channel.

Parameters:

    $channel

Optional: See L</INPUT CHANNELS> for parameter values and details. Specifies the
ADC input channel to read from. Setting this parameter allows you to read all
four channels without changing the default set in the object.

Return: A floating point number between C<0> and the maximum voltage output by
the Pi's GPIO pins.

=head2 percent

Retrieves the ADC channel's input value by percentage of maximum input.

Parameters: See C<$channel> in L</volts>.

=head2 raw

Retrieves the raw value of the ADC channel's input value.

Parameters: See C<$channel> in L</volts>.

=head1 C FUNCTIONS

The following C functions aren't meant to be called directly. Rather, use the
corresponding Perl object methods instead.

=head2 fetch

Fetches the raw data from the channel specified.

Implemented as:

    int
    fetch (addr, dev, wbuf1, wbuf2, res)
        int addr
        char * dev
        char * wbuf1
        char * wbuf2
        int resolution

C<wbuf1> is the most significant byte (bits 15-8) for the configuration
register, C<wbuf2> being the least significant byte (bits 7-0).

=head2 voltage_c

Fetches the ADC input and returns it as the actual voltage.

Implemented as:

    float
    voltage_c (addr, dev, wbuf1, wbuf2, res)
        int addr
        char * dev
        char * wbuf1
        char * wbuf2
        int resolution

See L</fetch> for details on the C<wbuf> arguments.

=head2 raw_c

Fetches the ADC input and returns it in its raw form.

Implemented as:

    int
    raw_c (addr, dev, wbuf1, wbuf2, res)
        int addr
        char * dev
        char * wbuf1
        char * wbuf2
        int resolution

See L</fetch> for details on the C<wbuf> arguments.

=head2 percent_c

Fetches the ADC input value as a floating point percentage between minimum and
maximum input values.

Implemented as:

    float
    percent_c (addr, dev, wbuf1, wbuf2, res)
        int addr
        char * dev
        char * wbuf1
        char * wbuf2
        int resolution

See L</fetch> for details on the C<wbuf> arguments.

=head1 TECHNICAL DATA

=head2 REGISTERS

Both the conversion and configuration registers are 16-bits wide.

The write buffer for the config register consists of an array with three 
elements. Element C<0> is the register pointer, which allows you to select the
register to use. Value C<0> for the conversion register and C<1> for the 
configuration register.

Element C<1> is a byte long, and represents the most significant bits (15-8) of
each 16-bit register, while element C<2> represents the least significant bits,
7-0.

It is advised that you don't change any of these except for the input channels
unless you know how the hardware works, and you have a good understanding of the
specific configuration register options.

=head2 CONFIG REGISTER

=head3 CONVERSATION BIT

Bit: 15

This bit should always be set to C<1> when writing. This initiates a
conversation with the ADC. When reading, this bit will read C<1> if a conversion
is currently occuring, and C<0> if the current conversion is complete.

=head3 INPUT CHANNELS

Bit: 14-12

Represents the ADC input channel, as well as either a single-ended
(difference between a single input channel and GRD) or differential mode
(difference between two input channels).

Single mode configuration:

    Param   Value   Input
    ---------------------

    0       100     A0 (default)
    1       101     A1
    2       110     A2
    3       111     A3

Differential mode configuration:

    Param   Value   Diff between
    ----------------------------

    4       000     A0 <-> A1
    5       001     A0 <-> A3
    6       010     A1 <-> A3
    7       011     A2 <-> A3


=head3 GAIN AMPLIFIER

Bit: 11-9

Represents the programmable gain amplifier. This software uses C<1> or
+/-4.096V to cover the Pi's 3.3V output.

    Param   Value   Gain
    --------------------

    0       000     +/-6.144V
    1       001     +/-4.096V (default)
    2       010     +/-2.048V
    3       011     +/-2.024V
    4       100     +/-0.512V
    5       101     +/-0.256V
    6       110     +/-0.256V
    7       111     +/-0.256V

=head3 OPERATION MODE

Bit: 8

Represents the conversion operation mode. We use the single conversion hardware
default.

    Param/Value   Mode
    ------------------

    0             continuous conversion
    1             single conversion (default)

=head3 DATA RATE

Bit: 7-5

Represent the data rate. We use 128SPS (128 Samples Per Second) by default:

    Param   Value   Rate
    --------------------

    0       000     128SPS (default)
    1       001     250SPS
    2       010     490SPS
    3       011     920SPS
    4       100     1600SPS
    5       101     2400SPS
    6       110     3300SPS
    7       111     3300SPS

=head3 COMPARATOR POLARITY

Bit: 3

Represents the comparator polarity. We use C<0> (active low) by default.

    Param/Value   Polarity
    ----------------------

    0             Active Low (default)
    1             Active High

=head3 COMPARATOR QUEUE

Bit: 1-0

Represents the comparator queue. We use C<3> (disabled) by default.

    Param   Value   Queue
    ---------------------

    0       00  Assert after one conversion
    1       01  Assert after two conversions
    2       10  Assert after four conversions
    3       11  Disable comparator (default)

=head1 READING DATA

Each channel has a conversion register (that contains the actual analog input).
This register is 16 bits wide. With that said, the most significant bit is used
to identify whether the number is positive or negative, so technically, for the
ADC11xx series ADCs, the width is actually 15 bits, and the ADC10xx units are
11 bits wide (as the resolution on these models are only 12-bit as opposed to
16-bit).

See the L<ADC's datasheet|https://cdn-shop.adafruit.com/datasheets/ads1015.pdf>
for further information.

=head1 NOTES

Bit 4 and 2 of the configuration register are currently unused.

=head1 SEE ALSO

L<WiringPi::API>, L<RPi::WiringPi>, L<RPi::DHT11>

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
