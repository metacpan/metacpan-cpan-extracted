# $Id: Echoer.pm 145 2006-12-25 19:09:56Z rcaputo $

=head1 NAME

POE::Stage::Echoer - a stage that echoes back whatever it's given

=head1 SYNOPSIS

	# Note, this is not a complete program.
	# See the distribution's examples directory.

	use POE::Stage::Echoer;
	my $stage = POE::Stage::Echoer->new();

	my $echo_request = POE::Request->new(
		stage     => $stage,
		method    => "echo",
		on_echo   => "handle_echo",
		args      => {
			message => "stuff to echo",
		},
	);

	sub handle_echo :Handler {
		my $arg_echo;
		print "Received an echo: $arg_echo\n";
	}

=head1 DESCRIPTION

POE::Stage::Echoer echoes back the messages it receives.

Echoer is the first of hopefully many message-routing stages.

=cut

package POE::Stage::Echoer;

use POE::Stage qw(:base req);

=head1 PUBLIC COMMANDS

Commands are invoked with POE::Request objects.

TODO - Public methods?  Careful here: "method" implies a direct call.

=head2 echo message => SCALAR

Receives a scalar "message" parameter whose contents will be echoed
back to the sender in an "echo"-typed return.

Ok, that's confusing.  Perhaps the SYNOPSIS is clearer?

TODO - It would be nice to have a documentation convention for this
sort of thing.

=cut

sub echo :Handler {
	my $arg_message;
	req->return(
		type    => "echo",
		args    => {
			echo  => $arg_message,
		},
	);
}

1;

=head1 PUBLIC RESPONSES

Responses are returned by POE::Request->return() and/or emit().

=head2 "echo" (echo => SCALAR)

Returns an echo of the "message" given to this stage's echo() command.
The echo is passed in the "echo" parameter to the "echo" response.

=head1 BUGS

See http://thirdlobe.com/projects/poe-stage/report/1 for known issues.
See http://thirdlobe.com/projects/poe-stage/newticket to report one.

POE::Stage is too young for production use.  For example, its syntax
is still changing.  You probably know what you don't like, or what you
need that isn't included, so consider fixing or adding that, or at
least discussing it with the people on POE's mailing list or IRC
channel.  Your feedback and contributions will bring POE::Stage closer
to usability.  We appreciate it.

=head1 SEE ALSO

POE::Stage and POE::Request.  The examples/ping-poing.perl program in
POE::Stage's distribution.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Stage::Echoer is Copyright 2005-2006 by Rocco Caputo.  All rights
are reserved.  You may use, modify, and/or distribute this module
under the same terms as Perl itself.

=cut
