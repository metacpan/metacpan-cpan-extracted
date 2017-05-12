#!/usr/bin/perl
# $Id: udp-peer.perl 146 2007-01-07 06:51:22Z rcaputo $

# This is a second version of the UDP peer code.  I've abstracted the
# original example into POE::Stage::Receiver.

{
	# The application is itself a POE::Stage;

	package App;

	use POE::Stage::App qw(:base rsp expose);
	use POE::Stage::Receiver;

	sub on_run {
		my $arg_bind_port;

		# TODO - The next two statements seem unnecessarily cumbersome.
		# What can be done to simplify them?

		my $req_receiver = POE::Stage::Receiver->new();
		my $req_receiver_run = POE::Request->new(
			stage         => $req_receiver,
			method        => "listen",
			on_datagram   => "handle_datagram",
			on_recv_error => "handle_error",
			on_send_error => "handle_error",
			args          => {
				bind_port   => $arg_bind_port,
			},
		);

		expose $req_receiver_run => my $rrr_name;
		$rrr_name = "testname";
	}

	sub handle_datagram :Handler {
		my ($arg_datagram, $arg_remote_address);

		my $rsp_name; # $rrr_name, amove
		print "$rsp_name received datagram: $arg_datagram\n";
		$arg_datagram =~ tr[a-zA-Z][n-za-mN-ZA-M];

		rsp->recall(
			method            => "send",
			args              => {
				remote_address  => $arg_remote_address,
				datagram        => $arg_datagram,
			},
		);
	}
}

# Main code.

my $bind_port = 8675;

print "You need a udp client like netcat: nc -u localhost $bind_port\n";
App->new()->run( bind_port => $bind_port );
exit;
