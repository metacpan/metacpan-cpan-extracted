package Signal::Mask;
$Signal::Mask::VERSION = '0.008';
use strict;
use warnings FATAL => 'all';

use Config;
use POSIX qw/SIG_BLOCK SIG_UNBLOCK SIG_SETMASK/;
BEGIN {
	if (eval { require Thread::SigMask }) {
		*sigmask = \&Thread::SigMask::sigmask;
	}
	else {
		require POSIX;
		*sigmask = \&POSIX::sigprocmask;
	}
}
use IPC::Signal qw/sig_num sig_name/;
use Carp qw/croak/;

my $sig_max = $Config{sig_count} - 1;

tie %Signal::Mask, __PACKAGE__;

sub TIEHASH {
	my $class = shift;
	my $self = { iterator => 1, };
	return bless $self, $class;
}

sub _get_status {
	my ($self, $num) = @_;
	my $mask = POSIX::SigSet->new;
	sigmask(SIG_BLOCK, POSIX::SigSet->new(), $mask);
	return $mask->ismember($num);
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->_get_status(sig_num($key));
}

my $block_signal = sub {
	my ($self, $key) = @_;
	my $num = sig_num($key);
	croak "No such signal '$key'" if not defined $num;
	sigmask(SIG_BLOCK, POSIX::SigSet->new($num)) or croak "Couldn't block signal: $!";
	return;
};

my $unblock_signal = sub {
	my ($self, $key) = @_;
	my $num = sig_num($key);
	croak "No such signal '$key'" if not defined $num;
	my $ret = POSIX::SigSet->new($num);
	sigmask(SIG_UNBLOCK, POSIX::SigSet->new($num), $ret) or croak "Couldn't unblock signal: $!";
	return $ret->ismember($num);
};

sub STORE {
	my ($self, $key, $value) = @_;
	my $method = $value ? $block_signal : $unblock_signal;
	$self->$method($key);
	return;
}

sub DELETE {
	my ($self, $key) = @_;
	return $self->$unblock_signal($key);
}

sub CLEAR {
	my ($self) = @_;
	sigmask(SIG_SETMASK, POSIX::SigSet->new());
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
	my $self = shift;
	my $mask = POSIX::SigSet->new;
	sigmask(SIG_BLOCK, POSIX::SigSet->new(), $mask);
	return scalar grep { $mask->ismember($_) } 1 .. $sig_max;
}

sub UNTIE {
	my $self = shift;
	$self->CLEAR;
	return;
}

sub DESTROY {
}

1;    # End of Signal::Mask

# ABSTRACT: Signal masks made easy

__END__

=pod

=encoding UTF-8

=head1 NAME

Signal::Mask - Signal masks made easy

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use Signal::Mask;
 
 {
     local $Signal::Mask{INT} = 1;
     do_something();
 }
 #signal delivery gets postponed until now

=head1 DESCRIPTION

Signal::Mask is an abstraction around your process or thread signal mask. It is used to fetch and/or change the signal mask of the calling process or thread. The signal mask is the set of signals whose delivery is currently blocked for the caller. It is available as the global hash %Signal::Mask.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
