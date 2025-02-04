package POSIX::RT::Signal;
$POSIX::RT::Signal::VERSION = '0.018';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/sigwaitinfo sigtimedwait sigwait sigqueue allocate_signal deallocate_signal/;
our %EXPORT_TAGS = (all => \@EXPORT);

use Carp qw/croak/;
use POSIX qw//;
use XSLoader;
use Signal::Info;
use threads::shared;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

my @signals : shared = (defined &POSIX::SIGRTMIN) ?  (POSIX::SIGRTMIN() .. POSIX::SIGRTMAX()) : (POSIX::SIGUSR1(), POSIX::SIGUSR2());

my %allowed = map { ( $_ => 1 ) } @signals;

sub allocate_signal {
	my ($priority) = @_;
	return +($priority ? shift @signals : pop @signals) || croak 'no more signal numbers available';
}

sub deallocate_signal {
	my ($signal) = @_;
	croak 'Signal not from original set' if not $allowed{$signal};
	@signals = sort { $a <=> $b } @signals, $signal;
	return;
}

1;

#ABSTRACT: POSIX Real-time signal handling functions

__END__

=pod

=encoding UTF-8

=head1 NAME

POSIX::RT::Signal - POSIX Real-time signal handling functions

=head1 VERSION

version 0.018

=head1 SYNOPSIS

 use POSIX::RT::Signal qw/sigqueue sigwaitinfo/;
 use Signal::Mask;
 
 $Signal::Mask{USR1}++;
 sigqueue($$, 'USR1');
 my $info = sigwaitinfo('USR1');

=head1 DESCRIPTION

This module exposes several advanced features and interfaces of POSIX real-time signals.

=head1 FUNCTIONS

=head2 sigqueue($pid, $sig, $value = 0)

Queue a signal $sig to process C<$pid>, optionally with the additional argument C<$value>. On error an exception is thrown. C<$sig> must be either a signal number(C<14>) or a signal name (C<'ALRM'>). If the signal queue is full, it returns undef and sets C<$!> to EAGAIN.

=head2 sigwaitinfo($signals)

Wait for a signal in C<$signals> to arrive and return information on it as a L<Signal::Info> object. The signal handler (if any) will not be called. Unlike signal handlers it is not affected by signal masks, in fact you are expected to mask signals you're waiting for. C<$signals> must either be a POSIX::SigSet object, a signal number or a signal name. On error it returns an C<undef> and C<$!> should be consulted.

=head2 sigtimedwait($signals, $timeout)

This is like C<sigwaitinfo>, except it has an additional timeout that indicates the maximal time the thread is suspended in fractional seconds; if no signal is received C<$!> will be C<EAGAIN>. Otherwise it behaves exactly the same as C<sigwaitinfo>.

=head2 sigwait($signals)

Wait for a signal in $signals to arrive and return it. The signal handler (if any) will not be called. Unlike signal handlers it is not affected by signal masks, in fact you are expected to mask signals you're waiting for. C<$signals> must either be a POSIX::SigSet object, a signal number or a signal name.

=head2 allocate_signal($priority)

Pick a signal from the set of signals available to the user. The signal will not be given to any other caller of this function until it has been deallocated. If supported, these will be real-time signals. By default it will choose the lowest priority signal available, but if C<$priority> is true it will pick the highest priority one. If real-time signals are not supported this will return C<SIGUSR1> and C<SIGUSR2>

=head2 deallocate_signal($signal)

Deallocate the signal to be reused for C<allocate_signal>.

=head1 SEE ALSO

=over 4

=item * L<Signal::Mask|Signal::Mask>

An easy interface to signal masks

=item * L<IPC::Signal|IPC::Signal>

Utility functions dealing with signals

=item * L<POSIX::RT::Timer|POSIX::RT::Timer>

POSIX real-time timers. These will produce signals on timeout.

=item * L<Linux::FD::Signal|Linux::FD::Signal>

Linux signal file descriptors. This is an alternative interface to signals that allows for polling alongside

=item * L<POSIX|POSIX>

This core module contains various used in dealing with signals.

=back

=for Pod::Coverage sigwait
=end

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
