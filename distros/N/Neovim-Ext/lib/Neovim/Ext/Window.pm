package Neovim::Ext::Window;
$Neovim::Ext::Window::VERSION = '0.06';
use strict;
use warnings;
use Carp qw/croak/;
use base qw/Neovim::Ext::Remote/;


sub new
{
	my ($this, $session, $code_data) = @_;

	return $this->SUPER::new ($session, 'nvim_win_', $code_data);
}



sub buffer
{
	my $this = shift;
	$this->request ('nvim_win_get_buf');
}



sub cursor
{
	my $this = shift;

	$this->request ('nvim_win_set_cursor', @_) if (@_);
	$this->request ('nvim_win_get_cursor');
}



sub height
{
	my $this = shift;

	$this->request ('nvim_win_set_height', @_) if (@_);
	$this->request ('nvim_win_get_height');
}



sub width
{
	my $this = shift;

	$this->request ('nvim_win_set_width', @_) if (@_);
	$this->request ('nvim_win_get_width');
}



sub row
{
	my $this = shift;
	$this->request ('nvim_win_get_position')->[0];
}



sub col
{
	my $this = shift;
	$this->request ('nvim_win_get_position')->[1];
}



sub tabpage
{
	my $this = shift;
	$this->request ('nvim_win_get_tabpage');
}



sub valid
{
	my $this = shift;
	$this->request ('nvim_win_is_valid');
}



sub number
{
	my $this = shift;
	$this->request ('nvim_win_get_number');
}


=head1 NAME

Neovim::Ext::Window - Neovim Window class

=head1 VERSION

version 0.06

=head2 SYNOPSIS

	use Neovim::Ext;

=head2 METHODS

=head2 buffer( )

Get the buffer currently displayed by the window

=head2 tabpage( )

Get the tabpage that contains the window.

=head2 row( )

Get the 0-indexed on-screen window row position in display cells.

=head2 col( )

Get the 0-indexed on-screen window column position in display cells.

=head2 cursor( [$row, $col] )

Get or set the row and column of the cursor.

=head2 height( [$height] )

Get or set the window height (in rows).

=head2 width( [$width] )

Get or set the window width (in columns).

=head2 number( )

Get the window number.

=head2 valid( )

Check if the window still exists.

=cut

1;
