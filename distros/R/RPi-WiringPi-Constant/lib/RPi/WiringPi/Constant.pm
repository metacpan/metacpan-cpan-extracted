package RPi::WiringPi::Constant;

use strict;
use warnings;

our $VERSION = '0.02';

require Exporter;
use base qw( Exporter );
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

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

sub _vim{1;};
1;
__END__

=head1 NAME

RPi::WiringPi::Constant - Constant variables for RPi::WiringPi

=head1 SYNOPSIS

    use RPi::WiringPi::Constant (:all);

    # or...

    use RPi::WiringPi::Constant (:pinmode);

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

=head2 :interrupt

Edge detection states for interrupts.

    EDGE_SETUP   => 0,  # reserved
    EDGE_FALLING => 1,
    EDGE_RISING  => 2,
    EDGE_BOTH    => 3,
    
=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
