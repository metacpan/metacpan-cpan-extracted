package Neovim::Ext::RemoteMap;
$Neovim::Ext::RemoteMap::VERSION = '0.06';
use strict;
use warnings;
use Carp qw/croak/;
use Class::Accessor;
use Tie::Hash;

our @ISA = (qw/Class::Accessor Tie::Hash/);
__PACKAGE__->mk_accessors (qw/nvim get_method set_method del_method/);


sub TIEHASH
{
	my ($this, $nvim, $get_method, $set_method, $del_method) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		get_method => $get_method,
		set_method => $set_method,
		del_method => $del_method,
	};

	return bless $self, $class;
}



sub STORE
{
	my ($this, $key, $value) = @_;

	croak "not available" if (!$this->set_method);
	$this->nvim->request ($this->set_method, $key, $value);
}



sub FETCH
{
	my ($this, $key) = @_;
	$this->nvim->request ($this->get_method, $key);
}



sub DELETE
{
	my ($this, $key) = @_;

	croak "not available" if (!$this->del_method);
	my $value = $this->FETCH ($key);
	$this->nvim->request ($this->del_method, $key);
	return $value;
}



sub EXISTS
{
	my ($this, $key) = @_;

	my $result = eval { $this->nvim->request ($this->get_method, $key); };
	return !!$result;
}



sub new
{
	my $this = shift;

	tie my %hash, 'Neovim::Ext::RemoteMap', @_;

	return \%hash;
}



sub fetch
{
	my ($this, $key, $default) = @_;

	return eval { $this->nvim->request ($this->get_method, $key) } // $default;
}


=head1 NAME

Neovim::Ext::RemoteMap - Neovim RemoteMap class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 new( $nvim, $get_method, [$set_method, $del_method])

=head2 fetch( $key, $default )

Return C<$key> if present, otherwise C<$default>.

=cut

1;
