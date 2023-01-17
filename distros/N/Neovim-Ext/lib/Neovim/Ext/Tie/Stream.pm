package Neovim::Ext::Tie::Stream;
$Neovim::Ext::Tie::Stream::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors (qw/callback/);


sub TIEHANDLE
{
	my ($class, $callback) = @_;

	my $self =
	{
		callback => $callback,
	};

	return bless $self, $class;
}

sub PRINT
{
	my ($this, @list) = @_;

	$this->callback->(join ("", (@list)));

	return 1;
}

sub PRINTF
{
	&PRINT ($_[0], sprintf ($_[1], @_[2..$#_]))
}

# unused
sub READ {}
sub BINMODE {}
sub READLINE {}
sub GETC {}
sub WRITE {}
sub FILENO {}
sub CLOSE {}

=head1 NAME

Neovim::Ext::Tie::Stream - Tie STDOUT/STDERR

=head1 VERSION

version 0.06

=cut

1;
