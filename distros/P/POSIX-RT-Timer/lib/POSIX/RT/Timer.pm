package POSIX::RT::Timer;
$POSIX::RT::Timer::VERSION = '0.021';
use 5.008001;

use strict;
use warnings FATAL => 'all';

use XSLoader ();

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;    # End of POSIX::RT::Timer

#ABSTRACT: POSIX real-time timers

__END__

=pod

=encoding UTF-8

=head1 NAME

POSIX::RT::Timer - POSIX real-time timers

=head1 VERSION

version 0.021

=head1 SYNOPSIS

 use POSIX::RT::Timer;

 my $timer = POSIX::RT::Timer->new(value => 1, signal => $signo, id => 42);

=head1 DESCRIPTION

This module provides for POSIX Real-Time timers. There timers send a signal to the process much like getitimer/setitimer but have various improvements:

=over 4

=item * An arbitrary number of timers is supported.

=item * Delivery to any signal is allowed, though using L<realtime signals|POSIX::RT::Signal> is recommended.

=item * Time measurement on a variety of clocks is supported.

=back

=head1 METHODS

=head2 Class methods

=over 4

=item * new(%options)

Create a new timer. Options include

=over 4

=item * value = 0

The time in factional seconds for timer expiration. If it is 0 the timer is disarmed.

=item * interval = 0

The value the timer is set to after expiration. If this is set to 0, it is a one-shot timer.

=item * clock = 'realtime'

The type of clock. This must either be the stringname of a supported clock or a L<POSIX::RT::Clock|POSIX::RT::Clock> object.

=item * signal

The signal number to send a signal to on timer expiration.

=item * id

An integer identifier added to the signal. Do note that perl's default signal handling throws away this information. You'll have to use either unsafe signals, with a risk of crashing your program, or a synchronous signal receiving mechanism (such as L<POSIX::RT::Signal|POSIX::RT::Signal> or L<Linux::FD::Signal|Linux::FD::Signal>), which may ruin your reason for using timers. YMMV.

=back

=back

=head2 Instance methods

=over 4

=item * get_timeout()

Get the timeout value. In list context, it also returns the interval value. Note that this value is always relative to the current time.

=item * set_timeout($value, $interval = 0, $abstime = 0)

Set the timer and interval values. If C<$abstime> is true, they are absolute values, otherwise they are relative to the current time. Returns the old value like C<get_time> does.

=item * get_overrun()

Get the overrun count for the timer. The timer overrun count is the number of additional timer expirations that occurred since the signal was sent.

=item * handle

This returns the raw handle to the timer.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
