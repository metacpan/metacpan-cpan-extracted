package PLP::Tie::Delay;

use strict;
no strict 'refs';
use warnings;

our $VERSION = '1.00';

=head1 PLP::Tie::Delay

Delays hash generation. Unties the hash on first access, and replaces it by the generated one.
Uses symbolic references, because circular ties make Perl go nuts :)

    tie %Some::hash, 'PLP::Tie::Delay', 'Some::hash', sub { \%generated_hash };

This module is part of the PLP internals and probably not of any use to others.

=cut

sub _replace {
	my ($self) = @_;
	untie %{ $self->[0] };

	# I'd like to use *{ $self->[0] } = $self->[1]->(); here,
	# but that causes all sorts of problems. The hash is accessible from
	# within this sub, but not where its creation was triggered.
	# Immediately after the triggering statement, the hash becomes available
	# to all: even the scope where the previous access attempt failed.
	
	%{ $self->[0] } = %{ $self->[1]->() }
}

sub TIEHASH {
	# my ($class, $hash, $source) = @_;
	return bless [ @_[1, 2] ], $_[0];
}

sub FETCH {
	my ($self, $key) = @_;
	$self->_replace;
	return $self->[0]->{$key};
}

sub STORE {
	my ($self, $key, $value) = @_;
	$self->_replace;
	return $self->[0]->{$key} = $value;
}

sub DELETE {
	my ($self, $key) = @_;
	$self->_replace;
	return delete $self->[0]->{$key};
}

sub CLEAR {
	my ($self) = @_;
	$self->_replace;
	return %{ $self->[0] };
}

sub EXISTS {
	my ($self, $key) = @_;
	$self->_replace;
	return exists $self->[0]->{$key};
}

sub FIRSTKEY {
	my ($self) = @_;
	$self->_replace;
	return 'PLPdummy';
}

sub NEXTKEY {
	# Let's hope this never happens. (It's shouldn't.)
	return undef;
}

sub UNTIE   { }

sub DESTROY { } 

1;

