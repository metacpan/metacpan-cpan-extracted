package Proc::Wait3;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw(wait3);
our $VERSION = '0.05';

bootstrap Proc::Wait3 $VERSION;

1;
__END__

=head1 NAME

Proc::Wait3 - Perl extension for wait3 system call

=head1 SYNOPSIS

  use Proc::Wait3;

  ($pid, $status, $utime, $stime, $maxrss, $ixrss, $idrss, $isrss,
  $minflt, $majflt, $nswap, $inblock, $oublock, $msgsnd, $msgrcv,
  $nsignals, $nvcsw, $nivcsw) = wait3(0); # doesn't wait

  ($pid, $status, $utime, $stime, $maxrss, $ixrss, $idrss, $isrss,
  $minflt, $majflt, $nswap, $inblock, $oublock, $msgsnd, $msgrcv,
  $nsignals, $nvcsw, $nivcsw) = wait3(1); # waits for a child

=head1 DESCRIPTION

If any child processes have exited, this call will "reap" the zombies
similar to the perl "wait" function.

By default, it will return immediately and if there are no dead
children, everything will be undefined.  If you pass in a true
argument, it will block until a child exits (or it gets a signal).

 $pid         PID of exiting child

 $status      exit status of child, just like C<$?>

 $utime       floating point user cpu seconds

 $stime       floating point system cpu seconds

 $maxrss      the maximum resident set size utilized (in kilobytes).

 $minflt      the number of page faults serviced without any I/O
              activity; here I/O activity is avoided by "reclaiming" a
              page frame from the list of pages awaiting reallocation.

 $majflt      the number of page faults serviced that required I/O
              activity.

 $nswap       the number of times a process was "swapped" out of main
              memory.

 $inblock     the number of times the file system had to perform input.

 $oublock     the number of times the file system had to perform output.

 $msgsnd      the number of messages sent over sockets.

 $msgrcv      the number of messages received from sockets.

 $nsignals    the number of signals delivered.

 $nvcsw       the number of times a context switch resulted due to a
              process voluntarily giving up the processor before its
              time slice was completed (usually to await availability of
              a resource).

 $nivcsw      the number of times a context switch resulted due to a
              higher priority process becoming runnable or because the
              current process exceeded its time slice.

=head1 AUTHOR

C. Tilmes E<lt>curt@tilmes.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<perl>, L<wait3>, L<getrusage>.

=cut
