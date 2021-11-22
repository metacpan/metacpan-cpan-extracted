package ReverseEcho;
# ABSTRACT: An echo server that reverses each message sent

use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::ZMQ;
use Net::Async::ZMQ::Socket;

sub run {
	my ($class, $package, $n_msgs) = @_;

	my $shim;
	if( $package =~ /^ZMQ::LibZMQ[34]$/ )  {
		$shim = Shim::LibZMQx->new( $package );
	} elsif( $package =~ /^ZMQ::FFI$/ ) {
		$shim = Shim::ZMQFFI->new( $package );
	} else {
		die "Unknown package";
	}

	die "Must send at least one message from client" unless $n_msgs > 0;


	my $loop = IO::Async::Loop->new;

	my $addr = "inproc://reverse-echo";

	my $loop_done = $loop->new_future;

	my $ctx = $shim->{init}();

	my $server_socket = $shim->{socket}( $ctx, $shim->{ZMQ_REP} );
	my $client_socket = $shim->{socket}( $ctx, $shim->{ZMQ_REQ} );

	$shim->{bind}( $server_socket, $addr );
	$shim->{connect}( $client_socket, $addr );

	my $counter = 0; # message counter for client
	my @blobs; # to store messages received by the server

	# Initiate first message.
	$shim->{sendmsg}( $client_socket, "hello @{[ $counter++ ]}" );

	my $zmq = Net::Async::ZMQ->new;

	$zmq->add_child(
		Net::Async::ZMQ::Socket->new(
			socket => $client_socket,
			on_read_ready => sub {
				while ( $shim->has_pollin( $client_socket ) ) {
					my $recvmsg = $shim->{recvmsg}( $client_socket, $shim->{ZMQ_NOBLOCK} );
					my $msg = $shim->{msg_data}($recvmsg);
					$shim->{sendmsg}( $client_socket, "hello @{[ $counter++ ]}" );
					if( $counter == $n_msgs + 1 ) {
						$loop_done->done;
					}
				}
			},
		)
	);

	$zmq->add_child(
		Net::Async::ZMQ::Socket->new(
			socket => $server_socket,
			on_read_ready => sub {
				while ( $shim->has_pollin( $server_socket ) ) {
					my $recvmsg = $shim->{recvmsg}( $server_socket, $shim->{ZMQ_NOBLOCK} );
					my $msg = $shim->{msg_data}($recvmsg);
					my $r_msg = reverse $msg;
					$shim->{sendmsg}( $server_socket, $r_msg );
					push @blobs, $msg;
				}
			},
		)
	);

	$loop->add( $zmq );

	$loop_done->on_ready(sub {
		$shim->{close}($client_socket);
		$shim->{close}($server_socket);
		$loop->stop;
	});

	$loop->loop_forever;

	\@blobs;
}

use constant SHIM_FUNCS => [ qw(
	zmq_bind
	zmq_close
	zmq_connect
	zmq_init
	zmq_msg_data
	zmq_recvmsg
	zmq_sendmsg
	zmq_socket
) ];

use constant SHIM_CONSTANTS => [ qw(
	ZMQ_REP ZMQ_REQ
	ZMQ_NOBLOCK
	ZMQ_EVENTS ZMQ_POLLIN
) ];

package
		Shim::LibZMQx {
	use Module::Load;

	sub new {
		my ($class, $zmq_class) = @_;
		die "Package must be ZMQ::LibZMQ[34]" unless $zmq_class =~ /^ZMQ::LibZMQ[34]$/;

		autoload $zmq_class;

		my @constants = @{ ReverseEcho::SHIM_CONSTANTS() };
		load ZMQ::Constants, @constants;

		my $self = bless {}, $class;
		$self->{_stash} = Package::Stash->new($zmq_class);

		for my $fun (@{ ReverseEcho::SHIM_FUNCS() }, qw(zmq_getsockopt)) {
			my $fun_no_prefix = $fun =~ s/^zmq_//r;
			$self->{$fun_no_prefix} = $self->{_stash}->get_symbol("&${fun}");
		}

		my $const_pkg = Package::Stash->new( 'ZMQ::Constants' );
		for my $constant (@constants) {
			$self->{$constant} = $const_pkg->get_symbol("&${constant}")->();
		}

		$self;
	}

	sub has_pollin {
		my ($self, $socket) = @_;
		$self->{getsockopt}($socket, $self->{ZMQ_EVENTS} ) & $self->{ZMQ_POLLIN};
	}
}

package
		Shim::ZMQFFI {
	use Module::Load;

	sub new {
		my ($class, $zmq_class) = @_;

		die "Package must be ZMQ::FFI" unless $zmq_class =~ /^ZMQ::FFI$/;

		autoload $zmq_class;
		load 'ZMQ::FFI::Constants', @{ ReverseEcho::SHIM_CONSTANTS() };

		my $self = bless {}, $class;
		$self->{_stash} = Package::Stash->new($zmq_class);

		my $orig_init = $self->{_stash}->get_symbol('&new');
		$self->{init} = sub {
			my @extra = $^O eq 'MSWin32'
				? ( soname => 'libzmq.dll' )
				: ();
			$orig_init->( $zmq_class, @_, @extra );
		};
		$self->{msg_data} = sub { $_[0] };

		my %map_fun = (
			sendmsg => 'send',
			recvmsg => 'recv',
		);

		for my $fun (@{ ReverseEcho::SHIM_FUNCS() }) {
			my $fun_no_prefix = $fun =~ s/^zmq_//r;
			next if exists $self->{$fun_no_prefix};

			my $actual_fun = $fun_no_prefix;
			if( exists $map_fun{$fun_no_prefix} ) {
				$actual_fun = $map_fun{$fun_no_prefix};
			}

			$self->{$fun_no_prefix} = sub {
				my ($obj, @rest) = @_;
				$obj->can($actual_fun)->( $obj, @rest );
			}
		}

		my $const_pkg = Package::Stash->new($class);
		for my $constant (@{ ReverseEcho::SHIM_CONSTANTS() }) {
			$self->{$constant} = $const_pkg->get_symbol("&${constant}")->();
		}

		$self;
	}

	sub has_pollin {
		my ($self, $socket) = @_;
		return 0 if $socket->socket_ptr == -1;
		$socket->has_pollin;
	}
}


1;
