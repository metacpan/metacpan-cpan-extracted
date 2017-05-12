package Protocol::SPDY::Stream;
$Protocol::SPDY::Stream::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

=head1 NAME

Protocol::SPDY::Stream - single stream representation within a L<Protocol::SPDY> connection

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 # You'd likely be using a subclass or other container here instead
 my $spdy = Protocol::SPDY->new;
 # Create initial stream - this example is for an HTTP request
 my $stream = $spdy->create_frame(
   # 0 is the default, use 1 if you don't want anything back from the
   # other side, for example server push
   unidirectional => 0,
   # Set to 1 if we're not expecting to send any further frames on this stream
   # - a GET request with no additional headers for example
   fin => 0,
   # Normally headers are provided as an arrayref to preserve order,
   # but for convenience you could use a hashref instead
   headers => [
     ':method'  => 'PUT',
     ':path:'   => '/some/path?some=param',
     ':version' => 'HTTP/1.1',
     ':host'    => 'localhost:1234',
     ':scheme'  => 'https',
   ]
 );
 # Update the headers - regular HTTP allows trailing headers, with SPDY
 # you can send additional headers at any time
 $stream->headers(
   # There's more to come
   fin => 0,
   # Again, arrayref or hashref are allowed here
   headers => [
     'content-length' => 5,
   ]
 );
 # Normally scalar (byte) data here, although scalar ref (\'something')
 # and Future are also allowed
 $stream->send_data('hello');
 # as a scalar ref:
 # $stream->send_data(\(my $buffer = "some data"));
 # as a Future:
 # $stream->send_data(my $f = Future->new);
 # $f->done('the data you expected');
 # If you want to cancel the stream at any time, use ->reset
 $stream->reset('CANCEL'); # or STREAM_CANCEL if you've imported the constants
 # Normally you'd indicate finished by marking a data packet as the final one:
 $stream->send_data('</html>', fin => 1);
 # ... and an empty data packet should also be fine:
 # $stream->send_data('', fin => 1);

=head1 DESCRIPTION

=head2 HTTP semantics

Each stream corresponds to a single HTTP request/response exchange. The request
is contained within the SYN_STREAM frame, with optional additional HEADERS
after the initial stream creation, and the response will be in the SYN_REPLY,
which must at least include the C<:status> and C<:version> headers (so
the SYN_REPLY must contain the C<200 OK> response, you can't send that in
a later HEADERS packet).

=head2 Window handling

Each outgoing data frame will decrement the window size; a data frame
can only be sent if the data length is less than or equal to the remaining
window size. Sending will thus be paused if the window size is insufficient;
note that it may be possible for the window size to be less than zero.

* Each frame we receive and process will trigger a window update response.
This applies to data frames only; windowing does not apply to control frames.
If we have several frames queued up for processing, we will defer the window
update until we know the total buffer space freed by processing those frames.
* Each data frame we send will cause an equivalent reduction in our window
size

* Extract all frames from buffer
* For each frame:
  * If we have a stream ID for the frame, pass it to that stream
* Stream processing for new data
  * Calculate total from all new data frames
  * Send window update if required

=head2 Error handling

There are two main types of error case: stream-level errors, which can
be handled by closing that stream, or connection-level errors, where
things have gone so badly wrong that the entire connection needs to be
dropped.

Stream-level errors are handled by RST_STREAM frames.

Connection-level errors are typically cases where framing has gone out
of sync (compression failures, incorrect packet lengths, etc.) and
these are handled by sending a single GOAWAY frame then closing the
connection immediately.

=head2 Server push support

The server can push additional streams to the client to avoid the unnecessary
extra SYN_STREAM request/response cycle for additional resources that the server
knows will be needed to fulfull the main request.

A server push response is requested with L</push_stream> - this example involves
a single associated stream:

 try {
   my $assoc = $stream->push_stream;
   $assoc->closed->on_ready(sub {
     # Associated stream completed or failed - either way,
	 # we can now start sending the main data
	 $stream->send_data($html);
   })->on_fail(sub {
     # The other side might already have the data or not
	 # support server push, so don't panic if our associated
	 # stream closes before we expected it
     warn "Associated stream was rejected";
   });
 } catch {
   # We'll get an exception if we tried to push data on a stream
   # we'd already marked as FIN on our side.
   warn "Our code is broken";
   $stream->connection->goaway;
 };

You can then send that stream using L</start> as usual:

 $assoc->start(
   headers => {
     ':scheme' => 'https',
     ':host'   => 'localhost',
     ':path'   => '/image/logo.png',
   }
 );

Note that associated streams can only be initiated before the
main stream is in FIN state.

Generally it's safest to create all the associated streams immediately
after the initial SYN_STREAM request has been received from the client,
since that will pass enough information back that the client will know
how to start arranging the responses for caching. You should then be
able to send data on the streams as and when it becomes available. The
L<Future> C<needs_all> method may be useful here.

Attempting to initiate server-pushed streams after sending content is
liable to hit race conditions - see section 3.3.1 in the SPDY spec.

=cut

use Protocol::SPDY::Constants ':all';
use Scalar::Util ();

use overload
	'""' => 'to_string',
	bool => sub { 1 },
	fallback => 1;

=head1 METHODS

=cut

=head2 new

Instantiates a new stream. Expects the following named parameters:

=over 4

=item * connection - the L<Protocol::SPDY::Base> subclass which is
managing this side of the connection

=item * stream_id - the ID to use for this stream

=item * version - SPDY version, usually 3

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $fin = delete $args{fin};
	my $uni = delete $args{uni};
	my $self = bless {
		%args,
		from_us => 1,
	}, $class;
	$self->{transfer_window} = $self->initial_window_size unless exists $self->{transfer_window};
	Scalar::Util::weaken($self->{connection});
	$self->finished->done if $fin;
	$self->remote_finished->done if $uni;
	$self;
}

=head2 new_from_syn

Constructs a new instance from a L<Protocol::SPDY::Frame::Control::SYN_STREAM>
frame object.

=cut

sub new_from_syn {
	my $class = shift;
	my $frame = shift;
	my %args = @_;
	my $self = bless {
		id         => $frame->stream_id,
		version    => $frame->version,
		connection => $args{connection},
		from_us    => 0,
	}, $class;
	Scalar::Util::weaken($self->{connection});
	$self->update_received_headers_from($frame);

	# Check whether we were expecting any more data
	$self->remote_finished->done if $frame->fin;
	$self->finished->done if $frame->uni;
	if(my $parent_id = $frame->associated_stream_id) {
		# We've received a unidirectional frame from the other
		# side, this means it's server-push stream.
		$self->{associated_stream_id} = $parent_id;
		die "not unidirectional?" unless $frame->uni;
		$self->associated_stream->invoke_event(push => $self) if $self->associated_stream;
		$self->accepted->done;
	}
	$self;
}

=head2 update_received_headers_from

Updates L</received_headers> from the given frame.

=cut

sub update_received_headers_from {
	my $self = shift;
	my $frame = shift;
	my $hdr = $frame->headers_as_simple_hashref;
	$self->{received_headers}{$_} = $hdr->{$_} for keys %$hdr;
	$self
}

=head2 from_us

Returns true if we initiated this stream.

=cut

sub from_us { shift->{from_us} ? 1 : 0 }

=head2 id

Returns the ID for this stream.

=cut

sub id { shift->{id} }

=head2 seen_reply

Returns true if we have seen a reply for this stream yet.

=cut

sub seen_reply { shift->{seen_reply} ? 1 : 0 }

=head2 connection

Returns the L<Protocol::SPDY::Base> instance which owns us.

=cut

sub connection { shift->{connection} }

=head2 priority

Returns the priority for this stream (0-7).

=cut

sub priority { shift->{version} }

=head2 version

Returns the SPDY version for this stream (probably 3).

=cut

sub version { shift->{version} }

=head2 syn_frame

Generates a SYN_STREAM frame for starting this stream.

=cut

sub syn_frame {
	my $self = shift;
	my %args = @_;
	$args{headers} ||= [];
	Protocol::SPDY::Frame::Control::SYN_STREAM->new(
		%args,
		associated_stream_id => $self->associated_stream_id,
		stream_id            => $self->id,
		priority             => $self->priority,
		slot                 => 0,
		version              => $self->version,
	);
}

=head2 sent_header

Returns the given header from our recorded list of sent headers

=cut

sub sent_header { $_[0]->{sent_headers}{$_[1]} }

=head2 sent_headers

Returns the hashref of all sent headers. Please don't change the value, it
might break something: changing this will B<not> send any updates to the
other side.

=cut

sub sent_headers { $_[0]->{sent_headers} }

=head2 received_header

Returns the given header from our recorded list of received headers.

=cut

sub received_header { $_[0]->{received_headers}{$_[1]} }

=head2 received_headers

Returns the hashref of all received headers.

=cut

sub received_headers { $_[0]->{received_headers} }

=head2 handle_frame

Attempt to handle the given frame.

=cut

sub handle_frame {
	my $self = shift;
	my $frame = shift;

	if($frame->is_data) {
		my $len = length($frame->payload);
		$self->invoke_event(data => $frame->payload);
		$self->queue_window_update($len);
	} elsif($frame->type_name eq 'WINDOW_UPDATE') {
		my $delta = $frame->window_delta;
		$self->{transfer_window} += $delta;
		$self->invoke_event(transfer_window => $self->transfer_window, $delta);
	} elsif($frame->type_name eq 'RST_STREAM') {
		return $self->accepted->fail($frame->status_code_as_text) if $self->from_us;
		$self->closed->fail($frame->status_code_as_text);
	} elsif($frame->type_name eq 'SYN_REPLY') {
		die "SYN_REPLY on a stream which has already been refused or replied" if $self->accepted->is_ready;
		$self->update_received_headers_from($frame);
		$self->accepted->done;
		$self->replied->done;
	} elsif($frame->type_name eq 'HEADERS') {
		die "HEADERS on a stream which has not yet seen a reply" unless $self->accepted->is_ready;
		$self->update_received_headers_from($frame);
		$self->invoke_event(headers => $frame);
	} elsif($frame->type_name eq 'SYN_STREAM') {
		die "SYN_STREAM on an existing stream";
	} else {
		die "what is $frame ?";
	}

	if($frame->fin) {
		die "Duplicate FIN received" if $self->remote_fin;
		$self->remote_finished->done;
	}
}

=head2 send_window_update

Send out any pending window updates.

=cut

sub send_window_update {
	my $self = shift;
	return unless my $delta = delete $self->{pending_update};
	$self->window_update(window_delta => $delta);
	$self
}

=head2 queue_window_update

Request a window update due to data frame processing.

=cut

sub queue_window_update {
	my $self = shift;
	my $len = shift;
	if(exists $self->{pending_update}) {
		$self->{pending_update} += $len;
	} else {
		$self->{pending_update} = $len;
		$self->connection->batch->on_done($self->curry::send_window_update);
	}
	$self
}

=head2 queue_frame

Asks our connection object to queue the given frame instance.

=cut

sub queue_frame {
	my $self = shift;
	my $frame = shift;
	$self->finished->done if $frame->fin;
	$self->connection->queue_frame($frame);
}

=head2 start

Start this stream off by sending a SYN_STREAM frame.

=cut

sub start {
	my $self = shift;
	$self->queue_frame($self->syn_frame(@_));
	$self
}

=head2 reply

Sends a reply to the stream instantiation request.

=cut

sub reply {
	my $self = shift;
	my %args = @_;
	my $flags = 0;
	$flags |= FLAG_FIN if $args{fin};
	$self->queue_frame(
		Protocol::SPDY::Frame::Control::SYN_REPLY->new(
			stream_id => $self->id,
			version   => $self->version,
			headers   => $args{headers},
			fin       => ($args{fin} ? 1 : 0),
		)
	);
}

=head2 reset

Sends a reset request for this frame.

=cut

sub reset {
	my $self = shift;
	my $status = shift;
	$self->queue_frame(
		Protocol::SPDY::Frame::Control::RST_STREAM->new(
			stream_id => $self->id,
			status    => $status,
		)
	);
}

=head2 push_stream

Creates and returns a new C<server push> stream.

Note that a pushed stream starts with a B< SYN_STREAM > frame but with
headers that are usually found in a B< SYN_REPLY > frame.

=cut

sub push_stream {
	my $self = shift;
	die "This stream is in FIN state" if $self->finished->is_ready;

	$self->connection->create_stream(
		uni                  => 1,
		fin                  => 0,
		associated_stream_id => $self->id,
	);
}

=head2 headers

Send out headers for this frame.

=cut

sub headers {
	my $self = shift;
	my %args = @_;
	$self->queue_frame(
		Protocol::SPDY::Frame::Control::HEADERS->new(
			%args,
			stream_id => $self->id,
			version   => $self->version,
		)
	);
}

=head2 window_update

Update information on the current window progress.

=cut

sub window_update {
	my $self = shift;
	my %args = @_;
	die "No window_delta" unless defined $args{window_delta};
	$self->queue_frame(
		Protocol::SPDY::Frame::Control::WINDOW_UPDATE->new(
			%args,
			stream_id => $self->id,
			version   => $self->version,
		)
	);
}

=head2 send_data

Sends a data packet.

=cut

sub send_data {
	my $self = shift;
	my $data = shift;
	my %args = @_;
	$self->queue_frame(
		Protocol::SPDY::Frame::Data->new(
			%args,
			stream_id => $self->id,
			payload   => $data,
		)
	);
	$self
}

=head1 METHODS - Accessors

These provide read-only access to various pieces of state information.

=head2 associated_stream_id

Which stream we're associated to. Returns 0 if there isn't one.

=cut

sub associated_stream_id { shift->{associated_stream_id} || 0 }

=head2 associated_stream

The L<Protocol::SPDY::Stream> for the associated stream
(the "parent" stream to this one, if it exists). Returns undef
if not found.

=cut

sub associated_stream {
	my $self = shift;
	$self->connection->stream_by_id($self->associated_stream_id)
}

=head2 remote_fin

Returns true if the remote has sent us a FIN (half-closed state).

=cut

sub remote_fin { shift->{remote_fin} ? 1 : 0 }

=head2 local_fin

Returns true if we have sent FIN to the remote (half-closed state).

=cut

sub local_fin { shift->{local_fin} ? 1 : 0 }

=head2 initial_window_size

Initial window size. Default is 64KB for a new stream.

=cut

sub initial_window_size { shift->{initial_window_size} // 65536 }

=head2 transfer_window

Remaining bytes in the current transfer window.

=cut

sub transfer_window { shift->{transfer_window} }

=head2 to_string

String representation of this stream, for debugging.

=cut

sub to_string {
	my $self = shift;
	'SPDY:Stream ID ' . $self->id
}

=head1 METHODS - Futures

The following L<Future>-returning methods are available. Attach events using
C<on_done>, C<on_fail> or C<on_cancel> or helpers such as C<then> as usual:

 $stream->replied->then(sub {
   # This also returns a Future, allowing chaining
   $stream->send_data('...')
 })->on_fail(sub {
   die 'here';
 });

or from the server side:

 $stream->closed->then(sub {
   # cleanup here after the stream goes away
 })->on_fail(sub {
   die "Our stream was reset from the other side: " . shift;
 });

=cut

=head2 replied

We have received a SYN_REPLY from the other side. If the stream is reset before
that happens, this will be cancelled with the reason as the first parameter.

=cut

sub replied {
	my $self = shift;
	$self->{future_replied} ||= Future->new->on_done(sub {
		$self->{seen_reply} = 1
	})
}

=head2 finished

This frame has finished sending everything, i.e. we've set the FIN flag on a packet.
The difference between this and L</closed> is that the other side may have more to
say. Will be cancelled with the reason on reset.

=cut

sub finished {
	my $self = shift;
	$self->{future_finished} ||= Future->new
}

=head2 remote_finished

This frame has had all the data it's going to get from the other side,
i.e. we're sending unidirectional data or we have seen the FIN flag on
an incoming packet.

=cut

sub remote_finished {
	my $self = shift;
	$self->{future_remote_finished} ||= Future->new->on_done(sub {
		$self->{remote_fin} = 1;
	});
}

=head2 closed

The stream has been closed on both sides - either through reset or "natural causes".
Might still be cancelled if the parent object disappears.

=cut

sub closed {
	my $self = shift;
	$self->{future_closed} ||= Future->needs_all($self->finished, $self->remote_finished)
}

=head2 accepted

The remote accepted this stream immediately after our initial SYN_STREAM. If you
want notification on rejection, use an ->on_fail handler on this method.

=cut

sub accepted {
	my $self = shift;
	$self->{future_accepted} ||= Future->new
}

1;

__END__

=head1 EVENTS

The following events may be raised by this class - use
L<Mixin::Event::Dispatch/subscribe_to_event> to watch for them:

 $stream->subscribe_to_event(
   push => sub {
     my ($ev, $stream) = @_;
	 print "Server push: received new stream $stream\n";
   }
 );

=head2 push event

Called when we have received a new stream from the other side
with an associated stream. This currently means the server is
pre-emptively sending data to us, see L</Server push support>.
Will be passed the new L<Protocol::SPDY::Stream> instance.

=head2 data event

This will be called whenever we receive data from the other
side. Will be passed the data payload as a scalar.

=head2 transfer_window event

The remote has sent us a WINDOW_UPDATE packet which means we
have just updated our transfer window. Will be called with
the new transfer window size and the delta in bytes.

=head2 headers event

New headers have been received on this stream. Will be called
with the L<Protocol::SPDY::Frame::Control::HEADERS> containing
the header information.

=head1 COMPONENTS

Further documentation can be found in the following modules:

=over 4

=item * L<Protocol::SPDY> - top-level protocol object

=item * L<Protocol::SPDY::Frame> - generic frame class

=item * L<Protocol::SPDY::Frame::Control> - specific subclass for control frames

=item * L<Protocol::SPDY::Frame::Data> - specific subclass for data frames

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
