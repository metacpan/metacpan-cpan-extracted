#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use RPi::PWM::PCA9685;

# Swap the RPi::I2C transport for an in-memory register file, so the
# chip logic (prescaler math, register sequencing, servo conversion)
# gets exercised with no hardware attached

plan tests => 20;

{
    no warnings 'redefine';
    *RPi::I2C::new = sub {
        my (undef, @args) = @_;
        return MockI2C->new(@args);
    };
}

my $pca = RPi::PWM::PCA9685->new;

isa_ok $pca, 'RPi::PWM::PCA9685';

# new() wakes the chip (SLEEP off) and enables auto-increment; the
# mock powers up as the real chip does, MODE1 = 0x11

is MockI2C->peek(0x00), 0x21, "new() clears SLEEP and sets AI in MODE1";

my $freq = $pca->freq(50);

is MockI2C->peek(0xFE), 121, "freq(50) writes prescale 121 (datasheet math)";
ok $freq > 50 && $freq < 50.1, "freq() returns the actual quantised frequency (~50.03)";

$pca->servo_us(0, 1500);

is MockI2C->peek(0x08), 51, "servo_us(1500) at 50 Hz sets LED0_OFF_L to 51 (307 ticks)";
is MockI2C->peek(0x09), 1, "...and LED0_OFF_H to 1";

$pca->duty(3, 2048);

is MockI2C->peek(0x15), 0x08, "duty(2048) sets LED3_OFF_H to 0x08 (off tick 2048)";

$pca->duty(3, 4095);

is MockI2C->peek(0x13), 0x10, "duty(4095) uses the full-on flag in LED3_ON_H";

$pca->duty(3, 0);

is MockI2C->peek(0x15), 0x10, "duty(0) uses the full-off flag in LED3_OFF_H";
is MockI2C->peek(0x13), 0x00, "...and clears the on registers";

$pca->all_off;

is MockI2C->peek(0xFD), 0x10, "all_off() sets the full-off flag in ALL_LED_OFF_H";

$pca->pwm(3, 5, 1234);

is_deeply [$pca->pwm_read(3)], [5, 1234], "pwm_read() returns what pwm() wrote";

$pca->invert;

is MockI2C->peek(0x01), 0x14, "invert() sets INVRT in MODE2";

$pca->invert(0);

is MockI2C->peek(0x01), 0x04, "invert(0) clears INVRT";

$pca->sleep;

ok MockI2C->peek(0x00) & 0x10, "sleep() sets the SLEEP bit";

$pca->wake;

ok ! (MockI2C->peek(0x00) & 0x10), "wake() clears the SLEEP bit";

eval { $pca->servo_us(0, 25000); };
like $@, qr/wider than the PWM period/, "servo_us() croaks on a pulse wider than the period";

$pca->osc_freq(26000000);
$pca->freq(50);

is MockI2C->peek(0xFE), 126, "osc_freq() calibration changes the prescaler math";

$pca->reset;

is $MockI2C::general_call_byte, 0x06, "reset() sends SWRST to the general-call address";

# Note: the lexical here isn't just tidiness. Once the line above has
# mentioned the MockI2C package, "ok MockI2C->peek(...)" parses as the
# indirect method call MockI2C->ok

my $mode1 = MockI2C->peek(0x00);
ok $mode1 & 0x20, "reset() re-initialises the chip (AI back on)";

# The in-memory chip: a shared register file, powered up with the
# PCA9685's real defaults (MODE1 asleep, MODE2 totem-pole, 200 Hz)

package MockI2C;

my %regs;
our $general_call_byte;

sub new {
    my ($class, $addr, $device) = @_;

    if (! %regs){
        %regs = (0x00 => 0x11, 0x01 => 0x04, 0xFE => 0x1E);
    }

    return bless { addr => $addr, device => $device }, $class;
}
sub peek {
    my (undef, $reg) = @_;
    return defined $regs{$reg} ? $regs{$reg} : 0;
}
sub read_block {
    my ($self, $num_bytes, $reg) = @_;
    return map { defined $regs{$reg + $_} ? $regs{$reg + $_} : 0 } 0 .. $num_bytes - 1;
}
sub read_byte {
    my ($self, $reg) = @_;
    return defined $regs{$reg} ? $regs{$reg} : 0;
}
sub write {
    my ($self, $byte) = @_;
    $general_call_byte = $byte;
    return 0;
}
sub write_block {
    my ($self, $values, $reg) = @_;
    my $i = 0;
    $regs{$reg + $i++} = $_ for @{$values};
    return 0;
}
sub write_byte {
    my ($self, $value, $reg) = @_;
    $regs{$reg} = $value;
    return 0;
}
