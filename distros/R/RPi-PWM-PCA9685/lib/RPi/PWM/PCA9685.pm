package RPi::PWM::PCA9685;

use strict;
use warnings;

use Carp qw(croak);
use RPi::I2C;

our $VERSION = '0.01';

use constant {
    CH_ALL           => 16,
    PWM_FULL         => 0x1000,
    PWM_MAX          => 4095,
    OSC_HZ           => 25000000,
    OSC_STAB         => 0.0005,
    PRESCALE_MIN     => 0x03,
    PRESCALE_MAX     => 0xFF,
    SWRST_MAGIC      => 0x06,
    REG_MODE1        => 0x00,
    REG_MODE2        => 0x01,
    REG_LED0_ON_L    => 0x06,
    REG_ALL_LED_ON_L => 0xFA,
    REG_PRE_SCALE    => 0xFE,
    MODE1_RESTART    => 0x80,
    MODE1_AI         => 0x20,
    MODE1_SLEEP      => 0x10,
    MODE2_INVRT      => 0x10,
    MODE2_OUTDRV     => 0x04,
};

# Public methods
sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    if (defined $args{device} && ref $args{device}){
        croak "device param must be a string, eg. '/dev/i2c-1'";
    }

    $self->{device} = defined $args{device} ? $args{device} : '/dev/i2c-1';

    if (defined $args{addr} && ($args{addr} !~ /^\d+$/ || $args{addr} < 0x03 || $args{addr} > 0x77)){
        croak "addr param must be an integer between 0x03 and 0x77";
    }

    $self->{addr} = defined $args{addr} ? $args{addr} : 0x40;

    if (defined $args{drive} && $args{drive} !~ /^(?:totem|open_drain)$/){
        croak "drive param must be 'totem' or 'open_drain'";
    }

    $self->{open_drain} = defined $args{drive} && $args{drive} eq 'open_drain' ? 1 : 0;

    $self->{osc_hz} = OSC_HZ;
    $self->{prescale} = 0x1E; # Chip default until _chip_init() reads the real one

    my $i2c = eval { RPi::I2C->new($self->{addr}, $self->{device}); };

    if (! defined $i2c){
        croak sprintf(
            "new() failed to open %s at addr 0x%02X: %s",
            $self->{device},
            $self->{addr},
            defined $@ && $@ ne '' ? $@ : 'unknown error',
        );
    }

    $self->{i2c} = $i2c;

    $self->_chip_init;

    # osc must be set before freq, as it's used in the prescaler math

    if (defined $args{osc}){
        $self->osc_freq($args{osc});
    }

    if (defined $args{freq}){
        $self->freq($args{freq});
    }

    if (defined $args{invert}){
        $self->invert($args{invert});
    }

    return $self;
}

sub all_off {
    my ($self) = @_;
    return $self->pwm(CH_ALL, 0, PWM_FULL);
}
sub close {
    my ($self) = @_;

    # Dropping the RPi::I2C object closes its file descriptor

    $self->{i2c} = undef;

    return 0;
}
sub duty {
    my ($self, $channel, $duty) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "duty() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    if (! defined $duty || $duty !~ /^\d+$/ || $duty > PWM_MAX){
        croak "duty() requires the \$duty param, an integer between 0-4095";
    }

    return $self->full_off($channel) if $duty == 0;
    return $self->full_on($channel) if $duty == PWM_MAX;

    return $self->pwm($channel, 0, $duty);
}
sub duty_pct {
    my ($self, $channel, $pct) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "duty_pct() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    if (! defined $pct || $pct !~ /^\d+(?:\.\d+)?$/ || $pct > 100){
        croak "duty_pct() requires the \$pct param, a number between 0-100";
    }

    return $self->duty($channel, int($pct / 100 * PWM_MAX + 0.5));
}
sub freq {
    my ($self, $freq) = @_;

    if (defined $freq){
        if ($freq !~ /^\d+(?:\.\d+)?$/ || $freq == 0){
            croak "freq() \$freq param must be a number between 24-1526";
        }

        # prescale = round(osc / (4096 * freq)) - 1, clamped to chip limits

        my $divider = $self->{osc_hz} / (4096 * $freq);
        $divider = 256 if $divider > 256;
        $divider = 1 if $divider < 1;

        my $prescale = int($divider + 0.5) - 1;
        $prescale = PRESCALE_MIN if $prescale < PRESCALE_MIN;
        $prescale = PRESCALE_MAX if $prescale > PRESCALE_MAX;

        # The prescaler is only writable while the oscillator is stopped

        my $mode1 = ($self->_reg_read(REG_MODE1) & ~MODE1_RESTART) & 0xFF;
        $self->_reg_write(REG_MODE1, ($mode1 | MODE1_SLEEP) & 0xFF);
        $self->_reg_write(REG_PRE_SCALE, $prescale);
        $self->{prescale} = $prescale;

        $self->wake;
    }

    $self->{prescale} = $self->_reg_read(REG_PRE_SCALE);

    return $self->{osc_hz} / (4096 * ($self->{prescale} + 1));
}
sub full_off {
    my ($self, $channel) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "full_off() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    return $self->pwm($channel, 0, PWM_FULL);
}
sub full_on {
    my ($self, $channel) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "full_on() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    return $self->pwm($channel, PWM_FULL, 0);
}
sub invert {
    my ($self, $invert) = @_;

    $invert = 1 if ! defined $invert;

    my $mode2 = $self->_reg_read(REG_MODE2);

    if ($invert){
        $mode2 |= MODE2_INVRT;
    }
    else {
        $mode2 = ($mode2 & ~MODE2_INVRT) & 0xFF;
    }

    $self->_reg_write(REG_MODE2, $mode2);

    return 0;
}
sub osc_freq {
    my ($self, $hz) = @_;

    if (defined $hz){
        if ($hz !~ /^\d+(?:\.\d+)?$/ || $hz == 0){
            croak "osc_freq() \$hz param must be a positive number";
        }
        $self->{osc_hz} = $hz;
    }

    return $self->{osc_hz};
}
sub pwm {
    my ($self, $channel, $on, $off) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "pwm() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    if (! defined $on || $on !~ /^\d+$/ || $on > 0x1FFF){
        croak "pwm() requires the \$on param, an integer between 0-4095 (bit 12 = full on)";
    }

    if (! defined $off || $off !~ /^\d+$/ || $off > 0x1FFF){
        croak "pwm() requires the \$off param, an integer between 0-4095 (bit 12 = full off)";
    }

    # One block write is a single I2C transaction; the chip's register
    # auto-increment walks ON_L, ON_H, OFF_L, OFF_H, and the output
    # updates atomically at the STOP

    my @bytes = (
        $on & 0xFF,
        ($on >> 8) & 0x1F,
        $off & 0xFF,
        ($off >> 8) & 0x1F,
    );

    my $rc = $self->_i2c->write_block(\@bytes, $self->_led_reg($channel));

    if (defined $rc && $rc == -1){
        croak "pwm($channel, $on, $off) i2c write failed: $!";
    }

    return 0;
}
sub pwm_read {
    my ($self, $channel) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > 15){
        croak "pwm_read() requires the \$channel param, an integer between 0-15";
    }

    my @bytes = $self->_i2c->read_block(4, $self->_led_reg($channel));

    my $on  = $bytes[0] | (($bytes[1] & 0x1F) << 8);
    my $off = $bytes[2] | (($bytes[3] & 0x1F) << 8);

    return ($on, $off);
}
sub register {
    my ($self, $reg, $value) = @_;

    if (! defined $reg || $reg !~ /^\d+$/ || $reg > 255){
        croak "register() requires the \$reg param, an integer between 0-255";
    }

    if (defined $value){
        if ($value !~ /^\d+$/ || $value > 255){
            croak "register() \$value param must be an integer between 0-255";
        }
        $self->_reg_write($reg, $value);
        return $value;
    }

    return $self->_reg_read($reg);
}
sub reset {
    my ($self) = @_;

    # SWRST: one byte, 0x06, to the I2C general-call address 0x00.
    # Resets EVERY PCA9685 on the bus to its power-on defaults

    my $general_call = eval { RPi::I2C->new(0, $self->{device}); };

    if (! defined $general_call){
        croak "reset() failed to open the general-call address: $@";
    }

    my $rc = $general_call->write(SWRST_MAGIC);

    if (defined $rc && $rc == -1){
        croak "reset() i2c write failed: $!";
    }

    select(undef, undef, undef, OSC_STAB);

    $self->_chip_init;

    return 0;
}
sub servo_us {
    my ($self, $channel, $us) = @_;

    if (! defined $channel || $channel !~ /^\d+$/ || $channel > CH_ALL){
        croak "servo_us() requires the \$channel param, an integer between 0-15, or 16 for all";
    }

    if (! defined $us || $us !~ /^\d+(?:\.\d+)?$/){
        croak "servo_us() requires the \$us param, the pulse width in microseconds";
    }

    # No pulses at all releases the servo

    return $self->full_off($channel) if $us == 0;

    # One counter tick lasts (prescale + 1) / osc_hz seconds. Uses the
    # prescale cached by new()/freq(); if the prescaler is changed
    # behind the module's back via register(), call freq() to resync

    my $ticks = $us * $self->{osc_hz} / (($self->{prescale} + 1) * 1e6) + 0.5;

    if ($ticks >= 4096){
        croak "servo_us() pulse width of $us us is wider than the PWM period";
    }

    return $self->full_off($channel) if $ticks < 1;

    return $self->pwm($channel, 0, int($ticks));
}
sub sink_mode {
    my ($self) = @_;

    # Current-sinking wiring (V+ -> LED -> resistor -> pin): open-drain so
    # an off pin floats instead of driving to VDD (safe when V+ is above
    # the chip's supply), plus inverted logic so duty maps to brightness

    $self->{open_drain} = 1;

    $self->_outdrv(1);
    $self->invert(1);

    return 0;
}
sub sleep {
    my ($self) = @_;

    my $mode1 = ($self->_reg_read(REG_MODE1) & ~MODE1_RESTART) & 0xFF;

    $self->_reg_write(REG_MODE1, ($mode1 | MODE1_SLEEP) & 0xFF);

    return 0;
}
sub wake {
    my ($self) = @_;

    my $mode1 = $self->_reg_read(REG_MODE1);

    # RESTART reads 1 if the chip was put to sleep while PWM was
    # running. Writing 1 to it is a command, so it gets masked out of
    # the modify-write, and only written deliberately once the
    # oscillator is back up

    my $restart = $mode1 & MODE1_RESTART;

    $mode1 = ($mode1 & ~(MODE1_RESTART | MODE1_SLEEP)) & 0xFF;

    $self->_reg_write(REG_MODE1, $mode1);

    select(undef, undef, undef, OSC_STAB);

    if ($restart){
        $self->_reg_write(REG_MODE1, $mode1 | MODE1_RESTART);
    }

    return 0;
}

sub DESTROY {
    my ($self) = @_;
    $self->close;
}

# Private methods

sub _chip_init {
    my ($self) = @_;

    # The initial read doubles as a presence check; a missing chip
    # won't ACK, and the read comes back -1

    my $mode1 = $self->_i2c->read_byte(REG_MODE1);

    if (! defined $mode1 || $mode1 == -1){
        croak sprintf(
            "no PCA9685 found at addr 0x%02X on %s",
            $self->{addr},
            $self->{device},
        );
    }

    # Enable register auto-increment; pwm() and pwm_read() rely on it

    $mode1 = (($mode1 & ~MODE1_RESTART) & 0xFF) | MODE1_AI;

    $self->_reg_write(REG_MODE1, $mode1);

    # Output drive type: totem-pole by default, or open-drain for
    # current-sinking loads. Reapplied here so it survives reset()

    $self->_outdrv($self->{open_drain});

    $self->{prescale} = $self->_reg_read(REG_PRE_SCALE);

    $self->wake;

    return 0;
}
sub _i2c {
    my ($self) = @_;

    if (! defined $self->{i2c}){
        croak "the device has been closed";
    }

    return $self->{i2c};
}
sub _led_reg {
    my ($self, $channel) = @_;

    return REG_ALL_LED_ON_L if $channel == CH_ALL;
    return REG_LED0_ON_L + 4 * $channel;
}
sub _outdrv {
    my ($self, $open_drain) = @_;

    # Read-modify-write so the INVRT bit is left untouched. OUTDRV set is
    # totem-pole (driven high and low); cleared is open-drain (sink only)

    my $mode2 = $self->_reg_read(REG_MODE2);

    if ($open_drain){
        $mode2 = ($mode2 & ~MODE2_OUTDRV) & 0xFF;
    }
    else {
        $mode2 |= MODE2_OUTDRV;
    }

    $self->_reg_write(REG_MODE2, $mode2);

    return 0;
}
sub _reg_read {
    my ($self, $reg) = @_;

    my $value = $self->_i2c->read_byte($reg);

    if (! defined $value || $value == -1){
        croak sprintf("register 0x%02X read failed: %s", $reg, $!);
    }

    return $value;
}
sub _reg_write {
    my ($self, $reg, $value) = @_;

    my $rc = $self->_i2c->write_byte($value, $reg);

    if (defined $rc && $rc == -1){
        croak sprintf("register 0x%02X write failed: %s", $reg, $!);
    }

    return 0;
}

sub _vim{}; # Fold placeholder

1;
__END__

=head1 NAME

RPi::PWM::PCA9685 - Interface to the NXP PCA9685 16-channel, 12-bit PWM/servo
controller over the I2C bus

=for html
<a href="https://github.com/stevieb9/rpi-pwm-pca9685/actions"><img src="https://github.com/stevieb9/rpi-pwm-pca9685/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/rpi-pwm-pca9685?branch=main'><img src='https://coveralls.io/repos/stevieb9/rpi-pwm-pca9685/badge.svg?branch=main&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

    use RPi::PWM::PCA9685;

    # LEDs / general PWM

    my $pca = RPi::PWM::PCA9685->new(freq => 1000);

    $pca->duty(0, 2048);        # channel 0 at 50%
    $pca->duty_pct(1, 12.5);    # channel 1 at 12.5%
    $pca->full_on(2);           # channel 2 hard on, no PWM

    $pca->all_off;

    # Powering an LED, two ways (see DRIVING LEDS)

    # Sourced from the pin:  pin -> resistor -> LED -> GND (totem-pole default)
    $pca->duty_pct(0, 75);

    # Sunk from a higher rail: V+ -> LED -> resistor -> pin (eg. 5V LED, 3.3V chip)
    $pca->sink_mode;            # Open-drain + inverted logic
    $pca->duty_pct(0, 75);

    # Servos (the whole chip must run at 50 Hz)

    my $servo = RPi::PWM::PCA9685->new(freq => 50);

    $servo->servo_us(0, 1500);  # centre
    $servo->servo_us(0, 2000);  # one end
    $servo->servo_us(0, 0);     # stop the pulses; servo goes limp

=head1 DESCRIPTION

Interface to the NXP PCA9685 16-channel, 12-bit PWM controller over the I2C
bus. This is the chip found on virtually every "16-channel servo driver" or
"16-channel PWM/LED driver" breakout board.

Each of the 16 channels has 4096 duty cycle steps, and the chip generates all
PWM in hardware, so the Pi spends zero CPU keeping the signals alive. All 16
channels share a single PWM frequency (24-1526 Hz); duty cycle and phase are
per-channel.

This distribution is pure Perl. The I2C transport is provided by L<RPi::I2C>,
which carries the compiled layer and talks to the chip through the kernel's
C</dev/i2c-N> interface. Channel updates go out as a single atomic I2C
transaction, so an output never glitches through a half-written state.

The chip powers up asleep with its oscillator stopped; C<new()> wakes it and
enables register auto-increment automatically.

=head1 METHODS

=head2 new

Instantiates a new L<RPi::PWM::PCA9685> object, opens the I2C bus, verifies
the chip responds, and wakes it up.

I<Parameters>:

All parameters are sent in within a single hash, and all are optional.

    device => $str

I<Optional, String>: The I2C bus device. Defaults to C</dev/i2c-1>.

    addr => $int

I<Optional, Integer>: The 7-bit I2C address of the chip, as set by its
C<A5>-C<A0> address pins. Defaults to C<0x40> (all address pins low). See
L</I2C ADDRESSING>.

    freq => $num

I<Optional, Number>: The PWM frequency in Hz for all 16 channels, between
24-1526. Use C<50> for servos, C<1000> is a good choice for LEDs. If not
supplied, the chip keeps its current prescaler (200 Hz from power-on).

    osc => $num

I<Optional, Number>: The true speed in Hz of the chip's internal oscillator,
if you've measured it. See L</osc_freq>.

    invert => $bool

I<Optional, Bool>: Invert the output logic of all channels. See L</invert>.

    drive => $str

I<Optional, String>: The output drive type, C<'totem'> (the default) or
C<'open_drain'>. Totem-pole drives each pin both high and low, and suits
LEDs powered from the chip's own pins and servo signal lines. Open-drain
only sinks (an off pin floats), which is what you want when sinking current
from a supply above the chip's VDD - see L</sink_mode> and L</DRIVING LEDS>.
The setting is reapplied across L</reset>.

I<Returns>: The L<RPi::PWM::PCA9685> object. Croaks if the bus can't be
opened or the chip doesn't respond.

=head2 freq

Sets and/or gets the PWM frequency shared by all 16 channels.

Changing frequency briefly stops the chip's oscillator (the prescaler is only
writable during sleep), so all outputs pause for about a millisecond. Set it
once, up front.

I<Parameters>:

    $freq

I<Optional, Number>: The desired frequency in Hz, clamped by the chip to
24-1526.

I<Returns>: The B<actual> frequency in Hz. The prescaler is an 8-bit divider,
so what you get is quantised; ask for 1000 and you'll receive C<1017.25>.

=head2 duty

Sets a channel's duty cycle.

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all channels at
once.

    $duty

I<Mandatory, Integer>: C<0>-C<4095>. C<0> is hard off and C<4095> is hard on
(these use the chip's full-off/full-on flags); anything between is
C<$duty/4096> of each PWM cycle.

I<Returns>: C<0> upon success.

=head2 duty_pct

Same as L</duty>, but takes a percentage.

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all.

    $pct

I<Mandatory, Number>: Duty cycle as a percentage, C<0>-C<100>. Decimals are
fine.

I<Returns>: C<0> upon success.

=head2 servo_us

Sets a channel's pulse width in microseconds - the native language of hobby
servos. The chip should be running at 50 Hz (C<< freq => 50 >> in C<new()>).

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all.

    $us

I<Mandatory, Number>: The pulse width in microseconds. Nominal servo range is
C<1000>-C<2000> with C<1500> as centre; many servos accept C<500>-C<2500> for
their full mechanical throw. Sneak up on the limits - a servo buzzing at an
end stop is cooking itself. C<0> stops the pulses entirely, releasing the
servo. Croaks if the pulse would be wider than the PWM period.

I<Returns>: C<0> upon success.

=head2 pwm

Raw access to a channel's ON and OFF tick registers, for phase control.

Within each 4096-tick PWM cycle, the output switches high when the counter
hits C<$on>, and low when it hits C<$off>. Duty is the distance between them;
giving each channel a different C<$on> staggers the switching edges so heavy
loads don't all slam the supply at the same instant.

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all.

    $on

I<Mandatory, Integer>: Tick the output goes high, C<0>-C<4095>. Setting bit
12 (C<0x1000>) forces the channel full on.

    $off

I<Mandatory, Integer>: Tick the output goes low, C<0>-C<4095>. Setting bit 12
(C<0x1000>) forces the channel full off, which wins over everything else.

I<Returns>: C<0> upon success.

=head2 pwm_read

Reads back a channel's ON and OFF tick registers.

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>.

I<Returns>: A two element list, C<($on, $off)>.

=head2 full_on

Puts a channel hard on - solid high, no PWM.

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all.

I<Returns>: C<0> upon success.

=head2 full_off

Puts a channel hard off. For a servo, this stops its pulses (releasing it).

I<Parameters>:

    $channel

I<Mandatory, Integer>: The channel, C<0>-C<15>, or C<16> for all.

I<Returns>: C<0> upon success.

=head2 all_off

Puts every channel hard off in a single call.

Takes no parameters. I<Returns>: C<0> upon success.

=head2 invert

Inverts the output logic of all 16 channels.

Useful when LEDs are wired to be current-sunk (V+ -> LED -> resistor -> pin),
where the LED is lit while the pin is low. Inverting makes duty cycle mean
brightness again. For the full sink-wiring setup, see L</sink_mode>.

I<Parameters>:

    $invert

I<Optional, Bool>: True to invert, false for normal logic. Defaults to C<1>.

I<Returns>: C<0> upon success.

=head2 sink_mode

Configures the chip for current-sinking LED wiring in one call: it switches
the outputs to open-drain and inverts the output logic. Equivalent to
C<< new(drive => 'open_drain') >> followed by C<< invert(1) >>.

Use this when LEDs (or other loads) are wired V+ -> load -> resistor -> pin
and powered from a supply above the chip's VDD - for example a 3.3 V chip
sinking 5 V LEDs. Open-drain lets an off pin float to the external rail
(within the pins' 5.5 V tolerance) instead of driving it down to VDD, and
the inversion keeps higher duty meaning brighter. See L</DRIVING LEDS>.

The open-drain setting is remembered and reapplied across L</reset>.

Takes no parameters. I<Returns>: C<0> upon success.

=head2 osc_freq

Sets and/or gets the oscillator frequency the prescaler and pulse width math
assumes. Defaults to the nominal C<25000000> (25 MHz).

The chip's internal oscillator is only accurate to a few percent, which skews
both the PWM frequency and servo pulse widths. If you've measured your
board's true speed (scope an output, or trim until a known pulse width
measures correctly), set it here - subsequent L</freq> and L</servo_us> calls
self-correct. This only changes the math on the Pi; nothing is written to the
chip.

I<Parameters>:

    $hz

I<Optional, Number>: The true oscillator speed in Hz.

I<Returns>: The currently assumed oscillator speed in Hz.

=head2 sleep

Puts the chip into low-power sleep - the oscillator stops and all outputs
freeze. Register contents survive.

Takes no parameters. I<Returns>: C<0> upon success.

=head2 wake

Wakes the chip from sleep, and restarts any PWM that was running when it went
down.

Takes no parameters. I<Returns>: C<0> upon success.

=head2 reset

Software-resets the chip to its power-on defaults, then re-initialises it
(auto-increment on, awake).

B<WARNING>: this is the I2C "general call" reset - it resets B<every>
PCA9685 on the bus, not just this one.

Takes no parameters. I<Returns>: C<0> upon success.

=head2 register

Reads or writes any register on the chip directly, for anything this API
doesn't wrap. See the datasheet, or the C<TECHNICAL INFORMATION> section
below for the register map.

I<Parameters>:

    $reg

I<Mandatory, Integer>: The register address, C<0>-C<255>.

    $value

I<Optional, Integer>: A byte to write, C<0>-C<255>. If omitted, the register
is read instead.

I<Returns>: The byte read, or the byte written.

=head2 close

Closes the I2C connection and invalidates the object. Called automatically
on C<DESTROY>. The chip's outputs keep running - call L</all_off> first if
you want everything off.

Takes no parameters. I<Returns>: C<0>.

=head1 TECHNICAL INFORMATION

=head2 DEVICE SPECIFICS

    - 16 outputs, 12-bit (4096 step) duty resolution each
    - One shared PWM frequency, 24-1526 Hz
    - Internal 25 MHz oscillator; no crystal required
    - Powers up asleep; new() handles the wake-up
    - Runs at 2.3-5.5V; the Pi's 3.3v is fine
    - Each output sinks up to 25 mA, sources up to 10 mA
    - The OE pin (active low) is a hardware master output-enable

Wiring to the Pi: VCC to 3.3v, SDA to GPIO 2 (pin 3), SCL to GPIO 3 (pin 5),
GND to ground. If the board has a V+ LED/servo supply input, feed it from an
external 5v supply, not the Pi. Verify the chip answers with
C<i2cdetect -y 1> - you'll see the chip at C<0x40> and its all-call alias at
C<0x70>.

=head2 PWM OPERATION

A free running counter ticks 0-4095 repeatedly; one lap is one PWM cycle.
Each channel holds two numbers: the output goes high when the counter hits
ON, low when it hits OFF. Duty cycle is C<(OFF - ON) / 4096>, and where the
pulse sits within the cycle (the phase) is up to you via L</pwm>.

The PWM frequency for all channels is set by an 8-bit prescaler dividing the
oscillator:

    freq     = 25MHz / (4096 * (prescale + 1))
    prescale = round(25MHz / (4096 * freq)) - 1

Because the prescaler is quantised, the actual frequency usually differs from
the request - L</freq> returns what you really got.

=head2 DRIVING LEDS

There are two ways to wire an LED to a channel, and they want different
output drive types.

B<Sourcing> - the pin supplies the current:

    pin -> resistor -> LED anode -> LED cathode -> GND

The pin drives high to light the LED. This needs B<totem-pole> outputs (the
default), and is limited to the ~10 mA a pin can source. Good for indicator
LEDs powered from the chip itself.

B<Sinking> - an external supply drives the LED, the pin is the return:

    V+ -> LED anode -> LED cathode -> resistor -> pin

The pin sinks up to 25 mA to light the LED, so it handles brighter LEDs, and
crucially the LED can run from a rail higher than the chip's VDD. The outputs
are 5.5 V tolerant regardless of VDD, so a chip powered at the Pi's 3.3 V can
sink LEDs from a 5 V rail (up to 5.5 V) directly.

This B<must> use B<open-drain> outputs. In totem-pole an off pin is driven to
VDD, which a higher V+ would back-feed through the LED into the chip's supply;
open-drain lets the off pin float to V+ instead. Sinking also inverts the
logic sense (the pin is low to light the LED), so the PWM values want
inverting to make duty mean brightness.

L</sink_mode> sets both at once:

    my $pca = RPi::PWM::PCA9685->new(freq => 1000);
    $pca->sink_mode;              # Open-drain + inverted, for V+ -> LED -> pin
    $pca->duty_pct(0, 75);        # 75% brightness

Requirements for the sinking setup:

    - Keep V+ at or below 5.5 V (the pins' absolute tolerance)
    - Tie the V+ supply's ground to the chip's VSS (shared return)
    - Size the resistor for <= 25 mA per channel, and mind the package total
      across all lit channels

For loads beyond 25 mA or above 5.5 V, drive an external transistor from the
pin instead. Open-drain plus L</invert> also suits an external N-type driver;
totem-pole plus non-inverted suits a P-type - see the datasheet's section 7.7.

=head2 SERVO OPERATION

Servos ignore duty cycle; they read the width of the pulse arriving each
20 ms (50 Hz) frame. Roughly 1000 us is one end of travel, 1500 us centre,
2000 us the other end. At 50 Hz, one counter tick is ~4.9 us of pulse width,
about 200 positions across a standard servo's range.

Real-world limits vary per servo, and the chip's oscillator tolerance skews
pulse widths a percent or three - calibrate with L</osc_freq> if you need
repeatable angles.

=head2 REGISTER MAP

    0x00        MODE1        Power/clock/addressing switches
    0x01        MODE2        Output pin behaviour (invert, drive type)
    0x02-0x05   SUBADR/ALLCALL Alternate I2C addresses
    0x06-0x45   LEDn ON/OFF  4 bytes per channel, starting at 0x06 + 4 * ch
    0xFA-0xFD   ALL_LED      Write every channel at once
    0xFE        PRE_SCALE    PWM frequency divider (writable only in sleep)
    0xFF        TESTMODE     Leave it alone

=head2 ON THE WIRE

This is what the registers above look like on the bus as the data is
clocked in. Time flows left to right, one box per byte, bits go out
MSB-first, and every 9th clock is an ACK slot:

    S = START    Sr = Repeated START    P = STOP
    A = ACK (receiver pulls SDA low)    N = NACK (master, "no more bytes")

Every transaction opens the same way: SDA falls while SCL is still high
(that's the START), then the master (the Pi) clocks out the chip address.
SDA may only change while SCL is low; the chip samples each bit while SCL
is high. Here's the first byte of every write this module does - address
C<0x40> shifted left plus the R/W bit, i.e. C<0x80>:

          Idle  START   1     0     0     0     0     0     0     0    ACK
    SDA   ------\_____/-----\_______________________________________________
    SCL   -----------\_/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\_

On the ACK clock the master releases SDA and the chip holds it low (the
line doesn't visibly move here since bit 0 was already 0 - only the
driver changes). SCL just keeps running, and the next byte follows the
same 8-bits-plus-ACK shape until the STOP.

A plain register write - the byte after the address is always the
register number, which is how the wire indexes into the register map.
This is the frame L</wake> sends at the end of a bare C<new()>, identical
to C<< $pca->register(0x00, 0x21) >>:

    +---+-----------+---+-----------+---+-----------+---+---+
    | S | 1000000 0 | A | 0000 0000 | A | 0010 0001 | A | P |
    +---+-----------+---+-----------+---+-----------+---+---+
          Chip addr       Register        New value
          0x40 + W=0      0x00 (MODE1)    0x21 (AI|ALLCALL)

A channel update: C<< $servo->servo_us(0, 1500) >> at 50 Hz works out to
307 ticks, so it becomes C<pwm(0, 0, 307)> - four bytes at C<LED0_ON_L>
in a single transaction. Because C<new()> set MODE1's auto-increment
bit, the chip bumps its register pointer after each data byte:

    +---+------+---+------+---+------+---+------+---+------+---+------+---+---+
    | S | 0x80 | A | 0x06 | A | 0x00 | A | 0x00 | A | 0x33 | A | 0x01 | A | P |
    +---+------+---+------+---+------+---+------+---+------+---+------+---+---+
         addr+W     Reg        Lands in   Lands in   Lands in   Lands in
                    pointer    0x06       0x07       0x08       0x09
                               LED0_ON_L  LED0_ON_H  LED0_OFF_L LED0_OFF_H

The outputs don't take the new values byte-by-byte - they latch at the
STOP, which is what makes channel updates atomic. The 12-bit OFF value
of 307 (C<0x133>) is split across the L/H register pair; the top three
bits of the H byte are don't-cares:

    LED0_OFF_L (0x08) = 0x33               LED0_OFF_H (0x09) = 0x01
    +---+---+---+---+---+---+---+---+      +---+---+---+---+---+---+---+---+
    | 0 | 0 | 1 | 1 | 0 | 0 | 1 | 1 |      | - | - | - | F | 0 | 0 | 0 | 1 |
    +---+---+---+---+---+---+---+---+      +---+---+---+---+---+---+---+---+
               OFF[7:0]                                  ^    OFF[11:8]
                                                         |
                                            The 0x1000 "full off" flag
                                            (clear in this frame)

Reading a register back is a write of just the register pointer, then a
repeated START with the R bit set. Direction flips mid-transaction:
during the data byte the I<chip> drives SDA and the master only supplies
clocks. C<< $pca->register(0xFE) >> after C<< freq => 50 >>:

    +---+------+---+------+---+----+------+---+------+---+---+
    | S | 0x80 | A | 0xFE | A | Sr | 0x81 | A | 0x79 | N | P |
    +---+------+---+------+---+----+------+---+------+---+---+
         addr+W     PRE_SCALE       addr+R     Chip      Master NACKs the
                    pointer         (R bit=1)  drives    last byte, then STOPs

L</pwm_read> is the same shape with four data bytes - the master ACKs
the first three and NACKs the fourth.

The general call reset is the shortest frame the module ever produces:
L</reset> sends the SWRST magic byte to 7-bit address C<0x00>, and every
PCA9685 on the bus ACKs it and resets:

    +---+-----------+---+-----------+---+---+
    | S | 0000000 0 | A | 0000 0110 | A | P |
    +---+-----------+---+-----------+---+---+
         General call     SWRST magic
         addr 0x00        0x06

That's every wire shape the module generates: single-byte write,
auto-increment block write, pointer-then-read, and the general call.

=head2 I2C ADDRESSING

The chip's 7-bit address is a fixed high bit followed by the six hardware
address pins, C<A5> down to C<A0>:

    1  A5 A4 A3 A2 A1 A0         The 7-bit address
    |  32 16  8  4  2  1         Each pin's weight when strapped high
    |
    Fixed - the 0x40 every address starts from

Each address pin B<must> be tied to a rail - GND for low, VCC for high.
The chip has no internal pull resistors on these pins, so one left
floating reads an undefined level, and the chip can answer at an address
you didn't intend - or not at all. Breakout boards typically strap all
six low and provide solder pads to bridge individual pins high.

All pins grounded gives the default C<0x40>, which is what C<new()>
assumes when no C<addr> is passed. Pulling a few pins high simply adds
their weights:

    A5 A4 A3 A2 A1 A0      Address
    -----------------      -------
     L  L  L  L  L  L       0x40      The default - all pins to GND
     L  L  L  L  L  H       0x41
     L  L  L  L  H  L       0x42
     L  L  L  H  L  H       0x45
     H  L  L  L  L  L       0x60
     H  H  L  H  L  H       0x75

Match the straps with the C<addr> param:

    my $pca = RPi::PWM::PCA9685->new(addr => 0x45);

Two straps to avoid: C<110000> (C<0x70>) collides with the all-call
address every PCA9685 answers by default (see L</MULTIPLE DEVICES>), and
the C<111xxx> combinations land in I2C-reserved space (C<0x78>-C<0x7F>)
that C<new()> refuses. The strapped value is what leads every transaction
on the bus, shifted left with the R/W bit appended - see L</ON THE WIRE>.

=head2 MULTIPLE DEVICES

The chip's 7-bit address is C<0x40> plus whatever is strapped on its six
address pins, so up to 62 chips can share the bus. Since all 16 channels of
one chip share a frequency, running servos (50 Hz) alongside flicker-free
LEDs (1 kHz) means using two chips:

    my $leds   = RPi::PWM::PCA9685->new(addr => 0x40, freq => 1000);
    my $servos = RPi::PWM::PCA9685->new(addr => 0x41, freq => 50);

Note that every PCA9685 also answers the all-call address C<0x70> by
default, and L</reset> resets all of them at once.

=head2 DATASHEET

The NXP PCA9685 datasheet (Rev. 4) is distributed with this software as
F<docs/datasheet/PCA9685.pdf>. It covers the register map, the PWM timing,
and the I2C framing this module drives.

=head1 SEE ALSO

L<RPi::I2C>, which provides the I2C transport for this distribution.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
