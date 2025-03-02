package Signal::Info;
$Signal::Info::VERSION = '0.006';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
# @EXPORT_OK is filled in XS

1;

# ABSTRACT: A wrapper around siginfo_t

__END__

=pod

=encoding UTF-8

=head1 NAME

Signal::Info - A wrapper around siginfo_t

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This class represents a POSIX C<siginfo_t> structure. It is typically not created by an end-user, but returned by (XS) modules.

=head1 METHODS

=head2 new

This creates a new (empty) siginfo object.

=head2 signo

The signal number.

=head2 code

The signal code.

=head2 errno

If non-zero, an errno value associated with this signal.

=head2 pid

Sending process ID.

=head2 uid

Real user ID of sending process.

=head2 status

Exit value or signal.

=head2 band

Band event for SIGPOLL.

=head2 value

Signal integer value.

=head2 ptr

Signal pointer value (as an unsigned)

=head2 addr

Address of faulting instruction.

=head2 fd

File descriptor associated with the signal. This may not be available everywhere.

=head2 timerid

Timer ID of POSIX real-time timers. This may not be available everywhere.

=head2 overrun

Timer overrun count of POSIX real-time timers. This may not be available everywhere.

=head1 CODE FLAGS

The following constants are defined for the C<code> field, all having their L<POSIX|https://pubs.opengroup.org/onlinepubs/009695399/basedefs/signal.h.html> meanings. Some may not be defined on all platforms.

=over 4

=item * C<ILL_ILLOPC>

=item * C<ILL_ILLOPN>

=item * C<ILL_ILLADR>

=item * C<ILL_ILLTRP>

=item * C<ILL_PRVOPC>

=item * C<ILL_PRVREG>

=item * C<ILL_COPROC>

=item * C<ILL_BADSTK>

=item * C<FPE_INTDIV>

=item * C<FPE_INTOVF>

=item * C<FPE_FLTDIV>

=item * C<FPE_FLTOVF>

=item * C<FPE_FLTUND>

=item * C<FPE_FLTRES>

=item * C<FPE_FLTINV>

=item * C<FPE_FLTSUB>

=item * C<SEGV_MAPERR>

=item * C<SEGV_ACCERR>

=item * C<BUS_ADRALN>

=item * C<BUS_ADRERR>

=item * C<BUS_OBJERR>

=item * C<TRAP_BRKPT> (conditionally defined)

=item * C<TRAP_TRACE> (conditionally defined)

=item * C<CLD_EXITED>

=item * C<CLD_KILLED>

=item * C<CLD_DUMPED>

=item * C<CLD_TRAPPED>

=item * C<CLD_STOPPED>

=item * C<CLD_CONTINUED>

=item * C<POLL_IN> (conditionally defined)

=item * C<POLL_OUT> (conditionally defined)

=item * C<POLL_MSG> (conditionally defined)

=item * C<POLL_ERR> (conditionally defined)

=item * C<POLL_PRI> (conditionally defined)

=item * C<POLL_HUP> (conditionally defined)

=item * C<SI_USER>

=item * C<SI_QUEUE>

=item * C<SI_TIMER>

=item * C<SI_ASYNCIO> (conditionally defined)

=item * C<SI_MESGQ> (conditionally defined)

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
