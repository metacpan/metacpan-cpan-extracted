package Neovim::Ext::MsgPack::RPC::EventLoop;
$Neovim::Ext::MsgPack::RPC::EventLoop::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Scalar::Util qw/weaken/;
use IPC::Open3 qw/open3/;
use IO::Handle;
use IO::Async::Loop;
use IO::Async::Signal;
use IO::Async::Stream;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Time::HiRes qw/usleep/;
use Socket qw/SOCK_STREAM/;
__PACKAGE__->mk_accessors (qw/loop stream data_cb _transport_type _can_close _pid signals/);


sub new
{
	my $this = shift;
	my $transport_type = shift;

	my $class = ref ($this) || $this;
	my $self =
	{
		loop => IO::Async::Loop->new,
		signals => [],
		_transport_type => $transport_type,
	};

	my $obj = bless $self, $class;
	if ($transport_type eq 'stdio')
	{
		$obj->connect_stdio (@_);
	}
	elsif ($transport_type eq 'tcp')
	{
		$obj->connect_tcp (@_);
	}
	elsif ($transport_type eq 'socket')
	{
		$obj->connect_socket (@_);
	}
	elsif ($transport_type eq 'child')
	{
		$obj->connect_child (@_);
	}
	else
	{
		die "Unsupported transport type: $transport_type\n";
	}

	return $obj;
}



sub DESTROY
{
	my ($this) = @_;

	if ($this->_pid)
	{
		waitpid ($this->_pid, 0);
	}
}



sub connect_stdio
{
	my ($this) = @_;

	binmode STDIN;
	binmode STDOUT;

	STDIN->blocking (0);
	STDOUT->blocking (0);

	$this->_create_stream (read_handle  => \*STDIN, write_handle => \*STDOUT);
}



sub connect_tcp
{
	my ($this, $address, $port, $retries, $retryInterval) = @_;

	$retries //= 0;
	$retryInterval //= 100;

AGAIN:
	my $socket = IO::Socket::INET->new
	(
		PeerAddr => $address,
		PeerPort => $port,
		Proto    => 'tcp',
		Type     => SOCK_STREAM
	);

	if (!$socket)
	{
		if ($retries == 0)
		{
			die "Couldn't connect to $address:$port: $!\n";
		}

		--$retries;
		usleep ($retryInterval*1000);
		goto AGAIN;
	}

	$socket->blocking (0);

	$this->_create_stream (handle => $socket);
	$this->_can_close (1);
}



sub connect_socket
{
	my ($this, $path, $retries, $retryInterval) = @_;

	$retries //= 0;
	$retryInterval //= 100;

AGAIN:
	my $socket = IO::Socket::UNIX->new
	(
		Type => SOCK_STREAM,
		Peer => $path,
	);

	if (!$socket)
	{
		if ($retries == 0)
		{
			die "Couldn't connect to $path: $!\n";
		}

		--$retries;
		usleep ($retryInterval*1000);
		goto AGAIN;
	}

	$socket->blocking (0);

	$this->_create_stream (handle => $socket);
	$this->_can_close (1);
}



sub connect_child
{
	my ($this, $argv) = @_;

	if ($^O eq 'MSWin32')
	{
		die "Not supported!";
	}

	$this->_pid (open3 (\*CHILD_IN, \*CHILD_OUT, \*ERR, @$argv));

	CHILD_IN->blocking (0);
	CHILD_OUT->blocking (0);

	$this->_create_stream (read_handle => \*CHILD_OUT, write_handle => \*CHILD_IN);
	$this->_can_close (1);
}



sub _create_stream
{
	my ($this, %options) = @_;

	$this->stream (IO::Async::Stream->new
		(
			%options,
			read_all => 1,
			autoflush => 1,
			close_on_read_eof => 1,
			on_read => $this->_on_read(),
			on_read_error => $this->_on_read_error(),
			on_read_eof => $this->_on_read_eof(),
		)
	);

	$this->loop->add ($this->stream);
}



sub _on_read
{
	my ($this) = @_;

	my $loop = $this;
	weaken ($loop);

	return sub
	{
		my ($self, $buffref, $eof) = @_;

		# Consume all the data
		my $data = $$buffref;
		$$buffref = '';

		$loop->data_cb->($data);

		return 0;
	};
}



sub _on_read_error
{
	my ($this) = @_;

	my $loop = $this;
	weaken ($loop);

	return sub
	{
		my (undef, $error) = @_;
		$loop->stop();
		die "handle read error: $error\n";
	};
}



sub _on_read_eof
{
	my ($this) = @_;

	my $loop = $this;
	weaken ($loop);

	return sub
	{
		$loop->stop();
		die "handle read eof\n";
	};
}



sub _on_signal
{
	my ($this) = @_;

	my $loop = $this;
	weaken ($loop);

	return sub
	{
		my ($signal) = @_;

		if ($loop->_transport_type eq 'stdio' && $signal eq 'INT')
		{
			# Probably running as a nvim child process, we don't want
			# to be killed by ctrl+C
			return;
		}

		$loop->stop();
	};
}



sub send
{
	my ($this, $data) = @_;
	$this->stream->write ($data);
}



sub create_future
{
	my ($this) = @_;
	return $this->loop->new_future;
}



sub await
{
	my ($this, $future) = @_;

	my @result = $this->loop->await ($future);
	return @result;
}



sub _setup_signals
{
	my ($this, @signals) = @_;

	return if ($^O eq 'MSWin32');

	foreach my $signal (@signals)
	{
		my $handler = $this->_on_signal();

		my $signal = IO::Async::Signal->new
		(
			name => $signal,
			on_receipt => sub
			{
				$handler->($signal);
			}
		);

		$this->loop->add ($signal);
		push @{$this->signals}, $signal;
	}
}



sub _teardown_signals
{
	my ($this) = @_;

	while (my $signal = shift @{$this->signals})
	{
		$this->loop->remove ($signal);
	}
}



sub run
{
	my ($this, $data_cb, $setup_cb) = @_;

	$this->loop->later ($setup_cb) if ($setup_cb);

	$this->data_cb ($data_cb);

	$this->_setup_signals ('INT', 'TERM');
	$this->loop->run;
	$this->_teardown_signals();
}



sub stop
{
	my ($this) = @_;
	$this->loop->stop;
}



sub close
{
	my ($this) = @_;

	$this->stream->close_now if ($this->_can_close);
}

=head1 NAME

Neovim::Ext::MsgPack::RPC::EventLoop - Neovim::Ext::MsgPack::RPC::EventLoop class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 connect_stdio( )

Connect using stdin/stdout.

=head2 connect_tcp( $address, $port )

Connect to tcp/ip C<$address>:C<port>.

=head2 connect_socket( $path )

Connect to socket at C<$path>.

=head2 connect_child( \@argv )

Connect to a new Nvim instance. Uses C<\@argv> as the argument vector to
spawn an embedded Nvim. This isn't support on Windows.

=head2 create_future( )

Create a future.

=head2 await( $future)

Wait for C<$future> to complete.

=head2 close( )

Stop the event loop.

=head2 send( $data )

Queue C<$data> for sending to Nvim.

=head2 run( $data_cb )

Run the event loop, calling C<$data_cb> for each message received.

=head2 stop( )

Stop the event loop.

=cut

1;
