package Neovim::Ext::MsgPack::RPC::AsyncSession;
$Neovim::Ext::MsgPack::RPC::AsyncSession::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Carp qw/croak/;
use Neovim::Ext::MsgPack::RPC::Response;
__PACKAGE__->mk_accessors (qw/loop msgpack_stream next_request_id pending_requests
	request_cb notification_cb handlers/);


sub new
{
	my ($this, $msgpack_stream) = @_;

	croak "msgpack_stream not provided" if (!$msgpack_stream);

	my $class = ref ($this) || $this;
	my $self =
	{
		msgpack_stream   => $msgpack_stream,
		next_request_id  => 1,
		pending_requests => {},
		loop             => $msgpack_stream->loop,
	};

	return bless $self, $class;
}



sub request
{
	my ($this, $method, $args, $response_cb) = @_;

	my $request_id = $this->next_request_id;
	$this->next_request_id ($request_id+1);
	$this->msgpack_stream->send ([0, $request_id, $method, $args // []]);
	$this->pending_requests->{$request_id} = $response_cb;
}



sub create_future
{
	my $this = shift;
	$this->msgpack_stream->create_future();;
}



sub notify
{
	my ($this, $method, $args) = @_;
	$this->msgpack_stream->send ([2, $method, $args // []]);
}



sub run
{
	my ($this, $request_cb, $notification_cb, $setup_cb) = @_;

	$this->request_cb ($request_cb);
	$this->notification_cb ($notification_cb);
	$this->msgpack_stream->run (sub
		{
			$this->_on_message (@_);
		},
		$setup_cb
	);
}



sub stop
{
	my ($this) = @_;
	$this->msgpack_stream->stop();
}



sub close
{
	my ($this) = @_;
	$this->msgpack_stream->close();
}



sub await
{
	my ($this, $future) = @_;
	$this->msgpack_stream->await ($future);
}



sub _on_message
{
	my ($this, $msg) = @_;

	my %handlers =
	(
		0 => sub
		{
			$this->_on_request (@_);
		},
		1 => sub
		{
			$this->_on_response (@_);
		},
		2 => sub
		{
			$this->_on_notification (@_);
		},
	);

	&{$handlers{$msg->[0]}}($msg);
}



sub _on_request
{
	my ($this, $msg) = @_;

	my $response = Neovim::Ext::MsgPack::RPC::Response->new ($this->msgpack_stream, $msg->[1]);
	$this->request_cb->($msg->[2], $msg->[3], $response);
}



sub _on_response
{
	my ($this, $msg) = @_;

	my $cb = delete $this->pending_requests->{$msg->[1]};
	$cb->($msg->[2], $msg->[3]);
}



sub _on_notification
{
	my ($this, $msg) = @_;
	$this->notification_cb->($msg->[1], $msg->[2]);
}

=head1 NAME

Neovim::Ext::MsgPack::RPC::AsyncSession - Neovim::Ext::MsgPack::RPC::AsyncSession class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 new( $msgpack_stream )

Create a new C<Neovim::Ext::MsgPack::RPC::AsyncSession>.

=head2 request( $method, $args, \&response_cb )

Send a msgpack-rpc request to Nvim. C<$response_cb> is called when the response is
available.

=head2 notify( $method, $args )

Send a msgpack-rpc notification to Nvim. This has the same effect as a request, but no
response will be received.

=head2 run( \&request_cb, \&notification_cb )

Run the event loop to receive requests and notifications from Nvim. While the event
loop is running, C<\&request_cb> and C<\&notification_cb> will be called whenever
requests or notifications are received.

=head2 stop( )

Stop the event loop.

=head2 close( )

Close the event loop.

=head2 create_future( )

Create a future.

=head2 await( $future )

Wait for C<$future> to complete.

=cut

1;
