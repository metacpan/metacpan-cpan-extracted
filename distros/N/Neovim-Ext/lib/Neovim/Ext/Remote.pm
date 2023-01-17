package Neovim::Ext::Remote;
$Neovim::Ext::Remote::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use overload
	'==' => sub { $_[0]->{code_data} == $_[1]->{code_data} },
	fallback => 1,
;
use Carp qw/croak/;
use MsgPack::Raw;

__PACKAGE__->mk_accessors (qw/session handle code_data api_prefix api vars options/);


sub new
{
	my ($this, $session, $api_prefix, $code_data) = @_;

	my $unpacker = MsgPack::Raw::Unpacker->new;
	$unpacker->feed ($code_data->{data});

	my $class = ref ($this) || $this;
	my $self =
	{
		session => $session,
		api_prefix => $api_prefix,
		code_data => $code_data,
		handle => $unpacker->next,
	};

	my $obj = bless $self, $class;
	$obj->api (Neovim::Ext::RemoteApi->new ($self, $api_prefix));
	$obj->vars (Neovim::Ext::RemoteMap->new ($self, $api_prefix.'get_var',
		$api_prefix.'set_var', $api_prefix.'del_var'));
	$obj->options (Neovim::Ext::RemoteMap->new ($self, $api_prefix.'get_option',
		$api_prefix.'set_option'));
	return $obj;
}



sub request
{
	my ($this, $name, @args) = @_;
	$this->session->request ($name, $this, @args);
}


=head1 NAME

Neovim::Ext::Remote - Neovim Remote class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 request( $name, @args )

Wrapper around C<$nvim>'s C<$request>.

=cut

1;
