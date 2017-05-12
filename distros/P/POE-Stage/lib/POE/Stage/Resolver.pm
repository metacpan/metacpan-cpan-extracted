# $Id: Resolver.pm 147 2007-01-21 07:57:35Z rcaputo $

=head1 NAME

POE::Stage::Resolver - a simple non-blocking DNS resolver

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	sub some_handler :Handler {
		my $req_resolver = POE::Stage::Resolver->new(
			method      => "resolve",
			on_success  => "handle_host",
			on_error    => "handle_error",
			args        => {
				input     => "thirdlobe.com",
				type      => "A",   # A is default
				class     => "IN",  # IN is default
			},
		);
	}

	sub handle_host :Handler {
		my ($arg_input, $arg_packet);

		my @answers = $arg_packet->answer();
		foreach my $answer (@answers) {
			print(
				"Resolved: $arg_input = type(", $answer->type(), ") data(",
				$answer->rdatastr, ")\n"
			);
		}

		# Cancel the resolver by destroying it.
		my $req_resolver = undef;
	}

=head1 DESCRIPTION

POE::Stage::Resolver is a simple non-blocking DNS resolver.  For now
it uses Net::DNS::Resolver for the bulk of its work.  It returns
Net::DNS::Packet objects in its "success" responses.  Please see the
documentation for Net::DNS.

=cut

package POE::Stage::Resolver;

use POE::Stage qw(:base self req);
use POE::Watcher::Delay;
use Net::DNS::Resolver;
use POE::Watcher::Input;
use Carp qw(croak);

=head1 PUBLIC COMMANDS

Commands are invoked with POE::Request objects.

=head2 new (input => INPUT, type => TYPE, class => CLASS)

Creates a POE::Stage::Resolver instance and asks it to resolve some
INPUT into records of a given CLASS and TYPE.  CLASS and TYPE default
to "IN" and "A", respectively.

When complete, the stage will respond with either a "success" or an
"error" message.

=cut

sub resolve :Handler {
	# Set up aspects of this request.
	my $req_type  = my $arg_type; $req_type ||= "A";
	my $req_class = my $arg_class; $req_class ||= "IN";
	my $req_input = my $arg_input;
	$req_input || croak "Resolver requires input";

	# Track pending requests in the object.
	my $memo_key = join("\t", $req_type, $req_class, $req_input);

	my %self_pending;
	if (exists $self_pending{$memo_key}) {
		push @{$self_pending{$memo_key}}, my $req;
		return;
	}

	$self_pending{$memo_key} = [ my $req ];

	# There's only one resolver.
	my $self_resolver ||= Net::DNS::Resolver->new();

	# But it can generate many sockets.
	my $req_socket = $self_resolver->bgsend(
		$req_input,
		$req_type,
		$req_class,
	);

	# Wait for input.
	my $req_wait_for_it = POE::Watcher::Input->new(
		handle    => $req_socket,
		on_input  => "net_dns_ready_to_read",
	);
}

sub net_dns_ready_to_read :Handler {
	my ($req_socket, $self_resolver);
	my $packet = $self_resolver->bgread($req_socket);

	my ($req_type, $req_class, $req_input);
	my $memo_key = join("\t", $req_type, $req_class, $req_input);

	my %self_pending;
	my $requests = delete $self_pending{$memo_key};

	unless (defined $requests) {
		$self_resolver = undef unless keys %self_pending;
		$req_socket = undef;
		my $req_wait_for_it = undef;
		return;
	}

	unless (defined $packet) {
		foreach my $pending (@$requests) {
			$pending->return(
				type    => "error",
				args    => {
					input => $req_input,
					error => $self_resolver->errorstring(),
				}
			);
		}

		$self_resolver = undef unless keys %self_pending;
		$req_socket = undef;
		my $req_wait_for_it = undef;
		return;
	}

	unless (defined $packet->answerfrom) {
		my $answerfrom = getpeername($req_socket);
		if (defined $answerfrom) {
			$answerfrom = (unpack_sockaddr_in($answerfrom))[1];
			$answerfrom = inet_ntoa($answerfrom);
			$packet->answerfrom($answerfrom);
		}
	}

	foreach my $pending (@$requests) {
		$pending->return(
			type      => "success",
			args      => {
				input   => $req_input,
				packet  => $packet,
			},
		);
	}

	$self_resolver = undef unless keys %self_pending;
	$req_socket = undef;
		my $req_wait_for_it = undef;
	return;
}

1;

=head1 PUBLIC RESPONSES

Responses are returned by POE::Request->return() or emit().

=head2 "success" (input, packet)

Net::DNS::Resolver successfully resolved a request.  The original
input is passed back in the "input" parameter.  The resulting
Net::DNS::Packet object is returned in "packet".

=head2 "error" (input, error)

Net::DNS::Resolver, or something else, failed to resolve the input to
a response.  The original input is passed back in the "input"
parameter.  Net::DNS::Resolver's error message comes back as "error".

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

L<POE::Stage> and L<POE::Request>.  The examples/log-resolver.perl
program in POE::Stage's distribution.  L<Net::DNS::Packet> for an
explanation of returned packets.  L<POE::Component::Client::DNS> for
the original inspiration and a much more complete asynchronous DNS
implementation.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Stage::Resolver is Copyright 2005-2006 by Rocco Caputo.  All
rights are reserved.  You may use, modify, and/or distribute this
module under the same terms as Perl itself.

=cut
