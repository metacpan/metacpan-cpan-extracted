package Neovim::Ext::Current;
$Neovim::Ext::Current::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Neovim::Ext::Plugin::Host;
use Neovim::Ext::RemoteApi;
use Neovim::Ext::RemoteMap;
use Neovim::Ext::RemoteSequence;

__PACKAGE__->mk_accessors (qw/session range/);

my %fields;


sub new
{
	my ($this, $session) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		session => $session,
	};

	return bless $self, $class;
}



sub line
{
	my $self = shift;

	if (@_)
	{
		my $line = shift;
		defined ($line) ?
			$self->session->request ('nvim_set_current_line', $line) :
			$self->session->request ('nvim_del_current_line');
	}

	return $self->session->request ('nvim_get_current_line') // '';
}



sub buffer
{
	my $self = shift;

	if (@_)
	{
		$self->session->request ('nvim_set_current_buf', shift);
	}

	return $self->session->request ('nvim_get_current_buf');
}



sub window
{
	my $self = shift;

	if (@_)
	{
		$self->session->request ('nvim_set_current_win', shift);
	}

	return $self->session->request ('nvim_get_current_win');
}



sub tabpage
{
	my $self = shift;

	if (@_)
	{
		$self->session->request ('nvim_set_current_tabpage', shift);
	}

	return $self->session->request ('nvim_get_current_tabpage');
}


=head1 NAME

Neovim::Ext::Current - Neovim Current class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 line( [$line] )

Get or set the current line.

=head2 buffer( [$buffer] )

Get or set the current buffer.

=head2 window( [$window] )

Get or set the current window.

=head2 tabpage( [$tabpage] )

Get or set the current tabpage.

=cut

1;
