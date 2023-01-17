package Neovim::Ext::Buffers;
$Neovim::Ext::Buffers::VERSION = '0.06';
use strict;
use warnings;
use Class::Accessor;
use Tie::Array;

our @ISA = (qw/Class::Accessor Tie::Array/);

__PACKAGE__->mk_accessors (qw/nvim/);


sub TIEARRAY
{
	my ($this, $nvim) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
	};

	return bless $self, $class;
}



sub new
{
	my $this = shift;

	tie my @array, 'Neovim::Ext::Buffers', @_;

	return \@array;
}



sub _fetch_buffers
{
	my ($this) = @_;
	return $this->nvim->api->list_bufs();
}



sub FETCHSIZE
{
	my ($this) = @_;
	return scalar (@{$this->_fetch_buffers});
}



sub FETCH
{
	my ($this, $number) = @_;

	return @{$this->_fetch_buffers}[$number];

}



sub get_bynumber
{
	my ($this, $number) = @_;

	foreach my $buffer (@{$this->_fetch_buffers})
	{
		if (tied (@{$buffer})->number == $number)
		{
			return $buffer;
		}
	}

	return undef;
}


=head1 NAME

Neovim::Ext::Buffers - Neovim Buffers class

=head1 VERSION

version 0.06

=head1 SYNPOSIS

	use Neovim::Ext;

	my $buffers = $nvim->buffers();

	my $count = scalar (@{$buffers}); # buffer count
	$buffers->[0];                    # first buffer
	$buffers->[-1];                   # last buffer

=head1 DESCRIPTION

Remote Nvim buffers.

=head1 METHODS

=head2 get_bynumber( $number )

Retrieve the C<Neovim::Ext::Buffer> matching the buffer C<$number>. C<$number>
is the actual buffer number, and NOT the index in this list.

=cut

1;
