package RPi::Pin;

use strict;
use warnings;

use parent 'WiringPi::API';

use Carp qw(croak);
use RPi::Const qw(:all);

our $VERSION = '3.1801';

sub new {
    my ($class, $pin, $comment) = @_;

    if (! defined $pin || $pin !~ /^\d+$/){
        die "pin must be an integer\n";
    }

    my $self = bless {}, $class;
    $self->comment($comment);

    if (! $ENV{NO_BOARD}){
        if (! defined $ENV{RPI_PIN_MODE}){
            $ENV{RPI_PIN_MODE} = 1;
            $self->setup_gpio;
        }
    }

    $self->{pin} = $pin;

    return $self;
}
sub comment {
    my ($self, $comment) = @_;
    if (defined $comment){
        $self->{comment} = $comment;
    }
    return $self->{comment};
}
sub mode {
    my ($self, $mode) = @_;

    if (! defined $mode){
        return $self->get_alt($self->num);
    }

    if ($mode != INPUT && $mode != OUTPUT && $mode != PWM_OUT && $mode != GPIO_CLOCK){
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

    # PUD_OFF == 0, PUD_DOWN == 1, PUD_UP == 2

    if ($direction != PUD_OFF && $direction != PUD_DOWN && $direction != PUD_UP){
        die "Core::pull_up_down requires either 0, 1 or 2 for direction";
    }

    $self->pull_up_down($self->num, $direction);
}
sub pwm {
    my ($self, $value) = @_;

    if ($> != 0){
        die "\nPWM requires your script to be run as the 'root' user (sudo)\n";
    }

    if ($self->mode != PWM_OUT && $self->num == 18){
        my $num = $self->num;
        die "\npin $num isn't set to mode 2 (PWM). pwm() can't be set\n";
    }

    $self->pwm_write($self->num, $value);
}
sub num {
    return $_[0]->{pin};
}
sub background_interrupt {
    my ($self, $edge, $callback, @rest) = @_;

    # An optional trailing options hashref (eg. {results => 1}) may follow the
    # optional debounce; forward it through to WiringPi::API unchanged.
    my $opts = (@rest && ref $rest[-1] eq 'HASH') ? pop @rest : undef;
    my ($debounce_us) = @rest;

    if (! defined $edge || $edge !~ /^[123]$/) {
        croak "background_interrupt() \$edge must be EDGE_FALLING (1), " .
            "EDGE_RISING (2) or EDGE_BOTH (3)";
    }

    if (! defined $callback || ref $callback ne 'CODE') {
        croak "background_interrupt() requires \$callback to be a CODE reference";
    }

    if (defined $debounce_us && $debounce_us !~ /^\d+$/) {
        croak "background_interrupt() \$debounce_us must be a non-negative integer";
    }

    my @args = ($self->num, $edge, $callback);
    push @args, $debounce_us if defined $debounce_us;
    push @args, $opts if $opts;

    return WiringPi::API::background_interrupt(@args);
}
sub set_interrupt {
    my ($self, $edge, $callback, @rest) = @_;

    # An optional trailing options hashref (eg. {auto_dispatch => 1}) may follow
    # the optional debounce; forward it through to WiringPi::API unchanged.
    my $opts = (@rest && ref $rest[-1] eq 'HASH') ? pop @rest : undef;
    my ($debounce_us) = @rest;

    if (! defined $edge || $edge !~ /^[123]$/) {
        croak "set_interrupt() \$edge must be EDGE_FALLING (1), " .
            "EDGE_RISING (2) or EDGE_BOTH (3)";
    }

    if (! defined $callback || ref $callback ne 'CODE') {
        croak "set_interrupt() requires \$callback to be a CODE reference";
    }

    if (defined $debounce_us && $debounce_us !~ /^\d+$/) {
        croak "set_interrupt() \$debounce_us must be a non-negative integer";
    }

    my @args = ($self->num, $edge, $callback);
    push @args, $debounce_us if defined $debounce_us;
    push @args, $opts if $opts;

    WiringPi::API::set_interrupt(@args);
}
sub interrupt_set {
    my ($self, $edge, $callback, $debounce_us) = @_;
    $self->set_interrupt($edge, $callback, $debounce_us);
}

sub _vim{1;};

1;
__END__

=head1 NAME

RPi::Pin - Access and manipulate Raspberry Pi GPIO pins

=head1 SYNOPSIS

    use RPi::Pin;
    use RPi::Const qw(:all);

    my $pin = RPi::Pin->new(5, "Optional descriptive pin label");

    $pin->mode(INPUT);
    $pin->write(LOW);

    my $num = $pin->num;
    my $mode = $pin->mode;
    my $state = $pin->read;

    print "pin number $num is in mode $mode with state $state\n";

    # As of WiringPi::API 3.18 the callback fires only while dispatch is
    # serviced; { auto_dispatch => 1 } services it for you (fire and forget).

    $pin->set_interrupt(EDGE_RISING, \&pin5_interrupt_handler, { auto_dispatch => 1 });

    sub pin5_interrupt_handler {
        my ($edge, $timestamp_us) = @_;
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

=head2 new($pin_num, $comment)

Takes the number representing the Pi's GPIO pin you want to use, and returns
an object for that pin.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

    $comment

Optional, String: A custom name or purpose description to associate this pin
with.

=head2 comment($comment)

Sets/gets a description or name for the pin.

Parameters:
    
    $comment

Optional, String: If sent in, we'll set the pin's comment to this value.

Return: The currently set comment for the pin.

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

L<Here's|https://elinux.org/RPi_BCM2835_GPIOshttps://elinux.org/RPi_BCM2835_GPIOs>
a decent guide to the various ALT settings for each pin.

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

=head2 background_interrupt($edge, $callback, $debounce_us, \%opts)

Interrupts are armed on the pin but driven through the Pi object. For the
per-method reference see L<RPi::WiringPi/"INTERRUPT METHODS">, and for full
runnable examples - driving dispatch, auto-dispatch, the background results
channel and teardown - see L<RPi::WiringPi::INTERRUPTS>.

Like C<set_interrupt()>, but handles the interrupt in a B<background process>:
the library forks, arms the interrupt in the child, and runs C<$callback> there
on each edge while your main program carries on - so it fires even while your
main code is busy in a long blocking call.

Takes the same arguments as C<set_interrupt()> (C<$debounce_us> optional), all
validated before forking. Because the callback runs in a separate process it
B<cannot> see or change your main program's variables; use it for independent
handlers (drive a pin, log, notify).

Returns a handle:

    my $h = $pin->background_interrupt(EDGE_RISING, \&handler);

    $h->stop;        # Stop + reap the background handler (idempotent)
    $h->pid;         # The child PID
    $h->running;     # True while the child is alive

A handle going out of scope stops its child, and a forgotten C<stop> is reaped
at program exit.

An optional trailing options hash reference is forwarded to L<WiringPi::API>;
C<< { results => 1 } >> ships the handler's defined return value back to the
parent, drained with C<< $h->read >> (and C<< $h->fh >> for C<select>):

    my $h = $pin->background_interrupt(
        EDGE_RISING,
        sub { return "hit" },
        { results => 1 }
    );

    while (defined(my $msg = $h->read)) { print "$msg\n" }

=head2 set_interrupt($edge, $callback, $debounce_us, \%opts)

Listen for an interrupt on a pin, and do something if it is triggered.

Interrupts are armed on the pin but driven through the Pi object. For the
per-method reference see L<RPi::WiringPi/"INTERRUPT METHODS">, and for full
runnable examples - driving dispatch, auto-dispatch, the background results
channel and teardown - see L<RPi::WiringPi::INTERRUPTS>.

Parameters:

    $edge

Mandatory: C<1> for C<EDGE_FALLING>, C<2> for C<EDGE_RISING>, or C<3> for
C<EDGE_BOTH>.

    $callback

Mandatory: a code reference (eg: C<\&my_handler> or C<sub {...}>) to run when
the interrupt fires. The callback receives C<($edge, $timestamp_us)>.

B<Note:> as of C<WiringPi::API> 3.18 the interrupt is dispatched in Perl rather
than from the wiringPi ISR thread, so the callback B<must> be a code reference;
a string sub name is no longer accepted. The callback also only runs when your
program services the interrupt file descriptor, so you must drive dispatch (eg.
C<< $pi->wait_interrupts($timeout_ms) >> in a loop, or
C<< $pi->dispatch_interrupts >>).

    $debounce_us

Optional: debounce window in microseconds. Edges arriving within this window of
the previous accepted edge are ignored. Defaults to C<0> (no debounce).

    \%opts

Optional: a trailing options hash reference, forwarded to L<WiringPi::API>. The
C<auto_dispatch> option turns on auto-dispatch as part of arming so the callback
fires without your own dispatch loop (process-wide; see
C<< $pi->auto_dispatch_interrupts >>):

    $pin->set_interrupt(EDGE_RISING, \&handler, { auto_dispatch => 1 });

    # Or choose the delivery signal:

    $pin->set_interrupt(EDGE_RISING, \&handler, { auto_dispatch => 'USR1' });

C<1> uses the default C<SIGIO>; a signal name (eg C<'USR1'>) delivers via that
signal instead, avoiding clashes with other C<SIGIO> users in your program.

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

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
