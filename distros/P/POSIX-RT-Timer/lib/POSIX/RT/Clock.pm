package POSIX::RT::Clock;
$POSIX::RT::Clock::VERSION = '0.021';
use 5.008;

use strict;
use warnings FATAL => 'all';

use POSIX::RT::Timer;

1;    # End of POSIX::RT::Clock

#ABSTRACT: POSIX real-time clocks

__END__

=pod

=encoding UTF-8

=head1 NAME

POSIX::RT::Clock - POSIX real-time clocks

=head1 VERSION

version 0.021

=head1 SYNOPSIS

 use POSIX::RT::Timer;

 my $timer = POSIX::RT::Clock->new('monotonic');
 $timer->sleep(1);

=head1 DESCRIPTION

POSIX::RT::Clock offers access to various clocks, both portable and OS dependent.

=head1 METHODS

=head2 Class methods

=over 4

=item * new($type)

Create a new clock. The C<$type>s supported are documented in C<get_clocks>.

=item * get_clocks()

Get a list of all supported clocks. These will be returned by their names, not as objects. Possible values include (but may not be limited to):

=over 4

=item * realtime 

The same clock as C<time> and L<Time::HiRes> use. It is the only timer guaranteed to always available and is therefor the default.

=item * monotonic

A non-settable clock guaranteed to be monotonic. This is defined in POSIX and supported on most operating systems.

=item * process

A clock that measures (user and system) CPU time consumed by (all of the threads in) the calling process. This is supported on many operating systems.

=item * thread

A clock that measures (user and system) CPU time consumed by the calling thread. This is Linux specific.

=item * uptime

A clock that measures the uptime of the system. This is FreeBSD specific.

=item * virtual

A clock that counts time the process spent in userspace. This is supported only in FreeBSD, NetBSD and Solaris.

=back

=item * get_cpuclock($id = 0)

Get the cpu-time clock for C<$id>. If C<$id> is an integer, it's interpreted as a PID and a per process clock is created, with zero having the special meaning of the current process (this is the same as the C<process> clock). If C<$id> is a C<thread> object, a per thread clock is created. This call is currently not supported on many operating systems.

=back

=head2 Instance methods

=over 4

=item * get_time()

Get the time of this clock.

=item * set_time($time)

Set the time of this clock. Note that this may not make sense on clocks other than C<realtime> and will require sysadmin permissions.

=item * get_resolution()

Get the resolution of this clock.

=item * sleep($time, $abstime = 0)

Sleep a C<$time> seconds on this clock. Note that it is B<never> restarted after interruption by a signal handler. It returns the remaining time. $time and the return value are relative time unless C<$abstime> is true. This function may not be available on some operating systems.

=item * sleep_deeply($time, $abstime = 0)

Sleep a C<$time> seconds on this clock. Unlike C<sleep>, it will retry on interruption until the time has passed. This function may not be available on some operating systems.

=item * timer(%options)

Create a timer based on this clock. All arguments except C<clock> as the same as in C<POSIX::RT::Timer::new>.

=item * handle

This returns the raw handle to the clock.

=back

=head1 SEE ALSO

A low-level interface to POSIX clocks is also provided by:

=over 4

=item * Time::HiRes

=item * POSIX::2008

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
