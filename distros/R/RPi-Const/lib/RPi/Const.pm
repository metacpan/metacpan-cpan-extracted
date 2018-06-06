package RPi::Const;

use strict;
use warnings;

our $VERSION = '1.04';

require Exporter;
use base qw( Exporter );
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    PWM_MODE_MS => 0,
    PWM_MODE_BAL => 1,
};

{ # PWM modes
    my @const = qw(
        PWM_MODE_MS
        PWM_MODE_BAL
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pwm_mode} = \@const;
}

use constant {
    PWM_DEFAULT_MODE => 1, # balanced
    PWM_DEFAULT_CLOCK => 32,
    PWM_DEFAULT_RANGE => 1023,
};

{ # PWM defaults
    my @const = qw(
        PWM_DEFAULT_MODE
        PWM_DEFAULT_CLOCK
        PWM_DEFAULT_RANGE
        );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pwm_defaults} = \@const;
}

use constant {
    INPUT => 0,
    OUTPUT => 1,
    PWM_OUT => 2,
    GPIO_CLOCK => 3,
    SOFT_PWM_OUTPUT => 4,
    SOFT_TONE_OUTPUT => 5,
    PWM_TONE_OUTPUT => 6,
};

{ # pinmodes
    my @const = qw(
        INPUT
        OUTPUT
        PWM_OUT
        GPIO_CLOCK
        SOFT_PWM_OUTPUT
        SOFT_TONE_OUTPUT
        PWM_TONE_OUTPUT
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pinmode} = \@const;
}

use constant {
    ALT0 => 4,
    ALT1 => 5,
    ALT2 => 6,
    ALT3 => 7,
    ALT4 => 3,
    ALT5 => 2,
};

{ # alt modes
    my @const = qw(
        ALT0
        ALT1
        ALT2
        ALT3
        ALT4
        ALT5
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{altmode} = \@const;
}

use constant {
    PUD_OFF => 0,
    PUD_DOWN => 1,
    PUD_UP => 2,
};

{ # pull
    my @const = qw(
        PUD_UP
        PUD_DOWN
        PUD_OFF
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pull} = \@const;
};

use constant {
    HIGH => 1,
    LOW => 0,
    ON => 1,
    OFF => 0,
};
       
{ # state

    my @const = qw(
        HIGH
        LOW
        ON
        OFF
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{state} = \@const;
}   

use constant {
    EDGE_SETUP => 0,
    EDGE_FALLING => 1,
    EDGE_RISING => 2,
    EDGE_BOTH   => 3,
};
       
{ # interrupt

    my @const = qw(
        EDGE_SETUP
        EDGE_FALLING
        EDGE_RISING
        EDGE_BOTH
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{edge} = \@const;
}   

use constant {
    RPI_MODE_WPI => 0,
    RPI_MODE_GPIO => 1,
    RPI_MODE_GPIO_SYS => 2,
    RPI_MODE_PHYS => 3,
    RPI_MODE_UNINIT => -1,
};

{ # mode

    my @const = qw(
        RPI_MODE_WPI
        RPI_MODE_GPIO
        RPI_MODE_GPIO_SYS
        RPI_MODE_PHYS
        RPI_MODE_UNINIT
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{mode} = \@const;
}

use constant {
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
    MCP23017_OUTPUT     => 0,
};

{ # MCP23017 GPIO Expander Registers

    my @const = qw(
        MCP23017_IODIRA
        MCP23017_IODIRB
        MCP23017_IPOLA
        MCP23017_IPOLB
        MCP23017_GPINTENA
        MCP23017_GPINTENB
        MCP23017_DEFVALA
        MCP23017_DEFVALB
        MCP23017_INTCONA
        MCP23017_INTCONB
        MCP23017_IOCONA
        MCP23017_IOCONB
        MCP23017_GPPUA
        MCP23017_GPPUB
        MCP23017_INTFA
        MCP23017_INTFB
        MCP23017_INTCAPA
        MCP23017_INTCAPB
        MCP23017_GPIOA
        MCP23017_GPIOB
        MCP23017_OLATA
        MCP23017_OLATB
        MCP23017_INPUT
        MCP23017_OUTPUT
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{mcp23017_registers} = \@const;
}

sub _vim{1;};
1;
__END__

=head1 NAME

RPi::Const - Constant variables for embedded programming, including the RPi::
family of modules

=head1 SYNOPSIS

    use RPi::Const (:all);

    # or...

    use RPi::Const (:pinmode);

    # etc

=head1 DESCRIPTION

This module optionally exports selections or all constant variables used within
the C<RPi::WiringPi> suite.

=head1 CONSTANT EXPORT TAGS

These are the individual grouping of export tags. The C<:all> tag includes all
of the below.

=head2 :mode

Setup modes. This is what determines which pin numbering scheme you're using.
See L<wiringPi setup modes|http://wiringpi.com/reference/setup> for details.

    RPI_MODE_WPI      =>  0, # wiringPi scheme
    RPI_MODE_GPIO     =>  1, # GPIO scheme
    RPI_MODE_GPIO_SYS =>  2, # GPIO scheme in SYS mode
    RPI_MODE_PHYS     =>  3, # physical pin layout scheme
    RPI_MODE_UNINIT   => -1, # setup not yet run

=head2 :pinmode

Pin modes.

    INPUT            => 0,
    OUTPUT           => 1,
    PWM_OUT          => 2,
    GPIO_CLOCK       => 3,
    SOFT_PWM_OUTPUT  => 4,  # reserved
    SOFT_TONE_OUTPUT => 5,  # reserved
    PWM_TONE_OUTPUT  => 6,  # reserved

=head2 :altmode

Pin ALT modes.

    ALT0 => 4,
    ALT1 => 5,
    ALT2 => 6,
    ALT3 => 7,
    ALT4 => 3,
    ALT5 => 2,

=head2 :pull

Internal pin pull up/down resistor state.

    PUD_OFF  => 0,
    PUD_DOWN => 1,
    PUD_UP   => 2,

=head2 :state

    HIGH => 1,
    LOW  => 0,
    ON   => 1,
    OFF  => 0,

=head2 :pwm_mode

The modes the PWM can be set to.

    PWM_MODE_MS  => 0,
    PWM_MODE_BAL => 1,

=head2 :pwm_defaults

Hardware defaults for PWM settings.

    PWM_DEFAULT_MODE => 1, # balanced mode
    PWM_DEFAULT_CLOCK => 32,
    PWM_DEFAULT_RANGE => 1023

=head2 :interrupt

Edge detection states for interrupts.

    EDGE_SETUP   => 0,  # reserved
    EDGE_FALLING => 1,
    EDGE_RISING  => 2,
    EDGE_BOTH    => 3,

=head2 :mcp23017_registers

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

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
