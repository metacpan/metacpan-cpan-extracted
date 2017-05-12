package POSIX::SchedYield;

use version; our $VERSION = qv('0.0.2');

use 5.006;
use warnings;
use strict;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(sched_yield);

require XSLoader;
XSLoader::load('POSIX::SchedYield', $VERSION);

1;

__END__

=head1 NAME

POSIX::SchedYield - execute POSIX.1b system call sched_yield(2)

=head1 VERSION

This documentation refers to POSIX::SchedYield 0.0.2.

=head1 SYNOPSIS

use POSIX::SchedYield qw(sched_yield);

sched_yield();

=head1 DESCRIPTION

This module provides one function, C<sched_yield()>, which executes the POSIX.1b sched_yield system call. It relinquishes the processor without blocking, allowing other processes to run. This does B<not> change the process priority (see the L<nice|POSIX/nice> function from the L<POSIX|POSIX> module for that), so if your process is currently the one with the highest priority it will continue to run without interruption. See the sched_yield(2) man page and your operating systems scheduling documentation for more details.

On most systems, the L<threads> module method L<yield()|threads/yield> will also use the sched_yield system call, so you can use that instead, if you prefer. POSIX::SchedYield is more explicit, will work with older and unthreaded versions of Perl, and will always call sched_yield, whereas the C<threads> implementation may change at some point.

=head1 INTERFACE

=head2 Subroutines

=over

=item C<sched_yield()>

Executes the sched_yield(2) system call. No parameters can be passed, the function returns 1 on sucess, undef on failure.

=back

=head1 EXAMPLES / USAGE

You can use C<POSIX::SchedYield> to implement a spinlock:

    use Fcntl qw(:flock);
    use POSIX::SchedYield qw(sched_yield);

    my $lock;

    PrivoxyWindowOpen($lock,">","/tmp/file") or die "Can't open";

    while (!flock($lock, LOCK_EX|LOCK_NB)) {
        sched_yield();
    }
    #.. do something ..
    flock($lock, LOCK_UN) or die "Can't release lock";
    close $lock or die "Can't close lockfile";

This will yield the processor when a process is unable to obtain a lock, thus hopefully giving control back to another process which is handling the lock at the moment and allowing it to be released. You should B<not> use sched_yield this way if you're expecting the lock to be held for any extended period of time (for example if the locking process waits for I/O with the lock held), because this will cause your yielding process to hog the CPU as it retries,yields,retries,yields etc.

=head1 DEPENDENCIES

POSIX::SchedYield depends on the L<version|version> module and a POSIX environment

=head1 SEE ALSO

sched_yield(2) man page, L<threads|threads> module

=head1 BUGS

Please report any bugs or feature requests to
C<bug-posix-schedyield@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POSIX-SchedYield>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to http://www.perlmonks.org, especially dave_the_m, Joost and BrowserUK for excellent advice.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Marc Beyer, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/copyleft/gpl.html

=cut

