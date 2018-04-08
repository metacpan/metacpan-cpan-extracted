package PLP::Tie::Delay;

use strict;
no strict 'refs';
use warnings;

our $VERSION = '1.01';

=head1 PLP::Tie::Delay

Delays hash generation. Unties the hash on first access, and replaces it by the generated one.
Uses symbolic references, because circular ties make Perl go nuts :)

    tie %Some::hash, 'PLP::Tie::Delay', 'Some::hash', sub { \%generated_hash };

This module is part of the PLP internals and probably not of any use to others.

=cut

sub _replace {
	my ($self) = @_;

	if ($] >= 5.018) {
		my $code = delete $self->[1] or return;
		$self->[0] = $code->();
		return 1;
	}

	untie %{ $self->[0] };
	%{ $self->[0] } = %{ $self->[1]->() };  # *{ $self->[0] } = $self->[1]->();
	return;
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
	$self->_replace and return 'PLPdummy';
	return each %{$self->[0]};
}

sub NEXTKEY {
	return each %{$_[0]->[0]};
}

sub UNTIE   { }

sub DESTROY { } 

1;

