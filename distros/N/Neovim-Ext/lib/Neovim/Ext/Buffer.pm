package Neovim::Ext::Buffer;
$Neovim::Ext::Buffer::VERSION = '0.06';
use strict;
use warnings;
use Tie::Array;
use Neovim::Ext::Remote;
use Neovim::Ext::Range;

our @ISA = (qw/Neovim::Ext::Remote Tie::Array/);


sub TIEARRAY
{
	my ($this, $session, $code_data) = @_;

	return $this->SUPER::new ($session, 'nvim_buf_', $code_data);
}


sub new
{
	my $this = shift;

	tie my @array, 'Neovim::Ext::Buffer', @_;

	return \@array;
}



sub FETCHSIZE
{
	my ($this) = @_;
	return $this->request ('nvim_buf_line_count');
}



sub FETCH
{
	my ($this, $index) = @_;
	my $result = $this->request ('nvim_buf_get_lines', $index, $index+1, 0);
	return shift @$result // '';
}



sub STORE
{
	my ($this, $index, $value) = @_;
	$this->request ('nvim_buf_set_lines', $index, $index+1, 0, defined ($value) ? ["$value"] : []);
}



sub SPLICE
{
	my ($this, $offset, $length, @list) = @_;

	$offset //= 0;
	$length //= $this->request ('nvim_buf_line_count');
	$this->request ('nvim_buf_set_lines', $offset, $offset+$length, 0, [map { "$_" } @list]);
}



sub STORESIZE
{
	my ($this, $count) = @_;

AGAIN:
	my $size = $this->FETCHSIZE();
	if ($count < $size)
	{
		$this->STORE ($size-1, undef);
		goto AGAIN;
	}
}



sub DELETE
{
	my ($this, $index) = @_;
	$this->STORE ($index, undef);
}



sub CLEAR
{
	my ($this) = @_;

	my $size = $this->FETCHSIZE();
	$this->request ('nvim_buf_set_lines', 0, $size, 0, []);
}



sub number
{
	my $this = shift;
	return $this->handle;
}



sub name
{
	my $this = shift;

	$this->request ('nvim_buf_set_name', shift) if (@_);
	$this->request ('nvim_buf_get_name') // '';
}



sub valid
{
	my $this = shift;
	$this->request ('nvim_buf_is_valid');
}



sub mark
{
	my ($this, $name) = @_;
	$this->request ('nvim_buf_get_mark', $name);
}




sub range
{
	my ($this, $start, $end) = @_;
	return Neovim::Ext::Range->new ($this, $start, $end);
}


=head1 NAME

Neovim::Ext::Buffer - Neovim Buffer class

=head1 VERSION

version 0.06

=head1 SYNPOSIS

	use Neovim::Ext;

	my $buffer = $nvim->current->buffer;

	push @$buffer, 'line'; # add a new line to the buffer
	@$buffer = ();         # delete all buffer lines

	# check if the buffer is valid
	if (tied (@{$buffer})->valid)
	{
		...
	}

=head1 DESCRIPTION

A remote Nvim buffer. A C<Neovim::Ext::Buffer> instance is a tied array reference.

=head1 METHODS

=head2 mark( $name )

Return the row and column for a named mark.

=head2 range( $start, $end )

Return a C<Neovim::Ext::Range> which represents part of the buffer.

=head2 name( [$name] )

Get or set buffer name.

=head2 number( )

Get the buffer number.

=head2 valid( )

Check if the buffer still exists.

=cut

1;
