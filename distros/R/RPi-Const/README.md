# NAME

RPi::Const - Constant variables for embedded programming, including the RPi::
family of modules

# SYNOPSIS

    use RPi::Const (:all);

    # or...

    use RPi::Const (:pinmode);

    # etc

# DESCRIPTION

This module optionally exports selections or all constant variables used within
the `RPi::WiringPi` suite.

# CONSTANT EXPORT TAGS

These are the individual grouping of export tags. The `:all` tag includes all
of the below.

## :mode

Setup modes. This is what determines which pin numbering scheme you're using.
See [wiringPi setup modes](http://wiringpi.com/reference/setup) for details.

    RPI_MODE_WPI      =>  0, # wiringPi scheme
    RPI_MODE_GPIO     =>  1, # GPIO scheme
    RPI_MODE_GPIO_SYS =>  2, # GPIO scheme in SYS mode
    RPI_MODE_PHYS     =>  3, # physical pin layout scheme
    RPI_MODE_UNINIT   => -1, # setup not yet run

## :pinmode

Pin modes.

    INPUT            => 0,
    OUTPUT           => 1,
    PWM_OUT          => 2,
    GPIO_CLOCK       => 3,
    SOFT_PWM_OUTPUT  => 4,  # reserved
    SOFT_TONE_OUTPUT => 5,  # reserved
    PWM_TONE_OUTPUT  => 6,  # reserved

## :altmode

Pin ALT modes.

    ALT0 => 4,
    ALT1 => 5,
    ALT2 => 6,
    ALT3 => 7,
    ALT4 => 3,
    ALT5 => 2,

## :pull

Internal pin pull up/down resistor state.

    PUD_OFF  => 0,
    PUD_DOWN => 1,
    PUD_UP   => 2,

## :state

    HIGH => 1,
    LOW  => 0,
    ON   => 1,
    OFF  => 0,

## :pwm\_mode

The modes the PWM can be set to.

    PWM_MODE_MS  => 0,
    PWM_MODE_BAL => 1,

## :pwm\_defaults

Hardware defaults for PWM settings.

    PWM_DEFAULT_MODE => 1, # balanced mode
    PWM_DEFAULT_CLOCK => 32,
    PWM_DEFAULT_RANGE => 1023

## :interrupt

Edge detection states for interrupts.

    EDGE_SETUP   => 0,  # reserved
    EDGE_FALLING => 1,
    EDGE_RISING  => 2,
    EDGE_BOTH    => 3,

## :mcp23017\_registers

Hardware register locations and related info for the MCP23107 GPIO Expander

    MCP23017_IODIRA     => 0x00,
    MCP23017_IODIRB     => 0x01,
    MCP23017_IPOLA      => 0x02,
    MCP23017_IPOLB      => 0x03,
    MCP23017_GPINTENA   => 0x04,
    MCP23017_GPINTENB   => 0x05,
    MCP23017_DEFVALA    => 0x06,
    MCP23017_DEFVALB    => 0x07,
    MCP23017_INTCONA    => 0x08,
    MCP23017_INTCONB    => 0x09,
    MCP23017_IOCONA     => 0x0A,
    MCP23017_IOCONB     => 0x0B,
    MCP23017_GPPUA      => 0x0C,
    MCP23017_GPPUB      => 0x0D,
    MCP23017_INTFA      => 0x0E,
    MCP23017_INTFB      => 0x0F,
    MCP23017_INTCAPA    => 0x10,
    MCP23017_INTCAPB    => 0x11,
    MCP23017_GPIOA      => 0x12,
    MCP23017_GPIOB      => 0x13,
    MCP23017_OLATA      => 0x14,
    MCP23017_OLATB      => 0x15,
    
    MCP23017_INPUT      => 1,
    MCP23017_OUTPUT     => 0

## :wpi\_pin

The `WPIPinType` pin-numbering scheme passed to wiringPi's
`wiringPiSetupPinType()` / `wiringPiSetupGpioDevice()` setup variants. Note
that `WPI_PIN_PHYS` is intentionally not provided - physical-pin setup is not
supported within the suite.

    WPI_PIN_BCM => 1,
    WPI_PIN_WPI => 2,

## :int\_edge

wiringPi-native names for the interrupt edge-detection triggers (these mirror
wiringPi's own `INT_EDGE_*` `#define`s). Same values as the `:interrupt`
(`EDGE_*`) tag.

    INT_EDGE_SETUP   => 0,  # reserved
    INT_EDGE_FALLING => 1,
    INT_EDGE_RISING  => 2,
    INT_EDGE_BOTH    => 3,

# AUTHOR

Steve Bertrand, <steveb@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
