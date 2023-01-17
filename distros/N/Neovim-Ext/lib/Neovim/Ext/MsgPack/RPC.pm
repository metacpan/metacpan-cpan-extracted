package Neovim::Ext::MsgPack::RPC;
$Neovim::Ext::MsgPack::RPC::VERSION = '0.06';
use strict;
use warnings;
use Neovim::Ext::MsgPack::RPC::EventLoop;
use Neovim::Ext::MsgPack::RPC::Stream;
use Neovim::Ext::MsgPack::RPC::AsyncSession;
use Neovim::Ext::MsgPack::RPC::Session;


sub tcp_session
{
	_session ('tcp', @_);
}



sub stdio_session
{
	_session ('stdio', @_);
}



sub socket_session
{
	_session ('socket', @_);
}



sub child_session
{
	_session ('child', @_);
}



sub _session
{
	my $transport_type = shift;
	my $loop = Neovim::Ext::MsgPack::RPC::EventLoop->new ($transport_type, @_);
	my $stream = Neovim::Ext::MsgPack::RPC::Stream->new ($loop);
	my $async_session = Neovim::Ext::MsgPack::RPC::AsyncSession->new ($stream);

	my $session = Neovim::Ext::MsgPack::RPC::Session->new ($async_session);
	$session->request ('nvim_set_client_info',
		'perl-client', {}, 'remote', {},
		{
			license => 'perl5',
			website => 'https://github.com/jacquesg/p5-Neovim',
		},
		async_ => 1
	);

	return $session;
}

=head1 NAME

Neovim::Ext::MsgPack::RPC - Neovim MessagePack RPC class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 FUNCTIONS

=head2 tcp_session( $address, $port )

Create a msgpack-rpc session from a tcp address/port.

=head2 socket_session( $path )

Create a msgpack-rpc session from a unix domain socket.

=head2 stdio_session( )

Create a msgpack-rpc session from stdin/stdout.

=head2 child_session( $argv )

Create a msgpack-rpc session from a new Nvim instance.

=cut

1;
