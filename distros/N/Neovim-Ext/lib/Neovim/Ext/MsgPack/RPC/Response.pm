package Neovim::Ext::MsgPack::RPC::Response;
$Neovim::Ext::MsgPack::RPC::Response::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors (qw/msgpack_stream request_id/);


sub new
{
	my ($this, $msgpack_stream, $request_id) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		msgpack_stream => $msgpack_stream,
		request_id => $request_id,
	};

	return bless $self, $class;
}



sub send
{
	my ($this, $value, $error) = @_;

	if ($error)
	{
		$this->msgpack_stream->send ([1, $this->request_id, $value, undef]);
	}
	else
	{
		$this->msgpack_stream->send ([1, $this->request_id, undef, $value]);
	}
}

=head1 NAME

Neovim::Ext::MsgPack::RPC::Response - Neovim::Ext::MsgPack::RPC::Response class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 send( $value, $error)

Send the response. If C<$error> is true, the response will be sent as an error.

=cut

1;
