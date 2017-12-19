package ReverseEcho;
# ABSTRACT: An echo server that reverses each message sent

use strict;
use warnings;

use Module::Load;
use IO::Async::Loop;
use Net::Async::ZMQ;
use Net::Async::ZMQ::Socket;

sub run {
	my ($class, $package, $n_msgs) = @_;

	die "Package must be ZMQ::LibZMQ[34]" unless $package =~ /^ZMQ::LibZMQ[34]/;

	die "Must send at least one message from client" unless $n_msgs > 0;

	autoload $package;
	load ZMQ::Constants, qw(ZMQ_REP ZMQ_REQ ZMQ_NOBLOCK);

	my $loop = IO::Async::Loop->new;

	my $addr = "inproc://reverse-echo";

	my $loop_done = $loop->new_future;

	my $ctx = zmq_init();

	my $server_socket = zmq_socket( $ctx, ZMQ_REP() );
	my $client_socket = zmq_socket( $ctx, ZMQ_REQ() );

	zmq_bind( $server_socket, $addr );
	zmq_connect( $client_socket, $addr );

	my $counter = 0; # message counter for client
	my @blobs; # to store messages received by the server

	# Initiate first message.
	zmq_sendmsg( $client_socket, "hello @{[ $counter++ ]}" );

	my $zmq = Net::Async::ZMQ->new;

	$zmq->add_child(
		Net::Async::ZMQ::Socket->new(
			socket => $client_socket,
			on_read_ready => sub {
				while ( my $recvmsg = zmq_recvmsg( $client_socket, ZMQ_NOBLOCK() ) ) {
					my $msg = zmq_msg_data($recvmsg);
					zmq_sendmsg( $client_socket, "hello @{[ $counter++ ]}" );
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
				while ( my $recvmsg = zmq_recvmsg( $server_socket, ZMQ_NOBLOCK() ) ) {
					my $msg = zmq_msg_data($recvmsg);
					my $r_msg = reverse $msg;
					zmq_sendmsg( $server_socket, $r_msg );
					push @blobs, $msg;
				}
			},
		)
	);

	$loop->add( $zmq );

	$loop_done->on_ready(sub {
		zmq_close($client_socket);
		zmq_close($server_socket);
		$loop->stop;
	});

	$loop->loop_forever;

	\@blobs;
}

1;
