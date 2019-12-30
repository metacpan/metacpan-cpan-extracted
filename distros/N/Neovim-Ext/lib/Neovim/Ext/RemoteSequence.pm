package Neovim::Ext::RemoteSequence;
$Neovim::Ext::RemoteSequence::VERSION = '0.02';
use strict;
use warnings;
use Class::Accessor;
use Tie::Array;

our @ISA = (qw/Class::Accessor Tie::Array/);

__PACKAGE__->mk_accessors (qw/nvim method/);


sub TIEARRAY
{
	my ($this, $nvim, $method) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		method => $method,
	};

	return bless $self, $class;
}



sub _fetch
{
	my $this = shift;
	$this->nvim->request ($this->method, @_);
}



sub FETCH
{
	my ($this, $index) = @_;
	return $this->_fetch->[$index];
}



sub FETCHSIZE
{
	my ($this) = @_;
	return scalar (@{$this->_fetch});
}



sub new
{
	my $this = shift;

	tie my @array, 'Neovim::Ext::RemoteSequence', @_;

	return \@array;
}


=head1 NAME

Neovim::Ext::RemoteSequence - Neovim RemoteSequence class

=head1 VERSION

version 0.02

=head1 SYNOPSIS

	use Neovim::Ext;

=cut

1;
