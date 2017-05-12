# $Id: Receiver.pm 145 2006-12-25 19:09:56Z rcaputo $

=head1 NAME

POE::Stage::Receiver - a simple UDP recv/send component

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	use POE::Stage::Receiver;
	my $stage = POE::Stage::Receiver->new();
	my $request = POE::Request->new(
		stage         => $stage,
		method        => "listen",
		on_datagram   => "handle_datagram",
		on_recv_error => "handle_error",
		on_send_error => "handle_error",
		args          => {
			bind_port   => 8675,
		},
	);

	# Echo the datagram back to its sender.
	sub handle_datagram :Handler {
		my ($rsp, $arg_remote_address, $arg_datagram);
		$rsp->recall(
			method            => "send",
			args              => {
				remote_address  => $arg_remote_address,
				datagram        => $arg_datagram,
			},
		);
	}

=head1 DESCRIPTION

POE::Stage::Receiver is a simple UDP receiver/sender stage.  It's
simple, partly because it's incomplete.

POE::Stage::Receiver has two public methods: listen() and send().  It
emits a small number of message types: datagram, recv_error, and
send_error.

=cut

package POE::Stage::Receiver;

use POE::Stage qw(:base req);

use POE::Watcher::Input;
use IO::Socket::INET;
use constant DATAGRAM_MAXLEN => 1024;

=head1 PUBLIC COMMANDS

Commands are invoked with POE::Request objects.

=head2 listen bind_port => INTEGER

Bind to a port on all local interfaces and begin listening for
datagrams.  Per the SYNOPSIS, the listen request should also map
POE::Stage::Receiver's message types to appropriate handlers.

=cut

sub listen :Handler {
	my ($self, $args) = @_;

	my $req_bind_port = delete $args->{bind_port};

	my $req_socket = IO::Socket::INET->new(
		Proto     => 'udp',
		LocalPort => $req_bind_port,
	);
	die "Can't create UDP socket: $!" unless $req_socket;

	my $req_udp_watcher = POE::Watcher::Input->new(
		handle    => $req_socket,
		on_input  => "_handle_input"
	);
}

sub _handle_input :Handler {
	my ($self, $args) = @_;

	my $req_socket;
	my $remote_address = recv(
		$req_socket,
		my $datagram = "",
		DATAGRAM_MAXLEN,
		0
	);

	if (defined $remote_address) {
		req->emit(
			type              => "datagram",
			args              => {
				datagram        => $datagram,
				remote_address  => $remote_address,
			},
		);
	}
	else {
		req->emit(
			type      => "recv_error",
			args      => {
				errnum  => $!+0,
				errstr  => "$!",
			},
		);
	}
}

=head2 send datagram => SCALAR, remote_address => ADDRESS

Send a datagram to a remote address.  Usually called via recall() to
respond to a datagram emitted by the Receiver.

=cut

sub send :Handler {
	my ($self, $args) = @_;

	my $req_socket;
	return if send(
		$req_socket,
		$args->{datagram},
		0,
		$args->{remote_address},
	) == length($args->{datagram});

	req->emit(
		type      => "send_error",
		args      => {
			errnum  => $!+0,
			errstr  => "$!",
		},
	);
}

1;

=head1 PUBLIC RESPONSES

Here's what POE::Stage::Resolver will send back.

=head2 "datagram" (datagram, remote_address)

POE::Stage::Receiver emits a "datagram" message whenever it
successfully recv()s a datagram from some remote peer.  The datagram
message includes two parameters: "datagram" contains the received
data, and "remote_address" contains the address that sent the
datagram.

Both parameters can be passed back to the POE::Stage::Receiver's
send() method, as is done in the SYNOPSIS.

	sub on_datagram {
		my ($arg_datagram, $arg_remote_address);
		my $output = function_of($arg_datagram);
		my $req->recall(
			method => "send",
			args => {
				remote_address => $arg_remote_address,
				datagram => $output,
			}
		);
	}

=head2 "recv_error" (errnum, errstr)

The stage encountered an error receiving from a peer.  "errnum" is the
numeric form of $! after recv() failed.  "errstr" is the error's
string form.

	sub on_recv_error {
		goto &on_send_error;
	}

=head2 "send_error" (errnum, errstr)

The stage encountered an error receiving from a peer.  "errnum" is the
numeric form of $! after send() failed.  "errstr" is the error's
string form.

	sub on_send_error {
		my ($arg_errnum, $arg_errstr);
		warn "Error $arg_errnum : $arg_errstr.  Shutting down.\n";
		my $req_receiver = undef;
	}

=head1 BUGS

See L<http://thirdlobe.com/projects/poe-stage/report/1> for known
issues.  See L<http://thirdlobe.com/projects/poe-stage/newticket> to
report one.

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.

=head1 SEE ALSO

L<POE::Stage> and L<POE::Request>.  The examples/udp-peer.perl program
in POE::Stage's distribution.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Stage::Receiver is Copyright 2005-2006 by Rocco Caputo.  All rights
are reserved.  You may use, modify, and/or distribute this module
under the same terms as Perl itself.

=cut
