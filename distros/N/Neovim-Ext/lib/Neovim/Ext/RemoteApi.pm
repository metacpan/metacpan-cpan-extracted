package Neovim::Ext::RemoteApi;
$Neovim::Ext::RemoteApi::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors (qw/nvim prefix/);


sub new
{
	my ($this, $nvim, $prefix) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		prefix => $prefix,
	};

	return bless $self, $class;
}



sub DESTROY
{
}


our $AUTOLOAD;

sub AUTOLOAD
{
	my $methodName;
	($methodName = $AUTOLOAD) =~ s/.*:://;

	# Install
	no strict 'refs';
	*{$AUTOLOAD} = sub
	{
		my $this = shift;
		$this->nvim->request ($this->prefix.$methodName, @_);
	};

	goto &$AUTOLOAD;
}

=head1 NAME

Neovim::Ext::RemoteApi - Neovim RemoteApi class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=cut

1;
