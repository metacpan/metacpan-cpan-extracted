package Signal::Unsafe;
$Signal::Unsafe::VERSION = '0.006';
use strict;
use warnings FATAL => 'all';

use XSLoader;
XSLoader::load(__PACKAGE__, Signal::Unsafe->VERSION);

use Exporter 5.57 'import';
our @EXPORT_OK = qw/sigaction/;

use Config;
use IPC::Signal qw/sig_num sig_name/;
use List::Util 'reduce';
use POSIX qw/SA_SIGINFO/;

{
	no warnings 'once';
	tie %Signal::Unsafe, __PACKAGE__;
}
our $Flags = SA_SIGINFO;
our $Mask  = POSIX::SigSet->new;

my $sig_max = $Config{sig_count} - 1;

sub TIEHASH {
	my $class = shift;
	my $self = { iterator => 1, };
	return bless $self, $class;
}

sub _get_status {
	my ($self, $num) = @_;
	my $ret = POSIX::SigAction->new;
	sigaction($num, undef, $ret);
	return [ $ret->handler, $ret->flags, $ret->mask ];
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->_get_status(sig_num($key));
}

my %flag_values = (
	siginfo   => POSIX::SA_SIGINFO,
	nodefer   => POSIX::SA_NODEFER,
	restart   => POSIX::SA_RESTART,
	onstack   => POSIX::SA_ONSTACK,
	resethand => POSIX::SA_RESETHAND,
	nocldstop => POSIX::SA_NOCLDSTOP,
	nocldwait => POSIX::SA_NOCLDWAIT,
);

sub get_args {
	my $value = shift;
	if (ref $value eq 'ARRAY') {
		my ($handler, $flags, $mask) = @{$value};
		$mask = $Mask if not defined $mask;
		$flags = not defined $flags ? $Flags : ref($flags) ne 'ARRAY' ? $flags : reduce { $a | $b } map { $flag_values{$_} } @{$flags};
		return ($handler, $mask, $flags);
	}
	else {
		return ($value, $Flags, $Mask);
	}
}

sub STORE {
	my ($self, $key, $value) = @_;
	my ($handler, $flags, $mask) = get_args($value);
	sigaction(sig_num($key), POSIX::SigAction->new($handler, $mask, $flags));
	return;
}

sub DELETE {
	my ($self, $key) = @_;
	my $old = POSIX::SigAction->new("DEFAULT", $Mask, $Flags);
	sigaction(sig_num($key), POSIX::SigAction->new("DEFAULT", $Mask, $Flags), $old);
	return ($old->handler, $old->mask, $old->flags);
}

sub CLEAR {
	my ($self) = @_;
	for my $sig_no (1 .. $sig_max) {
		sigaction($sig_no, POSIX::SigAction->new("DEFAULT", $Mask, $Flags));
	}
	return;
}

sub EXISTS {
	my ($self, $key) = @_;
	return defined sig_num($key);
}

sub FIRSTKEY {
	my $self = shift;
	$self->{iterator} = 1;
	return $self->NEXTKEY;
}

sub NEXTKEY {
	my $self = shift;
	if ($self->{iterator} <= $sig_max) {
		my $num = $self->{iterator}++;
		return wantarray ? (sig_name($num) => $self->_get_status($num)) : sig_name($num);
	}
	else {
		return;
	}
}

sub SCALAR {
	return 1;
}

sub UNTIE {
	my $self = shift;
	$self->CLEAR;
	return;
}

sub DESTROY {
}

1;

#ABSTRACT: Unsafe signal handlers made convenient

__END__

=pod

=encoding UTF-8

=head1 NAME

Signal::Unsafe - Unsafe signal handlers made convenient

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 $Signal::Mask{USR1} = 1;
 $Signal::Unsafe{USR1} = sub {
     my ($signo, $args, $binary) = @_;
     die "Process $args->{int} has run too long";
 }

 for my $pid (@pids) {
	 my $clock = POSIX::RT::Clock->get_cpuclock($pid);
	 push @timers, POSIX::RT::Timer->new(clock => $clock, value => 180, id => $pid);
 }
 $ppoll = IO::PPoll->new();
 $ppoll->mask(\*STDIN, POLLIN);
 # SIGUSR1 may be received during the ppoll, but not outside of it
 $ppoll->poll;

=head1 DESCRIPTION

This module provides a single global hash that, much like C<%SIG>, allows one to set signal handlers. Unlike C<%SIG>, it will set "unsafe" ones. You're expected to provide your own safety, for example by masking and then selectively unmasking it as in the synopsis.

=head1 VARIABLES

=over 4

=item * %Signal::Unsafe

This hash contains handlers for signals. It accepts various values:

=over 4

=item * If a code-reference is written to it, it will accept use that as handler conjoint with the default C<$Flags> and C<$Mask>.

=item * If an array-reference is written to is, it will accept that as a tuple of C<$handler>, C<$flags> and C<$mask>. Handler must be a coderef. C<$flags> must be either an integer value (a bitmask of C<POSIX::SA_*> values, or an array-reference containing some of the following entries:

=over 4

=item * siginfo

=item * nodefer

=item * restart

=item * onstack

=item * resethand

=item * nocldstop

=item * nocldwait

=back

=item * If an undefined value is written to it, the handler is reset to default.

=back

=item * $Signal::Unsafe::Flags

This contains the default flags. Its initial value is C<POSIX:SA_SIGINFO>

=item * $Signal::Unsafe::Mask

This contains the default mask. Its initial value is an empty mask.

=back

=head1 SIGNAL HANDLER

The signal handler will be called as soon as the signal is dispatched to the process/thread, without any userland delay. If the C<SA_SIGINFO> flag is set (which is highly recommended), the handler will not receive one but three argument.

=over 4

=item * The signal number

This is simple the number of the signal

=item * The signal information hash

This is a hash containing the following entries:

=over 4

=item * signo

=item * code

=item * errno

=item * pid

=item * uid

=item * status

=item * utime

=item * stime

=item * int

=item * ptr

=item * overrun

=item * timerid

=item * addr

=item * band

=item * fd

=back

Most values are not meaningful for most signal events.

=item * The signal information as a binary blob

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
