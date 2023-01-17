package Neovim::Ext::RemoteSequence;
$Neovim::Ext::RemoteSequence::VERSION = '0.06';
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



sub new
{
	my $this = shift;

	tie my @array, 'Neovim::Ext::RemoteSequence', @_;

	return \@array;
}



sub _fetch
{
	my $this = shift;
	return $this->nvim->request ($this->method, @_);
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



sub get_bynumber
{
	my ($this, $number) = @_;

	foreach my $buffer (@{$this->_fetch})
	{
		if (tied (@{$buffer})->number == $number)
		{
			return $buffer;
		}
	}

	return undef;
}


=head1 NAME

Neovim::Ext::RemoteSequence - Neovim RemoteSequence class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 get_bynumber( $number )

Retrieve the matching window/tab for C<$number>. C<$number>
is the actual window/tab number, and NOT the index in this list.

=cut

1;
