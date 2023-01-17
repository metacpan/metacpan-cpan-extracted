package Neovim::Ext::MsgPack::RPC::Session;
$Neovim::Ext::MsgPack::RPC::Session::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;
__PACKAGE__->mk_accessors (qw/async_session is_running pending_messages request_cb notification_cb/);


sub new
{
	my ($this, $async_session) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		async_session => $async_session,
		pending_messages => [],
	};

	return bless $self, $class;
}



sub next_message
{
	my ($this) = @_;

	croak "event loop is already running" if ($this->is_running);

	my $session = $this;
	weaken ($session);

	if (scalar (@{$session->pending_messages}))
	{
		return shift @{$session->pending_messages};
	}

	$this->async_session->run (sub { $session->_enqueue_request_and_stop (@_) },
		sub { $session->_enqueue_notification_and_stop (@_) });

	return shift @{$session->pending_messages};
}



sub request
{
	my ($this, $method, @args) = @_;

	my $async = 0;

	my @filtered;
	while (@args)
	{
		my $value = shift @args;
		if ($value && $value eq 'async_')
		{
			$async = !!shift @args;
			next;
		}

		push @filtered, $value;
	}

	@args = @filtered;

	if ($async)
	{
		$this->async_session->notify ($method, \@args);
		return
	}


	my $is_running = !!$this->is_running;

	my $result = [];

	my $future = $this->async_session->create_future();
	$this->async_session->request ($method, \@args, sub
		{
			my ($err, $rv) = @_;

			push @{$result}, $err, $rv;
			if ($is_running)
			{
				$future->done();
			}
			else
			{
				$this->async_session->stop();
			}
		}
	);

	if ($is_running)
	{
		$this->async_session->await ($future);
	}
	else
	{
		my $session = $this;
		weaken ($session);

		$this->async_session->run (sub { $session->_enqueue_request (@_) },
			sub { $session->_enqueue_notification (@_) });
	}

	my $error = shift @$result;
	if ($error)
	{
		die $error->[1];
	}

	return $result->[0];
}



sub run
{
	my ($this, $request_cb, $notification_cb, $setup_cb) = @_;

	$this->request_cb ($request_cb);
	$this->notification_cb ($notification_cb);

	my $session = $this;
	weaken ($session);

	my $init = sub
	{
		$setup_cb->() if ($setup_cb);

		while (scalar (@{$session->pending_messages}))
		{
			my $msg = shift @{$session->pending_messages};

			my $type = shift @$msg;
			if ($type eq 'request')
			{
				$session->_on_request (@$msg);
			}
			elsif ($type eq 'notification')
			{
				$session->_on_notification (@$msg);
			}
		}
	};

	$this->is_running (1);

	$this->async_session->run (sub { $session->_on_request (@_) }, sub { $session->_on_notification (@_) }, $init);

	$this->is_running (0);
}



sub stop
{
	my ($this) = @_;
	$this->async_session->stop();
}



sub close
{
	my ($this) = @_;
	$this->async_session->close();
}



sub _on_request
{
	my ($this, $name, $args, $response) = @_;

	eval
	{
		my $rv = $this->request_cb->($name, $args);
		$response->send ($rv);
	};

	if ($@)
	{
		if (ref ($@) && ref ($@) eq 'Neovim::Ext::ErrorResponse')
		{
			my $e = $@;
			$response->send ($e->{msg}, 1);
		}
		else
		{
			$response->send ("Unhandled exception: $@", 1);
		}
	}
}



sub _on_notification
{
	my ($this, $name, $args) = @_;
	$this->notification_cb->($name, $args);
}



sub _enqueue_request
{
	my ($this, $name, $args, $response) = @_;
	push @{$this->pending_messages}, ['request', $name, $args, $response];
}



sub _enqueue_request_and_stop
{
	my $this = shift;
	$this->_enqueue_request (@_);
	$this->stop();
}



sub _enqueue_notification
{
	my ($this, $name, $args) = @_;
	push @{$this->pending_messages}, ['notification', $name, $args];
}



sub _enqueue_notification_and_stop
{
	my $this = shift;
	$this->_enqueue_notification (@_);
	$this->stop();
}

=head1 NAME

Neovim::Ext::MsgPack::RPC::Session - Neovim::Ext::MsgPack::RPC::Session class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 run( $request_cb, $notification_cb, [$setup_cb] )

Run the event loop to receive requests and notifications from Neovim.

=head2 stop( )

Stop the event loop.

=head2 request( $method, @args )

Send a msgpack-rpc request and block until a response is received. If C<async_>
is set in C<@args>, an asynchronous notification is sent instead, and this method
doesn't block or return the value or error result.

=head2 next_message( )

Block until a message (request or notification) is available. If messages were
previously stored, the first one in the list will be returned, otherwise, run
the event loop until a message becomes available.

=head2 close( )

Close the event loop.

=cut

1;
