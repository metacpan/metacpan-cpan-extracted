#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::Fatal;
use Test::More;
use Test::TCP 1.03;

use Net::NSCA::Client ();
use Net::NSCA::Client::Connection::TLS ();
use Net::NSCA::Client::InitialPacket ();
use Socket qw(INADDR_LOOPBACK);

diag('Loopback address: ' . loopback_addr());

{
	# Get an unused port
	my $port = Test::TCP::empty_port();

	# Make a client
	my $client = Net::NSCA::Client->new(
		remote_host => loopback_addr(),
		remote_port => $port,
	);

	# Send a report to some random thing
	isnt(exception {
		$client->send_report(
			hostname => 'test',
			service  => 'Test',
			message  => 'OK - Test message',
			status   => $Net::NSCA::Client::STATUS_OK,
		);
	}, undef, "Unable to connect to nothing (port $port)");
}

# Create the client and server to perform the tests
test_tcp(
	client => sub { test_client(@_) },
	server => sub { test_server(@_) },
);

exit 0;

sub send_routines {[
	\&send_packet,
	sub { send_xor_encrypt('test', @_) },
	sub { send_xor_encrypt(undef, @_) },
	\&send_returns_self,
	\&send_no_initial_packet,
	\&send_wrong_config,
]}

sub recv_routines {[
	\&recv_nop, # Need this as first recv
	\&recv_packet,
	sub { recv_xor_encrypt(shift, 'test', @_) },
	sub { recv_xor_encrypt(shift, undef, @_) },
	\&recv_nop,
	\&recv_send_nothing,
	\&recv_nop,
]}

sub check_packet {
	my ($info, $packet, %args) = @_;

	# Check data packet attributes
	ATTR:
	for my $attr (keys %args) {
		# Check attribute value
		is($packet->$attr, $args{$attr}, "Received correct $attr ($info)");
	}

	return;
}
sub create_listening_socket {
	return IO::Socket::INET->new(
		Listen    => 1,
		LocalAddr => loopback_addr(),
		LocalPort => $_[0],
		Reuse     => 1,
		Proto     => 'tcp',
	);
}
sub generic_report {
	# Arguments for send_report that do not matter
	return (
		hostname => 'mail',
		service  => 'IMAP',
		message  => '32 connected user(s)',
		status   => $Net::NSCA::Client::STATUS_OK,
	);
}
sub generic_report_attr {
	my %report = generic_report();

	my $new_key_name = sub {
		return $_[0] eq 'hostname' ? $_[0]
		     : $_[0] eq 'service'  ? 'service_description'
		     : "service_$_[0]";
	};

	return map { $new_key_name->($_) => $report{$_} } keys %report;
}
sub loopback_addr {
	return join q{.}, unpack q{CCCC}, INADDR_LOOPBACK;
}
sub receive_data_packet {
	my ($info, $socket, $server_config) = @_;

	# Recieve the data packet
	my $received_bytes;
	my $data_packet_size = $server_config->_c_packer->sizeof('data_packet_struct');
	my $recv = $socket->sysread($received_bytes, $data_packet_size);

	# Check to be sure packet was received
	is($recv, $data_packet_size, "Received complete packet ($info)");

	return $received_bytes;
}
sub receive_xor_data_packet {
	my ($info, $socket, $server_config, $iv, $password) = @_;

	# Get the data packet
	my $received_bytes = receive_data_packet($info, $socket, $server_config);

	# Create a TLS object
	my $tls = Net::NSCA::Client::Connection::TLS->new(
		encryption_type => 'xor',
		(defined $password ? (password => $password) : ()),
	);

	# With XOR encryption, encrypt is also decrypt
	$received_bytes = $tls->encrypt(
		byte_stream => $received_bytes,
		iv          => $iv,
	);

	return $received_bytes;
}
sub recv_xor_encrypt {
	my ($remote, $password, %args) = @_;

	# Write an initial packet to the new client
	my $initial_packet = send_initial_packet($remote);

	# Create the client
	my $client = Net::NSCA::Client->new(%args,
		encryption_type => 'xor',
		(defined $password ? (encryption_password => $password) : ()),
	);

	my $info = defined $password ? "XOR/$password" : 'XOR';

	# Recieve the data packet
	my $received_bytes = receive_xor_data_packet(
		$info,
		$remote,
		$client->server_config,
		$initial_packet->initialization_vector,
		$password,
	);

	# Parse the data packet
	my $packet = Net::NSCA::Client::DataPacket->new($received_bytes);

	# Check data packet attributes
	check_packet($info, $packet, generic_report_attr());

	return;
}
sub recv_nop {
	# Write an initial packet to the new client
	send_initial_packet($_[0]);

	return;
}
sub recv_packet {
	my ($remote, %args) = @_;

	# Write an initial packet to the new client
	send_initial_packet($remote);

	# Create the client
	my $client = Net::NSCA::Client->new(%args);

	# Recieve the data packet
	my $received_bytes = receive_data_packet('general', $remote, $client->server_config);

	# Parse the data packet
	my $packet = Net::NSCA::Client::DataPacket->new($received_bytes);

	# Check data packet attributes
	check_packet('general', $packet, generic_report_attr());

	return;
}
sub recv_send_nothing {
	# Do nothing
	return;
}
sub send_report {
	my ($info, $client, %args) = @_;

	# Send report successfully
	ok(!exception { $client->send_report(%args) }, "Send report ($info)");

	return;
}
sub send_wrong_config {
	my %args = @_;

	# Create the connection manually
	my $conn = Net::NSCA::Client::Connection->new(%args);

	# Create a data packet
	my $packet = Net::NSCA::Client::DataPacket->new(
		generic_report_attr(),
		# With a different server configuration
		server_config => Net::NSCA::Client::ServerConfig->new(max_hostname_length => 4),
	);

	# Send the packet
	like(exception { $conn->send_data_packet($packet) },
		qr{configuration does not match}, 'Data packet needs same server configuration');

	return;
}
sub send_xor_encrypt {
	my ($password, %args) = @_;

	# Create the client
	my $client = Net::NSCA::Client->new(%args,
		encryption_type => 'xor',
		(defined $password ? (encryption_password => $password) : ()),
	);

	my $info = defined $password ? "XOR/$password" : 'XOR';

	# Send a report
	send_report($info, $client, generic_report());

	return;
}
sub send_initial_packet {
	my ($socket) = @_;

	# Create an initial packet
	my $initial_packet =  Net::NSCA::Client::InitialPacket->new;

	# Write initial packet to socket
	$socket->print($initial_packet->raw_packet);

	return $initial_packet;
}
sub send_no_initial_packet {
	my %args = @_;

	# Create the client
	my $client = Net::NSCA::Client->new(%args);

	# Send a report
	like(exception { $client->send_report(generic_report()) },
		qr{Remote host terminated connection}, 'Remote host terminated connection');

	return;
}
sub send_packet {
	my %args = @_;

	# Create the client
	my $client = Net::NSCA::Client->new(%args);

	# Send a report
	send_report('general', $client, generic_report());

	return;
}
sub send_returns_self {
	my %args = @_;

	# Create the client
	my $client = Net::NSCA::Client->new(%args);

	# Send a report (check that it returns self)
	is($client->send_report(generic_report()), $client, 'send_report returns self');

	return;
}
sub test_client {
	my ($port) = @_;

	# Client construction arguments
	my @client_args = (
		remote_host => loopback_addr(),
		remote_port => $port,
	);

	my $routines = send_routines();

	ROUTINE:
	for my $routine (@{$routines}) {
		# Perform the routines
		$routine->(@client_args);
	}

	done_testing;

	return;
}
sub test_server {
	my ($port) = @_;

	my $socket = create_listening_socket($port);
	diag("Listening on port $port");

	# Client construction arguments
	my @client_args = (
		remote_host => loopback_addr(),
		remote_port => $port,
	);

	my $routines = recv_routines();

	while (my $remote = $socket->accept) {
		# Get the current recieve routine
		my $routine = shift @{$routines};

		# Perform the recieve routine
		$routine->($remote, @client_args);

		# Close the socket
		$remote->close;
	}

	return;
}
