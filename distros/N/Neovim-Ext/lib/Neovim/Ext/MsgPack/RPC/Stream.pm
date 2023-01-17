package Neovim::Ext::MsgPack::RPC::Stream;
$Neovim::Ext::MsgPack::RPC::Stream::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use MsgPack::Raw;
__PACKAGE__->mk_accessors (qw/loop packer unpacker message_cb/);


sub new
{
	my ($this, $loop) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		loop => $loop,
		packer => MsgPack::Raw::Packer->new(),
		unpacker => MsgPack::Raw::Unpacker->new(),
	};

	return bless $self, $class;
}



sub run
{
	my ($this, $message_cb, $setup_cb) = @_;
	$this->message_cb ($message_cb);

	$this->loop->run (sub
		{
			$this->_on_data (@_);
		}, $setup_cb
	);
}



sub stop
{
	my ($this) = @_;
	$this->loop->stop();
}



sub close
{
	my ($this) = @_;
	$this->loop->close();
}



sub send
{
	my ($this, $msg) = @_;
	$this->loop->send ($this->packer->pack ($msg));
}



sub create_future
{
	my ($this) = @_;
	return $this->loop->create_future();
}



sub await
{
	my ($this, $future) = @_;
	$this->loop->await ($future);
}



sub _on_data
{
	my ($this, $data) = @_;

	$this->unpacker->feed ($data);

AGAIN:
	my $result = $this->unpacker->next;
	if ($result)
	{
		$this->message_cb->($result);
		goto AGAIN;
	}
}

=head1 NAME

Neovim::Ext::MsgPack::RPC::Stream - Neovim::Ext::MsgPack::RPC::Stream class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 run( \&message_cb )

Run the event loop to receive messages from Nvim. While the event
loop is running, C<\&message_cb> will be called whenever a message
is received.

=head2 stop( )

Stop the event loop.

=head2 send( $msg )

Queue C<$msg> for sending to Nvim.

=head2 close( )

Close the event loop.

=head2 create_future( )

Create a future.

=head2 await( $future )

Wait for C<$future> to complete.

=cut

1;
