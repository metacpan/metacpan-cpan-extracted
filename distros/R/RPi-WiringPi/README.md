# NAME

RPi::WiringPi - Perl interface to Raspberry Pi's board, GPIO, LCDs and other
various items

## Table of Contents

- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
- [BASE METHODS](#base-methods)
  - [new(\[%args\])](#newargs)
  - [adc](#adc)
    - [ADS1115](#ads1115)
    - [MCP3008](#mcp3008)
  - [bmp](#bmp)
  - [dac](#dac)
  - [dpot($cs, $channel)](#dpotcs-channel)
  - [gps](#gps)
  - [hcsr04($trig, $echo)](#hcsr04trig-echo)
  - [hygrometer($pin)](#hygrometerpin)
  - [i2c($addr, \[$device\])](#i2caddr-device)
  - [lcd(...)](#lcd)
  - [oled(\[$model\], \[$i2c\_addr\], \[$display\_splash\_page\])](#oledmodel-i2c_addr-display_splash_page)
  - [pin($pin\_num, $comment)](#pinpin_num-comment)
  - [rtc](#rtc)
  - [eeprom](#eeprom)
  - [expander](#expander)
  - [serial($device, $baud)](#serialdevice-baud)
  - [servo($pin\_num)](#servopin_num)
  - [shift\_register($base, $num\_pins, $data, $clk, $latch)](#shift_registerbase-num_pins-data-clk-latch)
  - [spi($channel, $speed)](#spichannel-speed)
  - [stepper\_motor($pins)](#stepper_motorpins)
  - [CORE PI SYSTEM METHODS](#core-pi-system-methods)
    - [gpio\_layout](#gpio_layout)
    - [io\_led](#io_led)
    - [pwr\_led](#pwr_led)
    - [identify](#identify)
    - [label](#label)
    - [pin\_scheme](#pin_scheme)
    - [pin\_map](#pin_map)
    - [pin\_to\_gpio](#pin_to_gpio)
    - [wpi\_to\_gpio](#wpi_to_gpio)
    - [phys\_to\_gpio](#phys_to_gpio)
    - [pwm\_range](#pwm_range)
    - [pwm\_mode](#pwm_mode)
    - [pwm\_clock](#pwm_clock)
    - [registered\_pins](#registered_pins)
    - [register\_pin](#register_pin)
    - [unregister\_pin](#unregister_pin)
    - [cleanup](#cleanup)
  - [ADDITIONAL PI SYSTEM METHODS](#additional-pi-system-methods)
    - [cpu\_percent](#cpu_percent)
    - [mem\_percent](#mem_percent)
    - [core\_temp](#core_temp)
    - [gpio\_info](#gpio_info)
    - [raspi\_config](#raspi_config)
    - [network\_info](#network_info)
    - [file\_system](#file_system)
    - [pi\_details](#pi_details)
    - [pi\_model](#pi_model)
  - [INTERRUPT METHODS](#interrupt-methods)
    - [wait\_interrupts($timeout\_ms)](#wait_interruptstimeout_ms)
    - [run\_interrupt\_loop($timeout\_ms, $max)](#run_interrupt_looptimeout_ms-max)
    - [stop\_interrupt\_loop](#stop_interrupt_loop)
    - [dispatch\_interrupts](#dispatch_interrupts)
    - [stop\_interrupts](#stop_interrupts)
    - [last\_interrupt](#last_interrupt)
    - [auto\_dispatch\_interrupts($bool, $signal)](#auto_dispatch_interruptsbool-signal)
    - [interrupt\_buffer($bytes)](#interrupt_bufferbytes)
    - [interrupt\_dropped](#interrupt_dropped)
    - [background\_interrupts(\[$pin, $edge, $callback, $debounce\], ...)](#background_interruptspin-edge-callback-debounce-)
    - [worker(\\&body, \\%opts)](#workerbody-opts)
- [RUNNING TESTS](#running-tests)
- [TROUBLESHOOTING](#troubleshooting)
- [AUTHOR](#author)
- [COPYRIGHT AND LICENSE](#copyright-and-license)

# SYNOPSIS

Please see the [FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for full usage details.

       use RPi::WiringPi;
       use RPi::Const qw(:all);
    
       my $pi = RPi::WiringPi->new;
    
       # For the below handful of system methods, see RPi::SysInfo
    
       my $mem_percent = $pi->mem_percent;
       my $cpu_percent = $pi->cpu_percent;
       my $cpu_temp    = $pi->core_temp;
       my $gpio_info   = $pi->gpio_info;
       my $raspi_conf  = $pi->raspi_config;
       my $net_info    = $pi->network_info;
       my $file_system = $pi->file_system;
       my $hw_details  = $pi->pi_details;
       my $pi_model    = $pi->pi_model;

       # Pin
    
       my $pin = $pi->pin(5);
       $pin->mode(OUTPUT);
       $pin->write(ON);
    
       my $num     = $pin->num;
       my $mode    = $pin->mode;
       my $state   = $pin->read;
    
       # Cleanup all pins and reset them to default before exiting your program
    
       $pi->cleanup;
    

# DESCRIPTION

This is the root module for the `RPi::WiringPi` system. It interfaces to a
Raspberry Pi board, its accessories and its GPIO pins via the
[wiringPi](http://wiringpi.com) library through the Perl wrapper
[WiringPi::API](https://metacpan.org/pod/WiringPi::API)
module, and various other custom device specific  modules.

[wiringPi](http://wiringpi.com) must be installed prior to installing/using
this module (v3.18).

We always and only use the `GPIO` pin numbering scheme.

This module is essentially a 'manager' for the sub-modules (ie. components).
You can use the component modules directly, but retrieving components through
this module instead has many benefits. We maintain a registry of pins and other
data, and reset the Pi back to default settings when your program ends (on
normal exit, on an uncaught `die()`, and on `SIGINT`/`SIGTERM`), so components
are not left in an inconsistent state. Component modules do none of these things.

There are a basic set of constants that can be imported. See [RPi::Const](https://metacpan.org/pod/RPi%3A%3AConst).

It's handy to have access to a pin mapping conversion chart. There's an
excellent pin scheme map for reference at
[pinout.xyz](https://pinout.xyz/pinout/wiringpi). You can also run the `pinmap`
command that was installed by this module, or `wiringPi`'s `gpio readall`
command.

# BASE METHODS

## new(\[%args\])

Returns a new `RPi::WiringPi` object. We exclusively use the `GPIO`
(Broadcom (BCM) GPIO) pin numbering scheme.

Parameters:

    setup => $string

Optional, String: Which `wiringPi` setup routine (and therefore pin numbering
scheme) to initialize the board with. Matching is case-insensitive on the
first letter:

    'gpio'      - GPIO (BCM) numbering; the default if not sent in
    'wiringpi'  - wiringPi's own (WPI) numbering
    'none'      - skip board setup entirely (the pin scheme remains
                  uninitialized; primarily for testing)

Any other value will croak. Note that if another application in the process
has already run a setup routine (signalled via the `RPI_PIN_MODE` environment
variable), that existing scheme is honoured and this parameter is ignored.

    shm_key => $string

By default, we use the key `rpiw` as the shared memory segment key. You can
change this if desired. Useful for separating "groups" of Pi objects from one
another (for example, production scripts can operate at the same time as test
scripts, and both use their own shared memory pool).

    fatal_exit => $bool

Optional: Controls what happens when we trap a `SIGINT` (Ctrl-C) or `SIGTERM`.
In both cases we first reset the Pi hardware to a safe state. By default
(`fatal_exit` true), we then re-raise the signal so the program terminates as it
normally would. Set `fatal_exit` to false (`0`) to perform the cleanup and then
**continue running** your script (eg. for unit-test work, or to allow your own
signal handling to take over).

With multiple Pi objects in a single process, the signal is re-raised only if
every live object has `fatal_exit` true; any object created with
`fatal_exit => 0` keeps the process running.

Note that this only affects trapped signals. Hardware cleanup on a normal exit or
on an uncaught `die()` always happens automatically (via the object's `END`/
`DESTROY` handling); we do **not** trap `$SIG{__DIE__}`, so a `die()` you catch
yourself with `eval` will not disturb your pins. Any `$SIG{INT}`/`$SIG{TERM}`
handler you installed before creating the object is chained to, not replaced.

    rpi_register => $bool

Optional: Set this value to false (`0`) to bypass the Pi object registration in
the meta data. This will also prevent pins from being registered as well. If set
to false, no object or pin cleanup will take place at the end of a program run.

    rpi_register_pins => $bool

Optional: Similar to `rpi_register`, but only bypasses the pin registration.
Object registration will still occur, and the object will be cleaned up after
but the pins will not. Should only be used for testing.

## adc

There are two different ADCs that you can select from. The default is the
ADS1x15 series:

### ADS1115

Returns a [RPi::ADC::ADS](https://metacpan.org/pod/RPi%3A%3AADC%3A%3AADS) object, which allows you to read the four analog
input channels on an Adafruit ADS1xxx analog to digital converter.

Parameters:

The default (no parameters) is almost always enough, but please do review
the documentation in the link above for further information, and have a
look at the
[ADC tutorial section](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ#ANALOG-TO-DIGITAL-CONVERTERS-ADC) in
this distribution.

### MCP3008

You can also use an [RPi::ADC::MCP3008](https://metacpan.org/pod/RPi%3A%3AADC%3A%3AMCP3008) ADC.

Parameters:

       model => 'MCP3008'
    

Mandatory, String. The exact quoted string above.

       channel => $channel
    

Mandatory, Integer. `0` or `1` for the Pi's onboard hardware CS/SS CE0 and CE1
pins, or any GPIO number above `1` in order to use an arbitrary GPIO pin for
the CS pin, and we'll do the bit-banging of the SPI bus automatically.

## bmp

Returns a [RPi::BMP180](https://metacpan.org/pod/RPi%3A%3ABMP180) object, which allows you to return the
current temperature in farenheit or celcius, along with the ability to retrieve
the barometric pressure in kPa.

## dac

Returns a [RPi::DAC::MCP4922](https://metacpan.org/pod/RPi%3A%3ADAC%3A%3AMCP4922) object (supports all 49x2 series DACs). These
chips provide analog output signals from the Pi's digital output. Please
see the documentation of that module for further information on both the
configuration and use of the DAC object.

Parameters:

       model => 'MCP4922'
    

Optional, String. The model of the DAC you're using. Defaults to `MCP4922`.

       channel => 0|1
    

Mandatory, Bool. The SPI channel to use.

       cs => $pin
    

Mandatory, Integer. A valid GPIO pin that the DAC's Chip Select is connected to.

There are a handful of other parameters that aren't required. For those, please
refer to the [RPi::DAC::MCP4922](https://metacpan.org/pod/RPi%3A%3ADAC%3A%3AMCP4922) documentation.

## dpot($cs, $channel)

Returns a [RPi::DigiPot::MCP4XXXX](https://metacpan.org/pod/RPi%3A%3ADigiPot%3A%3AMCP4XXXX) object, which allows you to manage a
digital potentiometer (only the MCP4XXXX versions are currently supported).

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for usage examples.

## gps

Returns a [GPSD::Parse](https://metacpan.org/pod/GPSD%3A%3AParse) object, allowing you to track your location.

The GPS distribution requires `gpsd` to be installed and running. All
parameters for the GPS can be sent in here and we'll pass them along. Please see
the link above for the full documentation on that module.

## hcsr04($trig, $echo)

Returns a [RPi::HCSR04](https://metacpan.org/pod/RPi%3A%3AHCSR04) ultrasonic distance measurement sensor object, allowing
you to retrieve the distance from the sensor in inches, centimetres or raw data.

Parameters:

       $trig
    

Mandatory, Integer: The trigger pin number, in GPIO numbering scheme.

       $echo
    

Mandatory, Integer: The echo pin number, in GPIO numbering scheme.

## hygrometer($pin)

Returns a [RPi::DHT11](https://metacpan.org/pod/RPi%3A%3ADHT11) temperature/humidity sensor object, allows you to fetch
the temperature (celcius or farenheit) as well as the current humidity level.

Parameters:

       $pin
    

Mandatory, Integer: The GPIO pin the sensor is connected to.

## i2c($addr, \[$device\])

Creates a new [RPi::I2C](https://metacpan.org/pod/RPi%3A%3AI2C) device object which allows you to communicate with
the devices on an I2C bus.

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for usage examples.

Aruino note: If using I2C with an Arduino, the Pi may speak faster than the
Arduino can. If this is the case, try lowering the I2C bus speed on the Pi:

       dtparam=i2c_arm_baudrate=10000
    

## lcd(...)

Returns a [RPi::LCD](https://metacpan.org/pod/RPi%3A%3ALCD) object, which allows you to fully manipulate
LCD displays connected to your Raspberry Pi.

Please see the linked documentation for information regarding the parameters
required.

## oled(\[$model\], \[$i2c\_addr\], \[$display\_splash\_page\])

Returns a specific `RPi::OLED::SSD1306` OLED display object, allowing you to
display text, characters and shapes to the screen.

Currently, only the `128x64` size model is offered, see the
[RPi::OLED::SSD1306::128\_64](https://metacpan.org/pod/RPi%3A%3AOLED%3A%3ASSD1306%3A%3A128_64) documentation for full usage details.

Parameters:

    $model

Optional, String: The screen size of the OLED you've got. Valid options are
`128x64`, `128x32` and `96x16`. Currently, only the `128x64` option is
valid, and it's the default if not sent in.

    $i2c_addr

Optional, Integer: The I2C address of your display. Defaults to `0x3C` if not
sent in.

    $display_splash_page

Optional, Bool: Whether to display the splash page when the display is
initialized. Defaults to true (`1`); send in `0` to skip it.

## pin($pin\_num, $comment)

Returns a [RPi::Pin](https://metacpan.org/pod/RPi%3A%3APin) object, mapped to a specified GPIO pin, which
you can then perform operations on. See that documentation for full usage
details.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

    $comment

Optional, String: A label stored alongside the pin's registration (visible in
the metadata store and used by the test suite). Defaults to none.

## rtc

Creates a new [RPi::RTC::DS3231](https://metacpan.org/pod/RPi%3A%3ARTC%3A%3ADS3231) object which provides access to the `DS3231`
or `DS1307` real-time clock modules.

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for some usage examples.

Parameters:

       $i2c_addr
    

Optional, Integer: The I2C address of the RTC module. Defaults to `0x68` for
the `DS3231` unit.

## eeprom

Creates and returns a new [RPi::EEPROM::AT24C32](https://metacpan.org/pod/RPi%3A%3AEEPROM%3A%3AAT24C32) object for reading and writing
to.

See the linked documentation for full documentation on usage, parameters or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for some usage examples.

## expander

Creates a new [RPi::GPIOExpander::MCP23017](https://metacpan.org/pod/RPi%3A%3AGPIOExpander%3A%3AMCP23017) GPIO expander chip object. This
adds an additional 16 pins across two banks (8 pins per bank).

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for some usage examples.

Parameters:

       $i2c_addr
    

Optional, Integer: The I2C address of the device. Defaults to `0x20`.

       $expander
    

Optional, String: The GPIO expander device type. Defaults to `MCP23017`, and
currently, this is the only option available.

## serial($device, $baud)

Creates a new [RPi::Serial](https://metacpan.org/pod/RPi%3A%3ASerial) object which allows basic read/write access to a
serial bus.

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for usage examples.

NOTE: On the Pi 3 and Pi 4, Bluetooth occupies the primary UART, leaving the
header pins (14, 15) on the mini-UART (`/dev/ttyS0`). To put the full PL011
UART back on the header you must disable Bluetooth in the
`/boot/firmware/config.txt` file (`/boot/config.txt` on releases before
Bookworm):

    dtoverlay=pi3-disable-bt-overlay

On the Pi 5, Bluetooth has its own dedicated UART, so no `disable-bt` overlay
is needed; simply enable the header UART (`/dev/ttyAMA0`) with `enable_uart=1`.

## servo($pin\_num)

This method configures PWM clock and divisor to operate a typical 50Hz servo,
and returns a special [RPi::Pin](https://metacpan.org/pod/RPi%3A%3APin) object. These servos have a `left` pulse of
`50`, a `centre` pulse of `150` and a `right` pulse of `250`. On exit of
the program (or a crash), we automatically clean everything up properly.

Parameters:

       $pin_num
    

Mandatory, Integer: The pin number (technically, this \*must\* be `18` on the
Raspberry Pi 3, as that's the only hardware PWM pin.

       %pwm_config
    

Optional, Hash. This parameter should only be used if you know what you're
doing and are having very specific issues.

Keys are `clock` with a value that coincides with the PWM clock speed. It
defaults to `192`. The other key is `range`, the value being an integer that
sets the range of the PWM. Defaults to `2000`.

Example:

       my $servo = $pi->servo(18);
    
       $servo->pwm(50);  # all the way left
       $servo->pwm(250); # all the way right
    

## shift\_register($base, $num\_pins, $data, $clk, $latch)

Allows you to access the output pins of up to four 74HC595 shift registers in
series, for a total of eight new output pins per register. Numerous chains of
four registers are permitted, each chain uses three GPIO pins.

Parameters:

       $base
    

Mandatory: Integer, represents the number at which you want to start
referencing the new output pins attached to the register(s). For example, if
you use `100` here, output pin `0` of the register will be `100`, output
`1` will be `101` etc.

       $num_pins
    

Mandatory: Integer, the number of output pins on the registers you want to use.
Each register has eight outputs, so if you have a single register in use, the
maximum number of additional pins would be eight.

       $data
    

Mandatory: Integer, the GPIO pin number attached to the `DS` pin (14) on the
shift register.

       $clk
    

Mandatory: Integer, the GPIO pin number attached to the `SHCP` pin (11) on the
shift register.

       $latch
    

Mandatory: Integer, the GPIO pin number attached to the `STCP` pin (12) on the
shift register.

## spi($channel, $speed)

Creates a new [RPi::SPI](https://metacpan.org/pod/RPi%3A%3ASPI) object which allows you to communicate on the Serial
Peripheral Interface (SPI) bus with attached devices.

See the linked documentation for full documentation on usage, or the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for usage examples.

## stepper\_motor($pins)

Creates a new [RPi::StepperMotor](https://metacpan.org/pod/RPi%3A%3AStepperMotor) object which allows you to drive a
28BYJ-48 stepper motor with a ULN2003 driver chip.

See the linked documentation for full usage instructions and the optional
parameters.

Parameters:

       pins => $aref
    

Mandatory, Array Reference: The ULN2003 has four data pins, IN1, IN2, IN3 and
IN4. Send in the GPIO pin numbers in the array reference which correlate to the
driver pins in the listed order.

       speed => 'half'|'full'
    

Optional, String: By default we run in "half speed" mode. Essentially, in this
mode we run through all eight steps. Send in 'full' to double the speed of the
motor. We do this by skipping every other step.

       delay => Float|Int
    

Optional, Float or Int: By default, between each step, we delay by `0.01`
seconds. Send in a float or integer for the number of seconds to delay each step
by. The smaller this number, the faster the motor will turn.

## CORE PI SYSTEM METHODS

Core methods are inherited in and documented in [RPi::WiringPi::Core](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3ACore). See
that documentation for full details of each one. I've included a basic
description of them here.

### gpio\_layout

Returns the GPIO layout, which in essence is the Pi board revision number.

### io\_led

Turn the disk IO (green) LED on or off.

### pwr\_led

Turn the power (red) LED on or off.

### identify

Toggles the power led off and disk IO led on which allows external physical
identification of the Pi you're running on.

### label

Sets an internal label/name to your [RPi::WiringPi](https://metacpan.org/pod/RPi%3A%3AWiringPi) Pi object.

### pin\_scheme

Returns the current pin mapping scheme in use within the object.

### pin\_map

Returns a hash reference mapping of the physical pin numbers to a pin scheme's
pin numbers.

### pin\_to\_gpio

Converts a pin number from any non-GPIO (BCM) scheme to GPIO (BCM) scheme.

### wpi\_to\_gpio

Converts a wiringPi pin number to GPIO pin number.

### phys\_to\_gpio

Converts a physical pin number to the GPIO pin number.

### pwm\_range

Set/get the PWM range.

### pwm\_mode

Set/get the PWM mode.

### pwm\_clock

Set/get the PWM clock.

### registered\_pins

Returns an array reference of all pin numbers currently registered in the
system. Used primarily for cleanup functionality.

### register\_pin

Registers a pin with the system for error checking, and proper resetting in the
cleanup routines.

### unregister\_pin

Removes an already registered pin.

### cleanup

Cleans up the entire system, resetting all pins and devices back to the state
we found them in when we initialized the system. It also releases any armed
interrupts (via `WiringPi::API::stop_interrupts()`) - stopping the wiringPi
ISR threads and closing the event pipe - so you don't have to do that yourself
at teardown.

Only the process that created the object performs the cleanup: in a forked
child the call is a no-op, so a child can't reset pins or mutate the shared
metadata on the parent's behalf when it exits.

## ADDITIONAL PI SYSTEM METHODS

We also include in the Pi object several hardware-type methods brought in from
[RPi::SysInfo](https://metacpan.org/pod/RPi%3A%3ASysInfo). They are loaded through [RPi::WiringPi::Core](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3ACore) via
inheritance. See the [RPi::SysInfo](https://metacpan.org/pod/RPi%3A%3ASysInfo) documentation for full method details.

       my $mem_percent = $pi->mem_percent;
       my $cpu_percent = $pi->cpu_percent;
       my $cpu_temp    = $pi->core_temp;
       my $gpio_info   = $pi->gpio_info;
       my $raspi_conf  = $pi->raspi_config;
       my $net_info    = $pi->network_info;
       my $file_system = $pi->file_system;
       my $hw_details  = $pi->pi_details;
    

### cpu\_percent

Returns the current CPU usage.

### mem\_percent

Returns the current memory usage.

### core\_temp

Returns the current temperature of the CPU core.

### gpio\_info

Returns the current status and configuration of one, many or all of the GPIO
pins.

### raspi\_config

Returns the live `vcgencmd get_config` values plus the non-comment directives
from the active `config.txt` (`/boot/firmware/config.txt` on Bookworm and
later, falling back to `/boot/config.txt` on older releases).

### network\_info

Returns the network configuration of the Pi, via `ifconfig` where the
`net-tools` package is installed, falling back to `ip addr` where it is not
(as on current Raspberry Pi OS Lite).

### file\_system

Returns current disk and mount information.

### pi\_details

Returns various information on both the hardware and OS aspects of the Pi.

### pi\_model

Returns the normalized Raspberry Pi board name (eg. `Raspberry Pi 5 Model B
Rev 1.1`), read from the devicetree model with a `/proc/cpuinfo` revision-code
decode fallback. Works across the Pi 0 through 5.

## INTERRUPT METHODS

Arm an interrupt on a pin with `$pin->set_interrupt($edge, $callback)`
(see [RPi::Pin](https://metacpan.org/pod/RPi%3A%3APin)). As of `WiringPi::API` 3.18 the callback must be a code
reference, and it runs in your own interpreter when you service the interrupt
rather than in the wiringPi ISR thread. The following methods drive that
dispatch. See [Interrupt usage](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ#Interrupt-usage) in the
[FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ) for a complete example.

### wait\_interrupts($timeout\_ms)

Blocks until an edge arrives or `$timeout_ms` milliseconds elapse, then runs
all pending interrupt callbacks. Returns the number of callbacks dispatched.
Call it in a loop to handle interrupts:

    $pi->wait_interrupts(1000) while 1;

### run\_interrupt\_loop($timeout\_ms, $max)

A blocking dispatch loop, so you don't have to write the
`wait_interrupts ... while 1` yourself. Repeatedly dispatches and returns
the total number of events handled. It runs until `$pi->stop_interrupt_loop`
is called (from a callback or a signal handler) or, if you pass `$max`, until
that many events have been dispatched.

    $pi->run_interrupt_loop;        # block, dispatching, until stop_interrupt_loop

Parameters:

    $timeout_ms

Optional, Integer: The per-iteration poll granularity in milliseconds (how long
each underlying `wait_interrupts` blocks waiting for an edge). Defaults to
`1000`.

    $max

Optional, Integer: The maximum number of events to dispatch before returning. If
omitted, the loop only ends when `$pi->stop_interrupt_loop` is called.

### stop\_interrupt\_loop

Breaks out of `run_interrupt_loop` at the next iteration. Safe to call from a
callback or a signal handler.

### dispatch\_interrupts

Runs all pending interrupt callbacks without blocking, and returns the number
dispatched. Use this instead of `wait_interrupts` when you already block
elsewhere (eg. in your own event loop).

### stop\_interrupts

Releases every armed interrupt: stops the wiringPi ISR threads and closes the
event pipe. The object's `cleanup` calls this for you automatically, so you
only need it to disarm interrupts while the program keeps running.

### last\_interrupt

Returns a hash reference describing the most recently dispatched interrupt event
\- `{ pin, pin_bcm, edge, status, ts_us }` - or `undef` if none has fired yet.
Because the callback only receives `($edge, $timestamp_us)`, this lets it (or
your main loop) recover the BCM pin and status; useful when one handler is armed
on several pins. Like `auto_dispatch_interrupts`, it reports a process-wide
value (the last event on any pin), so it lives on the Pi object.

### auto\_dispatch\_interrupts($bool, $signal)

Enables (`1`) or disables (`0`) async auto-dispatch for the whole process.
When enabled, `$pin->set_interrupt` callbacks fire **automatically** at Perl
safe points (via `SIGIO`) with no `wait_interrupts`/`dispatch_interrupts`
loop, and may touch your program's variables with no locking. The optional
`$signal` picks the delivery signal (default `SIGIO`; pass eg `'USR1'` to
avoid clashing with other `SIGIO` users). This is a
process-global switch (it affects every armed pin), which is why it lives on the
Pi object rather than on an individual pin. A long, non-yielding C/XS call defers
the callback until it returns - use `$pin->background_interrupt` (see
[RPi::Pin](https://metacpan.org/pod/RPi%3A%3APin)) if you need it to fire even then.

### interrupt\_buffer($bytes)

Gets (no argument) or sets the capacity of the interrupt queue - the kernel pipe
that absorbs edge bursts. On overflow the newest edges are dropped (never merged
or blocked) and counted, so raise this if a fast source outpaces your dispatch.
May be set before arming and persists across teardown. Process-wide, so it lives
on the Pi object. See `interrupt_buffer` in [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI) for details.

### interrupt\_dropped

Returns the running total of interrupt events dropped because the queue (see
`interrupt_buffer`) overflowed. A non-zero count means a source is outpacing
your dispatch - raise `interrupt_buffer` or dispatch more often. Process-wide,
so it lives on the Pi object. See `interrupt_dropped` in [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI) for
details.

### background\_interrupts(\[$pin, $edge, $callback, $debounce\], ...)

Handles **many** pins in a **single** background child (rather than one child per
pin via `$pin->background_interrupt`). Pass one array-ref spec per pin; the
returned handle adds `$h->arm($pin)` / `$h->disarm($pin)` (toggling
pins registered at creation) to the usual `stop`/`pid`/`running`. Because it
spans several pins it lives on the Pi object, not on a single pin. See
`background_interrupts` in [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI) for details.

**Dependency note:** the per-pin `$pin->background_interrupt` form referenced
above requires [RPi::Pin](https://metacpan.org/pod/RPi%3A%3APin) `2.3609` or greater (the version this distribution
already requires). To drive multiple pins from a single background child rather
than one child per pin, use this `$pi->background_interrupts` method.

### worker(\\&body, \\%opts)

Runs `\&body` as a hands-off background task, hiding the spawn mechanism, the
loop, and the lifecycle - the GPIO sibling of `background_interrupts`. By
default it forks a child (no `use threads` required) that runs `body`
repeatedly, and returns a `WiringPi::API::Worker` handle:

    pin_mode(2, 1);                                   # OUTPUT, once in main

    my $w = $pi->worker(sub {
        digital_write(2, 1); sleep 1;
        digital_write(2, 0); sleep 1;
    });

    # ... main does its own work ...

    $w->stop;                                         # idempotent

The handle carries `$w->stop` (idempotent), `$w->pid`, and
`$w->running`, matching the interrupt handle. You normally need not call
`stop` at all: `$pi->cleanup` (and therefore `DESTROY`) automatically
stops every worker started through this method, and a forked child never reaps
the parent's workers.

`\%opts` mirrors `WiringPi::API::worker()` exactly:

- `once => 1` - run `body` a single time instead of looping.
- `interval => $secs` - pace each pass (periodic sampler/blink)
instead of letting `body` set its own cadence.
- `shared => 1` - publish `body`'s return value as a lossy latest
value; read it from the parent with `$w->value`.
- `results => 1` - stream every defined return value back; drain it
with `$w->read` or select on `$w->fh`.
- `mechanism => 'fork' | 'thread'` - default `fork` (works on any
Perl). `thread` uses an ithread for shared-memory ergonomics and requires
`threads` to be loaded (croaks otherwise). Under `thread` mode, serialise
shared GPIO access yourself with `WiringPi::API::pi_lock` /
`WiringPi::API::pi_unlock`; the fork default never locks. See
[RPi::WiringPi::WORKERS](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AWORKERS) for the full OO threads/worker story.

All argument validation happens in the low-level layer, so an invalid `body`,
`interval`, or `mechanism` croaks before anything is spawned. See
`worker` in [WiringPi::API](https://metacpan.org/pod/WiringPi%3A%3AAPI) and [RPi::WiringPi::WORKERS](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AWORKERS) for full details.

# RUNNING TESTS

Please see [RUNNING TESTS](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ#RUNNING-TESTS) in the
[FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ).

# TROUBLESHOOTING

Please read through the [SETUP](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ#SETUP) section in the
[FAQ](https://metacpan.org/pod/RPi%3A%3AWiringPi%3A%3AFAQ).

# AUTHOR

Steve Bertrand, <steveb@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
