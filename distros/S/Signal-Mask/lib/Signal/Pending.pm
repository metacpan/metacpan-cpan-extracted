package Signal::Pending;
$Signal::Pending::VERSION = '0.008';
use strict;
use warnings FATAL => 'all';

use Config;
use POSIX qw/sigpending/;
use IPC::Signal qw/sig_num sig_name/;
use Carp qw/croak/;

my $sig_max = $Config{sig_count} - 1;

tie %Signal::Pending, __PACKAGE__;

sub TIEHASH {
	my $class = shift;
	my $self = { iterator => 1, };
	return bless $self, $class;
}

sub _get_status {
	my ($self, $num) = @_;
	my $mask = POSIX::SigSet->new;
	sigpending($mask);
	return $mask->ismember($num);
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->_get_status(sig_num($key));
}

sub STORE {
	my ($self, $key, $value) = @_;
	croak 'Can\'t assign to %Signal::Pending';
}

sub DELETE {
	my ($self, $key) = @_;
	croak 'Can\'t delete from %Signal::Pending';
}

sub CLEAR {
	my ($self) = @_;
	croak 'Can\'t clear %Signal::Pending';
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
	sigpending($mask);
	return scalar grep { $mask->ismember($_) } 1 .. $sig_max;
}

sub UNTIE {
}

sub DESTROY {
}

1;    # End of Signal::Mask

# ABSTRACT: Signal pending status made easy

__END__

=pod

=encoding UTF-8

=head1 NAME

Signal::Pending - Signal pending status made easy

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use Signal::Mask;
 use Signal::Pending;
 
 {
     local $Signal::Mask{INT} = 1;
     do {
		 something();
     } while (not $Signal::Pending{INT})
 }
 #signal delivery gets postponed until now

=head1 DESCRIPTION

Signal::Pending is an abstraction around your process'/thread's pending signals. It can be used in combination with signal masks to handle signals in a controlled manner. The set of pending signals is available as the global hash %Signal::Pending.

=for Pod::Coverage SCALAR

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
