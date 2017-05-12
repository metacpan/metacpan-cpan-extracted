# $Id: Ticker.pm 143 2006-12-18 07:28:32Z rcaputo $

=head1 NAME

POE::Stage::Ticker - a periodic message generator for POE::Stage

=head1 SYNOPSIS

	sub some_handler :Handler {
		my $req_ticker = POE::Stage::Ticker->new();
		my $req_ticker_request = POE::Request->new(
			stage       => $req_ticker,
			method      => "start_ticking",
			on_tick     => "handle_tick",   # Invoke my handle_tick() method
			args        => {
				interval  => 10,              # every 10 seconds.
			},
		);
	}

	sub handle_tick {
		my $arg_id;
		print "Handled tick number $arg_id in a series.\n";
	}

=head1 DESCRIPTION

POE::Stage::Ticker emits recurring messages at a fixed interval.

=cut

package POE::Stage::Ticker;

use POE::Stage qw(:base self req);
use POE::Watcher::Delay;

=head1 PUBLIC COMMANDS

=head2 start_ticking (interval => FLOAT)

Used to request the Ticker to start ticking.  The Ticker will emit a
"tick" message every "interval" seconds.

=cut

sub start_ticking :Handler {
	# Since a single request can generate many ticks, keep a counter so
	# we can tell one from another.

	my $req_tick_id  = 0;
	my $req_interval = my $arg_interval;

	self->set_delay();
}

sub got_watcher_tick :Handler {
	# Note: We have received two copies of the tick interval.  One is
	# from start_ticking() saving it in the request-scoped part of
	# $self.  The other is passed to us in $args, through the
	# POE::Watcher::Delay object.  We can use either one, but I thought
	# it would be nice for testing and illustrative purposes to make
	# sure they both agree.
	die unless my $req_interval == my $arg_interval;

	my $req_tick_id;
	req->emit(
		type  => "tick",
		args  => {
			id  => ++$req_tick_id,
		},
	);

	# TODO - Ideally we can restart the existing delay, perhaps with an
	# again() method.  Meanwhile we just create a new delay object to
	# replace the old one.

	self->set_delay();
}

sub set_delay :Handler {
	my $req_interval;
	my $req_delay = POE::Watcher::Delay->new(
		seconds     => $req_interval,
		on_success  => "got_watcher_tick",
		args        => {
			interval  => $req_interval,
		},
	);
}

1;

=head1 PUBLIC RESPONSES

Responses are returned by POE::Request->return() or emit().

=head2 "tick" (id)

Once start_ticking() has been invoked, POE::Stage::Ticker emits a
"tick" event.  The "id" parameter is the ticker's unique ID, so that
ticks from multiple tickers are not confused.

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

L<POE::Stage> and L<POE::Request>.  The examples/many-responses.perl
program in POE::Stage's distribution.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org>.

=head1 LICENSE

POE::Stage::Ticker is Copyright 2005-2006 by Rocco Caputo.  All rights
are reserved.  You may use, modify, and/or distribute this module
under the same terms as Perl itself.

=cut
