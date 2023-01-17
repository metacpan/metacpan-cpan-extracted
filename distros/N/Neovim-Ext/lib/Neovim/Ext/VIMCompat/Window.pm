package Neovim::Ext::VIMCompat::Window;
$Neovim::Ext::VIMCompat::Window::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Neovim::Ext::VIMCompat::Buffer;

__PACKAGE__->mk_accessors (qw/window/);


sub new
{
	my ($this, $window) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		window => $window,
	};

	return bless $self, $class;
}



sub SetHeight
{
	my ($this, $height) = @_;
	$this->window->height ($height);
}



sub Buffer
{
	my ($this) = @_;
	return Neovim::Ext::VIMCompat::Buffer->new ($this->window->buffer);
}



sub Cursor
{
	my ($this, $row, $col) = @_;

	if (defined ($row) || defined ($col))
	{
		$this->window->cursor ([$row, $col]);
	}

	return @{$this->window->cursor};
}

=head1 NAME

Neovim::Ext::VIMCompat::Windo - Neovim legacy VIM perl compatibility layer

=head1 VERSION

version 0.06

=head1 SYNPOSIS

	use Neovim::Ext;

=head1 DESCRIPTION

A compatibility layer for the legacy VIM perl interface.

=head1 METHODS

=head2 SetHeight( $height )

Set the window height to C<$height>, within the screen limits.

=head2 Buffer( )

Get the C<Neovim::Ext::VIMCompat::Buffer> associated with the window.

=head2 Cursor( [$row, $col] )

Get or set the current cursor position for the window.

=cut

1;
