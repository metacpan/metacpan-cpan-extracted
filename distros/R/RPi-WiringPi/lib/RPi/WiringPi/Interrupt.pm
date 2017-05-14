package RPi::WiringPi::Interrupt;

use strict;
use warnings;

use parent 'WiringPi::API';
use parent 'RPi::WiringPi::Util';

use Config;
use RPi::WiringPi::Constant qw(:all);

our $VERSION = '2.3613';

my $interrupts = {};

sub new {
    return bless {}, shift;
}
sub set {
    my ($self, $pin, $edge, $callback) = @_;
    $interrupts->{$pin}{edge} = $edge;
    $self->set_interrupt($pin, $edge, $callback);
}

sub _vim{1;};
1;
__END__

=head1 NAME

RPi::WiringPi::Interrupt - Raspberry Pi GPIO pin interrupts

=head1 SYNOPSIS

    use RPi::WiringPi::Interrupt;
    use RPi::WiringPi::Constant qw(:all);

    my $int = RPi::WiringPi::Interrupt->new;

    my $pin = 6;

    $int->set($pin, EDGE_RISING, 'interrupt_handler');

    sub interrupt_handler {
        print "in handler";
        # turn a pin on, or do other things
    }

=head1 DESCRIPTION

This module allows you to set up GPIO pin edge detection interrupts where you
can supply the name of a Perl subroutine that you write that will act as the
interrupt handler.

The Interrupt Service Routine (ISR) is written in C and runs in a separate
thread, so it doesn't block the main program thread from running while waiting
for the interrupt to occur.

=head1 METHODS

=head2 new()

Returns a new C<RPi::WiringPi::Interrupt> object.

=head2 set($pin, $edge, $callback)

Starts a new thread that waits for an interrupt on the specified pin, when the
selected edge is triggered. The name of the Perl subroutine in C<$callback>
will be the code executed as the interrupt handler.

Parameters:

    $pin

Mandatory: The pin number to set the interrupt on. We'll convert the pin number
appropriately regardless of which pin mapping you're currently using.

    $edge

Mandatory: One of C<1> for C<EDGE_FALLING>, C<2> for C<EDGE_RISING> or C<3> for
C<EDGE_BOTH>.

    $callback

Mandatory: This is a string containing the name of a user-written Perl
subroutine that contains the code you want to execute when the edge change is
detected on the pin. (ie. the Interrupt Handler).

=head1 SEE ALSO

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
