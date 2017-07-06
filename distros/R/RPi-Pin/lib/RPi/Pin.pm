package RPi::Pin;

use strict;
use warnings;

use parent 'WiringPi::API';

our $VERSION = '2.3603';

sub new {
    my ($class, $pin) = @_;

    if (! defined $pin || $pin !~ /^\d+$/){
        die "pin must be an integer\n";
    }

    my $self = bless {}, $class;

    if (! $ENV{NO_BOARD}){
        if (! defined $ENV{RPI_PIN_MODE}){
            $ENV{RPI_PIN_MODE} = 1;
            $self->setup_gpio;
        }
    }

    $self->{pin} = $pin;

    return $self;
}
sub mode {
    my ($self, $mode) = @_;

    if (! defined $mode){
        return $self->get_alt($self->num);
    }
    if ($mode != 0 && $mode != 1 && $mode != 2 && $mode != 3){
        die "mode() mode param must be either 0 (input), 1 " .
            "(output), 2 (PWM output) or 3 (GPIO CLOCK output)\n";
    }

    $self->pin_mode($self->num, $mode);
}
sub mode_alt {
    my ($self, $alt) = @_;

    if (! defined $alt){
        return $self->get_alt($self->num);
    }

    $self->pin_mode_alt($self->num, $alt);
}
sub read {
    my $state = $_[0]->read_pin($_[0]->num);
    return $state;
}
sub write {
    my ($self, $value) = @_;
    if ($value != 0 && $value != 1){
        die "Core::write_pin value must be 0 or 1\n";
    }
    $self->write_pin($self->num, $value);
}
sub pull {
    my ($self, $direction) = @_;

    # 0 == down, 1 == up, 2 == off

    if ($direction != 0 && $direction != 1 && $direction != 2){
        die "Core::pull_up_down requires either 0, 1 or 2 for direction";
    }

    $self->pull_up_down($self->num, $direction);
}
sub pwm {
    my ($self, $value) = @_;

    my $gpio = $self->pin_to_gpio($self->num);

    if ($self->mode != 2 && $gpio == 18){
        my $num = $self->num;
        die "\npin $num isn't set to mode 2 (PWM). pwm() can't be set\n";
    }

    if ($value > 1023 || $value < 0){
        die "\npwm() value must be 0-1023\n";
    }

    $self->pwm_write($self->num, $value);
}
sub num {
    return $_[0]->{pin};
}
sub set_interrupt {
    my ($self, $edge, $callback) = @_;
    WiringPi::API::set_interrupt($self->num, $edge, $callback);
}
sub interrupt_set {
    my ($self, $edge, $callback) = @_;
    $self->set_interrupt($self->num, $edge, $callback);
}
sub _vim{1;};
1;
__END__

=head1 NAME

RPi::Pin - Access and manipulate Raspberry Pi GPIO pins

=head1 SYNOPSIS

    use RPi::Pin;
    use RPi::Constant qw(:all);

    my $pin = RPi::Pin->new(5);

    $pin->mode(INPUT);
    $pin->write(LOW);

    $pin->set_interrupt(EDGE_RISING, 'main::pin5_interrupt_handler');

    my $num = $pin->num;
    my $mode = $pin->mode;
    my $state = $pin->read;

    print "pin number $num is in mode $mode with state $state\n";

    sub pin5_interrupt_handler {
        print "in interrupt handler\n";
    }

=head1 DESCRIPTION

An object that represents a physical GPIO pin.

Using the pin object's methods, the GPIO pins can be controlled and monitored.

This distribution can be accessed through L<RPi::WiringPi>. Using that
distribution provides safety and cleanup procedures. Using this module directly
requires you to reset your pins manually.

We use the C<BCM> (C<GPIO>) pin numbering scheme.

=head1 METHODS

=head2 new($pin_num)

Takes the number representing the Pi's GPIO pin you want to use, and returns
an object for that pin.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

=head2 mode($mode)

Puts the pin into either C<INPUT>, C<OUTPUT>, C<PWM_OUT> or C<GPIO_CLOCK>
mode. If C<$mode> is not sent in, we'll return the pin's current mode.
           
Parameters:

    $mode

Optional: If not sent in, we'll simply return the current mode of the pin.
Otherwise, send in: C<0> for C<INPUT>, C<1> for C<OUTPUT>, C<2> for C<PWM_OUT>
and C<3> for C<GPIO_CLOCK> mode.

=head2 mode_alt($alt)

Allows you to set any pin to any mode.
            
Parameters:
        
    $alt

Optional: If not sent in, we'll simply return the current mode of the pin. The
possible values of this method are as follows:

    Value   Mode
    ------------
    0       INPUT
    1       OUTPUT
    4       ALT0
    5       ALT1
    6       ALT2
    7       ALT3
    3       ALT4
    2       ALT5

=head2 read()

Returns C<1> if the pin is C<HIGH> (on) and C<0> if the pin is C<LOW> (off).

=head2 write($state)

For pins in C<OUTPUT> mode, will turn C<HIGH> (on) the pin, or C<LOW> (off).

Parameters:

    $state

Send in C<1> to turn the pin on, and C<0> to turn it off.

=head2 pull($direction)

Used to set the internal pull-up or pull-down resistor for a pin. Calling this
method on a pin will automatically set the pin to C<INPUT> mode.

Parameter:

    $direction

Mandatory: C<2> for C<PUD_UP>, C<1> for C<PUD_DOWN> and C<0> for C<PUD_OFF>
(disabled the resistor).

=head2 set_interrupt($edge, $callback)

Listen for an interrupt on a pin, and do something if it is triggered.

Parameters:

    $edge

Mandatory: C<1> for C<EDGE_FALLING>, C<2> for C<EDGE_RISING>, or C<3> for
C<EDGE_BOTH>.

    $callback

The string name of a Perl subroutine that you've already written within your
code. This is the interrupt handler. When an interrupt is triggered, the code
in this subroutine will run. If you get errors when the handler is called,
specify the full package name to the handler (eg: C<'main::callback'>).

=head2 interrupt_set

DEPRECATED; See C<set_interrupt()>.

=head2 pwm($value)

Sets the level of the Pulse Width Modulation (PWM) of the pin. Dies if the
pin's C<mode()> is not set to PWM (C<2>). Note that only physical pin 12
(wiringPi pin 1, GPIO pin 18) is PWM hardware capable. 

Parameter:

    $value

Mandatory: values range from 0-1023. C<0> for 0% (off) and C<1023> for 100%
(fully on).

See L<RPi/pwm_range-range> for details on how to modify the range to
something other than C<0-1023>.

=head2 num()

Returns the pin number associated with the pin object.

=head1 SEE ALSO

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
