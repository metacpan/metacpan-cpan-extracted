package Neovim::Ext::VIMCompat::Buffer;
$Neovim::Ext::VIMCompat::Buffer::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors (qw/buffer/);


sub new
{
	my ($this, $buffer) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		buffer => $buffer,
	};

	return bless $self, $class;
}



sub Name
{
	my ($this) = @_;

	my $name = tied (@{$this->buffer})->name;
	if ($name)
	{
		my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;
		return $vim->eval ('bufname ("'.$name.'")');
	}

	return $name;
}



sub Number
{
	my ($this) = @_;
	return tied (@{$this->buffer})->number;
}



sub Count
{
	my ($this) = @_;
	return scalar (@{$this->buffer});
}



sub Get
{
	my ($this, @lineNumbers) = @_;

	my @result;
	foreach my $lineNumber (@lineNumbers)
	{
		my $line = $this->buffer->[$lineNumber-1];
		push @result, $line if defined ($line);
	}

	if (scalar (@lineNumbers) == 1)
	{
		return shift @result;
	}

	return @result;
}



sub Delete
{
	my ($this, $start, $end) = @_;

	if (defined ($end) && $end > $start)
	{
		splice (@{$this->buffer}, $start-1, $end-1);
	}
	else
	{
		delete $this->buffer->[$start-1];
	}
}



sub Append
{
	my ($this, $start, @lines) = @_;

	if (scalar (@lines) == 1 && ref ($lines[0]) eq 'ARRAY')
	{
		@lines = @{$lines[0]};
	}

	if (scalar (@lines))
	{
		splice (@{$this->buffer}, $start, 0, @lines);
	}
}



sub Set
{
	my ($this, $start, @lines) = @_;

	if (scalar (@lines))
	{
		my $count = $this->Count();
		while (($start + scalar (@lines) - 1) > $count)
		{
			pop @lines;
		}

		splice (@{$this->buffer}, $start-1, scalar (@lines), @lines);
	}
}

=head1 NAME

Neovim::Ext::VIMCompat::Buffer - Neovim legacy VIM perl compatibility layer

=head1 VERSION

version 0.06

=head1 SYNPOSIS

	use Neovim::Ext;

=head1 DESCRIPTION

A compatibility layer for the legacy VIM perl interface.

=head1 METHODS

=head2 Name( )

Get the buffer name.

=head2 Number( )

Get the buffer number.

=head2 Count( )

Get the number of lines in the buffer.

=head2 Get( @lineNumbers )

Get the lines represented by C<@lineNumbers>.

=head2 Delete( $start, [$end] )

Delete line C<$start> in the buffer. If C<$end> is specified, the range C<$start>
to C<$end> will be deleted.

=head2 Append( $start, @lines )

Appends each line in C<@lines> after C<$start>.

=head2 Set( $start, @lines )

Replaces C<@lines> starting at C<$start>.

=cut

1;
