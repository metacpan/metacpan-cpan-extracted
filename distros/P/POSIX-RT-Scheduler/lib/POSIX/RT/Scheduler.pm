package POSIX::RT::Scheduler;
{
  $POSIX::RT::Scheduler::VERSION = '0.003';
}
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: POSIX Scheduler support functions



=pod

=head1 NAME

POSIX::RT::Scheduler - POSIX Scheduler support functions

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 sched_setscheduler($pid, 'rr', 10);

=head1 DESCRIPTION

This module allows one to set the scheduler and the scheduler priority of processes. 

The following scheduler policies are supported:

=over 4

=item * C<other>

This is the default non-real-time scheduler. It doesn't have a real-time priority

=item * C<fifo>

This is a real-time scheduler.  A fifo scheduled process runs until either it is blocked by an I/O request, it is preempted by a higher priority process, or it calls C<sched_yield>.

=item * C<rr>

Round-robin scheduling. This is similar to fifo scheduling, except that after a specified amount of time the thread will be 

=item * C<batch>

A Linux specific scheduler, useful for keeping CPU-intensive processes at normal priority without sacrificing interactivity.

=item * C<idle>

A Linux specific scheduler that causes a process to be scheduled only when there's no other (non-idle scheduled) process available for running.

=back

=head1 FUNCTIONS

=head2 sched_getscheduler($pid)

Get the scheduler for C<$pid>.

=head2 sched_setscheduler($pid, $policy, $priority = 0)

Set the scheduler for C<$pid> to C<$policy>, with priority C<$priority> if applicable. C<$priority> must be within the inclusive priority range for the scheduling policy specified by policy. If C<$pid> is zero, the current process is retrieved

=head2 sched_getpriority($pid)

Return the real-time priority of C<$pid> as an integer value.

=head2 sched_setpriority($pid, $priority)

Set the real-time priority of C<$pid> to C<$priority>.

=head2 sched_priority_range($policy)

This function returns the (inclusive) minimal and maximal values allowed for C<$policy>.

=head2 sched_yield()

Yield execution to the next waiting process or thread. Note that if the current process/thread is the highest priority runnable real-time scheduled process/thread available, this will be a no-op.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

