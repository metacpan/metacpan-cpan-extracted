package RPiTest;

# NOTE: This test suite is serial-only - do NOT run it with prove's -j
# parallelism. Every test file shares the same physical pins (GPIO 18 alone
# is driven by a dozen files, 12/26 by several) and the same shared-memory
# segment (shm_key 'rpit'), and t/110-114 assert absolute object/pin counts.
# Parallel runs corrupt the counts and fight over the hardware.

use warnings;
use strict;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    rpi_legal_object_count
    rpi_legal_pin_count
    rpi_sudo_check
    rpi_multi_check
    rpi_i2c_check
    rpi_pwm_adc_window
    rpi_running_test
    rpi_oled_available
    rpi_oled_unavailable
    rpi_check_pin_status
    rpi_verify_pin_status
    rpi_default_pin_config
    rpi_board_tag
    rpi_serial_device
    rpi_reset
);

use RPi::WiringPi;
use Carp qw(croak);
use Test::More;
use WiringPi::API qw(:perl);

# validate that tests can run

if (! $ENV{RPI_BOARD} && ! $ENV{SUDO_USER}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board";
}

# RPI_OBJECT_COUNT / RPI_PIN_COUNT are optional baseline overrides, not a run
# gate. RPI_BOARD above already decides whether we're allowed to run; the count
# helpers default to 0 (a clean shared segment) when these are unset, so there's
# no need to force the user to define them just to get the suite to run.

# relevant testing variables

my $oled_lock = '/dev/shm/oled_unavailable.rpi-wiringpi';

# fetch the number of pre-existing objects and pins in use

sub rpi_legal_object_count {
    # Pre-existing objects registered in the shared 'rpit' segment by external,
    # long-running processes (eg. crontab-run scripts). Defaults to 0 (a clean
    # segment) when RPI_OBJECT_COUNT is unset; set the var to override.
    return $ENV{RPI_OBJECT_COUNT} // 0;
}
sub rpi_legal_pin_count {
    # Pre-existing pins registered in the shared 'rpit' segment by external,
    # long-running processes. Defaults to 0 when RPI_PIN_COUNT is unset, so a
    # clean machine compares against 0 rather than undef; set the var to override.
    return $ENV{RPI_PIN_COUNT} // 0;
}

# various test run checks

sub rpi_sudo_check {
    if (! $ENV{RPI_SUDO} && $> != 0){
        plan skip_all => "RPI_SUDO env var not set\n";
    }
}
sub rpi_multi_check {
    if (!$ENV{RPI_MULTI}) {
        plan skip_all => "RPI_MULTI environment variable not set\n";
    }
}

# PWM -> ADS1115 feedback calibration, single-sourced here for both PWM
# feedback tests (t/109-pwm_hw_mods.t and t/140-pwm_spi_adc.t) so a hardware
# recalibration updates both in one place.
#
# %pwm_adc_windows holds the empirically calibrated ADC percent windows per
# PWM level at the default PWM range (1023), as historically carried by
# t/140. rpi_pwm_adc_window() returns the empirical window when one exists
# for the requested level/range; for any other level/range combination
# (e.g. t/109's range-2000 sweep) it falls back to the model: expected duty
# (pwm / range * 100) +/- RPI_PWM_TOLERANCE percentage points, clamped to
# 0..100. The tolerance is derived from the empirical windows, whose largest
# deviation from ideal duty is 3.35 points.

use constant RPI_PWM_TOLERANCE => 4;

my %pwm_adc_windows = (
    100  => [8, 13],
    200  => [18, 22],
    300  => [27, 31],
    400  => [36, 42],
    500  => [46, 50],
    600  => [58, 62],
    700  => [67, 70],
    800  => [75, 79],
    900  => [86, 89],
    1000 => [96, 100],
);

sub rpi_pwm_adc_window {
    my ($pwm, $range) = @_;

    if (! defined $pwm || $pwm !~ /^\d+$/){
        croak "rpi_pwm_adc_window() requires the \$pwm param, and it must " .
              "be an integer";
    }

    if (! defined $range || $range !~ /^\d+$/ || $range == 0){
        croak "rpi_pwm_adc_window() requires the \$range param, and it " .
              "must be a positive integer";
    }

    if ($range == 1023 && exists $pwm_adc_windows{$pwm}){
        return @{ $pwm_adc_windows{$pwm} };
    }

    my $duty = $pwm / $range * 100;

    my $min = $duty - RPI_PWM_TOLERANCE;
    $min = 0 if $min < 0;

    my $max = $duty + RPI_PWM_TOLERANCE;
    $max = 100 if $max > 100;

    return ($min, $max);
}
sub rpi_i2c_check {
    # Gate tests that require a live I2C bus (e.g. the ADS1115 ADC). Without
    # this, a test that unconditionally touches I2C dies mid-run when the bus
    # is disabled, leaving stale metadata in shared memory that cascades into
    # subsequent tests.
    if (! $ENV{RPI_I2C}) {
        plan skip_all => "RPI_I2C environment variable not set (these tests " .
                         "verify PWM via the I2C ADS1115; set RPI_I2C=1 when " .
                         "the I2C bus and ADS1115 are wired and powered)\n";
    }
}

# fetch the current running test file number

sub rpi_running_test {
    (my $test) = @_;

    my $pi = RPi::WiringPi->new(label => 't/RPiTest.pm', shm_key => 'rpit');
    $pi->meta_lock;
    my $meta = $pi->meta_fetch;
    
    if ($test =~ m|t/(\d+)-(.*)\.t|){
        $meta->{testing}{test_num} = $1;
        $meta->{testing}{test_name} = $2;
        $pi->meta_store($meta);
        $pi->meta_unlock;
        $pi->cleanup;
        return 0;
    }
    elsif ($test =~ /^-\d+/){
        $meta->{testing}{test_num} = -1;
        $meta->{testing}{test_name} = '';
        $pi->meta_store($meta);
        $pi->meta_unlock;
        $pi->cleanup;
        return 0;
    }

    croak
        "rpi_running_test() couldn't translate '$test' to a usable shared format\n";
}

# get and set the availability of the OLED

sub rpi_oled_available {
    my ($available) = @_;

    if ($available) {
        if (-e $oled_lock) {
            unlink $oled_lock or die $!;
        }
    }

    return -e $oled_lock ? 0 : 1;
}
sub rpi_oled_unavailable {
    open my $wfh, '>', $oled_lock or die $!;
    close $wfh;

    return -e $oled_lock ? 1 : 0;
}

# test whether all pins have been reset to program start defaults

sub rpi_check_pin_status {
    setup_gpio();

    # pins 4, 5, 6, 17, 22, 27 removed because of LCD

    my $oled_locked = -e '/dev/shm/oled_in_use';

    if ($oled_locked) {
        note "I2C locked due to external OLED software running; skipping pins 2 and 3";
    }

    my @gpio_pins;

    if ($oled_locked) {
        @gpio_pins = qw(
            14 15 18 23 24 10 9 25 11 8 7 0 1 12 13 19 16 20 21 26
        );
    }
    else {
        @gpio_pins = qw(
            2 3 14 15 18 23 24 10 9 25 11 8 7 0 1 12 13 19 16 20 21 26
        );
    }
    my $config = rpi_default_pin_config();

    for (@gpio_pins){
        is get_alt($_), $config->{$_}{alt}, "pin $_ set back to default mode ($config->{$_}{alt}) ok";

        # An undef state means "mode-only check" (eg. the CS pins, whose level
        # depends on the attached device)

        if (defined $config->{$_}{state}){
            is read_pin($_), $config->{$_}{state}, "pin $_ set back to default state ($config->{$_}{state}) ok";
        }
    }
}

# verify whether all pins have been reset to program start defaults

sub rpi_verify_pin_status {
    setup_gpio();

    # pins 4, 5, 6, 17, 22, 27 removed because of LCD

    my $oled_locked = -e '/dev/shm/oled_in_use';

    my @gpio_pins;

    if ($oled_locked) {
        @gpio_pins = qw(
            14 15 18 23 24 10 9 25 11 8 7 0 1 12 13 19 16 20 21 26
        );
    }
    else {
        @gpio_pins = qw(
            2 3 14 15 18 23 24 10 9 25 11 8 7 0 1 12 13 19 16 20 21 26
        );
    }
    my $config = rpi_default_pin_config();

    my $incorrect_config = 0;

    for (@gpio_pins){
        my $alt = get_alt($_);

        if ($alt != $config->{$_}{alt}){
            note "pin $_ alt mismatch: got $alt, expected $config->{$_}{alt}";
            $incorrect_config++;
        }

        # An undef state means "mode-only check" (eg. the CS pins)

        if (defined $config->{$_}{state}){
            my $state = read_pin($_);

            if ($state != $config->{$_}{state}){
                note "pin $_ state mismatch: got $state, expected $config->{$_}{state}";
                $incorrect_config++;
            }
        }

        return 0 if $incorrect_config;
    }

    return $incorrect_config ? 0 : 1;
}

# identify which board family we're running on, so the correct default pin
# config table can be loaded. The legacy BCM boards (Pi 3, Pi 4) share the
# classic 0-7 alt-mode encoding from get_alt(); the Pi 5 / RP1 peripheral uses
# a different funcsel scheme (e.g. 31 == "null / no peripheral function").

sub rpi_board_tag {
    return 'pi5' if WiringPi::API::pi_rp1_model();

    my $info  = WiringPi::API::pi_board_id();
    my $model = ref $info ? $info->{model} : -1;

    # wiringPi model codes: 17 == 4B, 19 == 400, 20 == CM4
    return 'pi4' if grep { $model == $_ } (17, 19, 20);

    # everything else legacy (3B/3B+/3A+/CM3/Zero etc.)
    return 'pi3';
}

# Return the GPIO-header serial device for the detected board. The Pi 3/4 leave
# GPIO 14/15 on the mini-UART (/dev/ttyS0) unless Bluetooth is disabled; the
# Pi 5 always exposes the header UART as /dev/ttyAMA0 (Bluetooth has its own).

sub rpi_serial_device {
    my %device = (
        pi3 => '/dev/ttyS0',
        pi4 => '/dev/ttyS0',
        pi5 => '/dev/ttyAMA0',
    );

    return $device{ rpi_board_tag() } // '/dev/ttyAMA0';
}

# fetch the default pin state and mode for the detected board

sub rpi_default_pin_config {

    # Pi 3 (BCM2837) - classic 0-7 alt-mode encoding (ALT0 == 4)
    my $pi3 = {
      '0'  => { 'alt' => 0, 'state' => 1 },
      '1'  => { 'alt' => 0, 'state' => 1 },
      '2'  => { 'alt' => 4, 'state' => 1 },
      '3'  => { 'alt' => 4, 'state' => 1 },
      '4'  => { 'alt' => 0, 'state' => 1 },
      '5'  => { 'alt' => 0, 'state' => 1 },
      '6'  => { 'alt' => 0, 'state' => 1 },
      '7'  => { 'alt' => 1, 'state' => 1 },
      '8'  => { 'alt' => 1, 'state' => 1 },
      '9'  => { 'alt' => 4, 'state' => 0 },
      '10' => { 'alt' => 4, 'state' => 0 },
      '11' => { 'alt' => 4, 'state' => 0 },
      # 12/26 are the DAC/ADC chip-select pins; their level depends on the
      # attached device's pull state, so only the alt mode is verified
      '12' => { 'alt' => 0, 'state' => undef },
      '13' => { 'alt' => 0, 'state' => 0 }, # OUTPUT/HIGH due to the dpot test (t/345)
      # 14/15: alt 4 (ALT0) when Serial bluetooth disabled
      '14' => { 'alt' => 4, 'state' => 1 },
      '15' => { 'alt' => 4, 'state' => 1 },
      '16' => { 'alt' => 0, 'state' => 0 },
      '17' => { 'alt' => 0, 'state' => 1 },
      '18' => { 'alt' => 0, 'state' => 0 },
      '19' => { 'alt' => 0, 'state' => 0 },
      '20' => { 'alt' => 0, 'state' => 0 },
      '21' => { 'alt' => 0, 'state' => 0 },
      '22' => { 'alt' => 0, 'state' => 1 },
      '23' => { 'alt' => 0, 'state' => 0 },
      '24' => { 'alt' => 0, 'state' => 0 },
      '25' => { 'alt' => 0, 'state' => 0 },
      '26' => { 'alt' => 0, 'state' => undef }, # ADC CS - mode-only check
      '27' => { 'alt' => 0, 'state' => 1 }, # hot due to LCD
    };

    # Pi 4 (BCM2711) - shares the legacy 0-7 alt-mode encoding with the Pi 3
    my $pi4 = {
      '0'  => { 'alt' => 0, 'state' => 1 },
      '1'  => { 'alt' => 0, 'state' => 1 },
      '2'  => { 'alt' => 4, 'state' => 1 },
      '3'  => { 'alt' => 4, 'state' => 1 },
      '4'  => { 'alt' => 0, 'state' => 1 },
      '5'  => { 'alt' => 0, 'state' => 1 },
      '6'  => { 'alt' => 0, 'state' => 1 },
      '7'  => { 'alt' => 1, 'state' => 1 },
      '8'  => { 'alt' => 1, 'state' => 1 },
      '9'  => { 'alt' => 4, 'state' => 0 },
      '10' => { 'alt' => 4, 'state' => 0 },
      '11' => { 'alt' => 4, 'state' => 0 },
      # 12/26 are the DAC/ADC chip-select pins; their level depends on the
      # attached device's pull state, so only the alt mode is verified
      '12' => { 'alt' => 0, 'state' => undef },
      '13' => { 'alt' => 0, 'state' => 0 }, # OUTPUT/HIGH due to the dpot test (t/345)
      # 14/15: alt 4 (ALT0) when Serial bluetooth disabled
      '14' => { 'alt' => 4, 'state' => 1 },
      '15' => { 'alt' => 4, 'state' => 1 },
      '16' => { 'alt' => 0, 'state' => 0 },
      '17' => { 'alt' => 0, 'state' => 1 },
      '18' => { 'alt' => 0, 'state' => 0 },
      '19' => { 'alt' => 0, 'state' => 0 },
      '20' => { 'alt' => 0, 'state' => 0 },
      '21' => { 'alt' => 0, 'state' => 0 },
      '22' => { 'alt' => 0, 'state' => 1 },
      '23' => { 'alt' => 0, 'state' => 0 },
      '24' => { 'alt' => 0, 'state' => 0 },
      '25' => { 'alt' => 0, 'state' => 0 },
      '26' => { 'alt' => 0, 'state' => undef }, # ADC CS - mode-only check
      '27' => { 'alt' => 0, 'state' => 1 }, # hot due to LCD
    };

    # Pi 5 (RP1) - RP1 funcsel encoding; 31 == "null / no peripheral function"
    my $pi5 = {
      '0'  => { 'alt' => 0,  'state' => 1 },
      '1'  => { 'alt' => 0,  'state' => 1 },
      # 2/3: I2C funcsel (7) when the I2C bus is enabled
      '2'  => { 'alt' => 7,  'state' => 1 },
      '3'  => { 'alt' => 7,  'state' => 1 },
      '4'  => { 'alt' => 31, 'state' => 0 },
      '5'  => { 'alt' => 31, 'state' => 0 },
      '6'  => { 'alt' => 31, 'state' => 0 },
      '7'  => { 'alt' => 1,  'state' => 1 },
      '8'  => { 'alt' => 1,  'state' => 1 },
      # 9/10/11: SPI funcsel (4) when the SPI bus is enabled
      '9'  => { 'alt' => 4,  'state' => 0 },
      '10' => { 'alt' => 4,  'state' => 0 },
      '11' => { 'alt' => 4,  'state' => 0 },
      # 12/26 are the DAC/ADC chip-select pins; their level depends on the
      # attached device's pull state, so only the alt mode is verified
      '12' => { 'alt' => 31, 'state' => undef },
      '13' => { 'alt' => 31, 'state' => 0 }, # OUTPUT/HIGH due to the dpot test (t/345)
      # 14/15: UART funcsel (3) when the header UART is enabled; line idles high
      '14' => { 'alt' => 3,  'state' => 1 },
      '15' => { 'alt' => 3,  'state' => 1 },
      '16' => { 'alt' => 31, 'state' => 0 },
      '17' => { 'alt' => 1,  'state' => 0 },
      '18' => { 'alt' => 0,  'state' => 0 },
      '19' => { 'alt' => 31, 'state' => 0 },
      '20' => { 'alt' => 31, 'state' => 0 },
      '21' => { 'alt' => 31, 'state' => 0 },
      '22' => { 'alt' => 1,  'state' => 0 },
      '23' => { 'alt' => 1,  'state' => 0 },
      '24' => { 'alt' => 31, 'state' => 0 },
      '25' => { 'alt' => 31, 'state' => 0 },
      '26' => { 'alt' => 31, 'state' => undef }, # ADC CS - mode-only check
      '27' => { 'alt' => 1,  'state' => 0 }, # hot due to LCD
    };

    my %config = (
        pi3 => $pi3,
        pi4 => $pi4,
        pi5 => $pi5,
    );

    return $config{ rpi_board_tag() };
}

# reset the pins and meta data to default

sub rpi_reset {
    # reset pins and meta data

    my ($all) = @_;

    $all //= 0;

    my $pi = RPi::WiringPi->new(
        label           => 'rpi_reset',
        shm_key         => 'rpit',
        rpi_register    => 0,
    );

    $pi->meta_erase($all);

    my $meta = $pi->meta_fetch;
    $pi->cleanup;

    is keys %{ $meta }, 0, "meta data store has been reset ok";

    my $pin_defaults = rpi_default_pin_config();
    my $valid_pin_config = rpi_verify_pin_status();

    warn "pin configuration is not valid, resetting..." if ! $valid_pin_config;

    if (! $valid_pin_config){
        for my $pin (keys %$pin_defaults) {
            # Reuse the library's RP1-aware restore (pinMode for INPUT/OUTPUT,
            # pinctrl for "no function", pinModeAlt for real alts) so the reset
            # actually restores Pi 5 pins instead of mis-handling them.
            $pi->_restore_pin_alt($pin, $pin_defaults->{$pin}{alt});

            if (defined $pin_defaults->{$pin}{state}){
                WiringPi::API::digitalWrite($pin, $pin_defaults->{$pin}{state});
            }
        }
    }
}

1;
