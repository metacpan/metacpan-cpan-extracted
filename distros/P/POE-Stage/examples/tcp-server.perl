#!/usr/bin/perl
# $Id: tcp-server.perl 155 2007-02-15 05:09:17Z rcaputo $

# Test out the syntax for a TCP listener stage.

use lib qw(./lib ../lib);

{
	package POE::Stage::Listener;

	use POE::Stage qw(:base self req);

	use IO::Socket::INET;
	use POE::Watcher::Input;

	# Fire off an automatic request using the stage's constructor
	# parameters.  Check the parameters while were here since this is
	# happening during new().
	#
	# TODO - Fix up error reporting so croak() reports where new() was
	# called.
	#
	# TODO - I'm not sure whether things should be stored in $self,
	# $self->{req} or what.  Very confusing.  Users will also have this
	# problem.  Hell, if *I* can't figure it out, then it sucks.

	sub init :Handler {
		my $args = $_[1];
		my $self_init_request;
		my ($arg_socket, $arg_listen_queue);

		# TODO - This idiom happens enough that we should abstract it.
		my $passthrough_args = delete($args->{args}) || { };

		# TODO - Common pattern: Hoist parameters out of $args and place
		# them into a request's args.  It's a butt-ugly, repetitive thing
		# to do.  Find a better way.

		die "POE::Stage::Listener requires a socket" unless $arg_socket;

		$arg_listen_queue ||= SOMAXCONN;

		$self_init_request = POE::Request->new(
			stage   => self,
			method  => "listen",
			%$args,
			args    => {
				%$passthrough_args,
				socket => $arg_socket,
				listen_queue => $arg_listen_queue,
			},
		);

		# Do object-scoped initialization here.
		# TODO
	}

	# Set up the listener.

	sub listen :Handler {
		my ($arg_socket, $arg_listen_queue);

		my $req_socket = $arg_socket;
		my $req_listen_queue = $arg_listen_queue;

		# TODO - Pass in parameters for listen.  Whee.
		listen($arg_socket, $arg_listen_queue) or die "listen: $!";

		my $req_input_watcher = POE::Watcher::Input->new(
			handle    => $arg_socket,
			on_input  => "accept_connection",
		);
	}

	# Ready to accept from the socket.  Do it.

	sub accept_connection :Handler {
		my $new_socket = (my $req_socket)->accept();
		warn "accept error $!" unless $new_socket;
		req->emit( type => "accept", socket => $new_socket );
	}
}

###

{
	package POE::Stage::EchoSession;

	use POE::Stage qw(:base self req);

	sub init :Handler {
		my $args = $_[1];
		my $self_init_request;
		my $arg_socket;

		my $passthrough_args = delete($args->{args}) || { };

		$self_init_request = POE::Request->new(
			stage => self,
			method => "interact",
			%$args,
			args => {
				socket => $arg_socket,
			}
		);
	}

	sub interact :Handler {
		my $arg_socket;

		my $req_input_watcher = POE::Watcher::Input->new(
			handle    => $arg_socket,
			on_input  => "process_input",
		);
	}

	sub process_input :Handler {
		my $arg_handle;

		my $ret = sysread($arg_handle, my $buf = "", 65536);

		use POSIX qw(EAGAIN EWOULDBLOCK);

		my $req_input_watcher;
		unless ($ret) {
			return if $! == EAGAIN or $! == EWOULDBLOCK;
			if ($!) {
				warn "read error: $!";
			}
			else {
				warn "remote closed connection";
			}
			$req_input_watcher = undef;
			return;
		}

		my ($offset, $rest) = (0, $ret);
		while ($rest) {
			my $wrote = syswrite($arg_handle, $buf, $rest, $offset);

			# Nasty busy loop for rapid prototyping.
			unless ($wrote) {
				next if $! == EAGAIN or $! == EWOULDBLOCK;
				warn "write error: $!";
				$req_input_watcher = undef;
				return;
			}

			$rest -= $wrote;
			$offset += $wrote;
		}
	}
}

###

{
	package POE::Stage::EchoServer;

	use Scalar::Util qw(weaken);
	use base qw(POE::Stage::Listener);

	sub on_my_accept :Handler {
		my $arg_socket;

		# Do we need to save this reference?  Self-requesting stages
		# should do something magical here.
		my %req_sockets;
		$req_sockets{$arg_socket} = POE::Stage::EchoSession->new(
			socket => $arg_socket,
		);
		weaken $req_sockets{$arg_socket};
	}
}

# The application starts an echo server based on parameters given to
# it.

{
	package App;
	use POE::Stage::App qw(:base);
	sub on_run {
		my $req_server = POE::Stage::EchoServer->new(
			socket => IO::Socket::INET->new(
				LocalAddr => my $arg_bind_addr,
				LocalPort => my $arg_bind_port,
				ReuseAddr => "yes",
			),
		);

		print "To connect to this echo server: telnet localhost 31415\n";
	}
}

App->new()->run(
	bind_addr => "127.0.0.1",
	bind_port => 31415,
);
exit;

__END__

Do we even need an App class for self-contained subclass
components?  Nifty!  Try to avoid it.

# Creating the server object will also set it up.
# init() fires the event, self-firing style.
# We need callbacks that redirect to other stages.

my $x = POE::Stage::EchoServer->new(
	BindPort => 8675,
);

POE::Kernel->run();

Uppercase parameters are constructor arguments?  Does it matter which
are for the constructor?

Socket

on_accept
on_accept_failure
on_failure

