use strict;
use warnings;
use Protocol::SPDY;

use Test::More;

{
	# Used for examining frames without interfering with our
	# server internal state (compression etc.)
	my $spdy = new_ok('Protocol::SPDY::Tracer' => [
		# Server is requesting to send some data across the wire
		on_write => sub { die "should not write" },
	]);

	my $outgoing = '';
	my $server = new_ok('Protocol::SPDY::Server' => [
		# Server is requesting to send some data across the wire
		on_write => sub { $outgoing .= $_[0]; },
	]);

	# Helper code for setting up a new stream and checking validity on the generated
	# SYN_STREAM frame.
	my $gen_stream = sub {
		my $server = shift;
		my $code = shift;
		ok(my $stream = $server->create_stream, 'create a new stream');
		is($stream->id % 2, 0, 'even-numbered stream ID');
		ok($stream->id, 'stream ID is nonzero');
		ok($server->has_stream($stream), 'server knows about this stream');
		ok(!$stream->seen_reply, 'new stream has no reply');
		is($outgoing, '', 'have no data yet');
		ok($stream->start, 'send SYN');
		ok(length($outgoing), 'have outgoing data');
		ok(my $bytes = $spdy->extract_frame(\$outgoing), 'can extract a frame from the buffer');
		is($outgoing, '', 'buffer is now empty');
		isa_ok(my $frame = $spdy->parse_frame($bytes), 'Protocol::SPDY::Frame::Control::SYN_STREAM');
		is($frame->stream_id, $stream->id, 'stream IDs match');
		is($frame->version, $server->version, 'our protocol version matches the frame');
		$code->($stream, $frame) if $code;
		return $stream;
	};
	subtest 'RST_STREAM' => sub {
		note 'Start with a new stream request and check generated packet + state';
		my $stream = $gen_stream->($server);
		note 'Inject a RST and verify we handle it correctly';
		$stream->replied->on_done(sub {
			fail("we were not expecting a reply");
		});
		$stream->accepted->on_done(sub {
			fail("the stream was unexpectedly accepted");
		})->on_fail(sub {
			is(shift, "REFUSED_STREAM", "rejected with correct error message");
		});
		$server->on_read(
			$spdy->control_frame_bytes(RST_STREAM => [
				status    => 'REFUSED_STREAM',
				stream_id => $stream->id,
			])
		);
		done_testing;
	};
	subtest 'SYN_REPLY' => sub {
		note 'Start with a new stream request and verify we can accept it';
		my $stream = $gen_stream->($server);

		note 'Inject a reply and verify we handle it correctly';
		$stream->replied->on_done(sub {
			pass("we have a reply");
		})->on_fail(sub {
			fail("reply failed - " . shift);
		});
		$stream->accepted->on_done(sub {
			pass("the stream was accepted");
		})->on_fail(sub {
			fail("accept failed - " . shift);
		});
		$server->on_read(
			$spdy->control_frame_bytes(SYN_REPLY => [
				stream_id => $stream->id,
				headers => [ ],
			])
		);
		ok($stream->seen_reply, 'new stream has now seen the reply');
		done_testing;
	};

	subtest 'HEADERS' => sub {
		note 'Start with a new stream request and verify we can accept it';
		my $stream = $gen_stream->($server);

		note 'Inject a reply and verify we handle it correctly';
		$stream->replied->on_done(sub {
			pass("we have a reply");
			$stream->subscribe_to_event(headers => sub {
				pass("seen headers");
				is($stream->received_header('some-header'), 'some-value', 'have expected header value');
			});
			$server->on_read(
				$spdy->control_frame_bytes(HEADERS => [
					stream_id => $stream->id,
					headers => [
						[ 'some-header' => 'some-value' ],
					],
				])
			);
		})->on_fail(sub {
			fail("reply failed - " . shift);
		});
		$stream->accepted->on_done(sub {
			pass("the stream was accepted");
		})->on_fail(sub {
			fail("accept failed - " . shift);
		});
		$server->on_read(
			$spdy->control_frame_bytes(SYN_REPLY => [
				stream_id => $stream->id,
				headers => [ ],
			])
		);
		ok($stream->seen_reply, 'new stream has now seen the reply');
		done_testing;
	};

	subtest 'send data' => sub {
		note 'Start with a new stream request and verify we can accept it';
		my $stream = $gen_stream->($server);

		note 'Send data on the stream';
		$stream->replied->on_done(sub {
			pass("we have a reply");
		})->on_fail(sub {
			fail("reply failed - " . shift);
		});
		$stream->accepted->on_done(sub {
			pass("the stream was accepted");
		})->on_fail(sub {
			fail("accept failed - " . shift);
		});
		ok($stream->send_data(my $test_data = 'this is a test message'), 'send data');
		{
			ok(length($outgoing), 'have outgoing data');
			ok(my $bytes = $spdy->extract_frame(\$outgoing), 'can extract a frame from the buffer');
			is($outgoing, '', 'buffer is now empty');
			isa_ok(my $frame = $spdy->parse_frame($bytes), 'Protocol::SPDY::Frame::Data');
			is($frame->payload, $test_data, 'outgoing frame payload matches data we sent');
		}

		note 'Inject a reply and verify we handle it correctly';
		$server->on_read(
			$spdy->control_frame_bytes(SYN_REPLY => [
				stream_id => $stream->id,
				headers => [ ],
			])
		);
		ok($stream->seen_reply, 'new stream has now seen the reply');
		done_testing;
	};
}
done_testing();

