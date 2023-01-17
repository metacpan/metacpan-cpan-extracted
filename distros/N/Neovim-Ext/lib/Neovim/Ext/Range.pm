package Neovim::Ext::Range;
$Neovim::Ext::Range::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor Tie::Array/;

__PACKAGE__->mk_accessors (qw/buffer start end/);


sub TIEARRAY
{
	my ($this, $buffer, $start, $end) = @_;

	my $class = 'Neovim::Ext::Range';
	my $self =
	{
		buffer => $buffer,
		start => $start - 1,
		end => $end - 1,
	};

	return bless $self, $class;
}



sub new
{
	my $this = shift;

	tie my @array, 'Neovim::Ext::Range', @_;

	return \@array;
}



sub FETCHSIZE
{
	my ($this) = @_;
	return $this->end - $this->start + 1;
}



sub FETCH
{
	my ($this, $index) = @_;
	$index = $this->_normalise_index ($index);
	return $this->buffer->FETCH ($index);
}



sub STORE
{
	my ($this, $index, $value) = @_;
	$index = $this->_normalise_index ($index);
	$this->buffer->STORE ($index, $value);
}



sub DELETE
{
	my ($this, $index) = @_;
	$this->STORE ($index, undef);
}



sub _normalise_index
{
	my ($this, $index) = @_;

	return undef if (!defined ($index));
	return $this->end if ($index < 0);

	$index += $this->start;
	$index = $this->end if ($index > $this->end);
	return $index;
}

=head1 NAME

Neovim::Ext::Range - Neovim Buffer range class

=head1 VERSION

version 0.06

=head1 SYNPOSIS

	use Neovim::Ext;

=head1 DESCRIPTION

A buffer range for a C<Neovim::Ext::Buffer>.

=cut

1;
