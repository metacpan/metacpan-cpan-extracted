#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_calling_mock.py.
#
# Every command in CallingNamespace is exercised against the mock server so
# we know the SDK sends the right wire request - method, path, command
# field, and (where applicable) the id and params.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $CALLS_PATH = '/api/calling/calls';

# Helper: assert journal entry matches a calling command. expected_id of
# undef means "no id at body root" (true only for update / dial which
# carry id inside params).
sub _assert_command {
    my ($command, $expected_id) = @_;
    my $j = MockTest::journal_last();
    is($j->{method}, 'POST',       "method is POST for $command");
    is($j->{path},   $CALLS_PATH,  "path is $CALLS_PATH for $command");
    isnt($j->{matched_route}, undef, "matched_route set for $command");
    is(ref $j->{body}, 'HASH',     "body is a hashref for $command");
    is($j->{body}{command}, $command, "command field is $command");
    if (defined $expected_id) {
        is($j->{body}{id}, $expected_id, "id at body root for $command");
    }
    else {
        ok(!exists $j->{body}{id}, "no id at body root for $command");
    }
    return $j->{body}{params} || {};
}

# -------------------- Lifecycle --------------------

subtest 'TestCallingLifecycle' => sub {
    subtest 'dial codecs array' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->dial(
            url    => 'https://example.com/swml',
            to     => '+15551234567',
            codecs => [ 'OPUS', 'G729', 'VP8', 'PCMA' ],
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('dial', undef);
        is_deeply(
            $params->{codecs},
            [ 'OPUS', 'G729', 'VP8', 'PCMA' ],
            'params.codecs is the array we sent',
        );
        is($params->{to}, '+15551234567', 'params.to forwarded');
    };

    subtest 'dial codecs string' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->dial(
            url    => 'https://example.com/swml',
            to     => '+15551234567',
            codecs => 'OPUS,G729,VP8,PCMA',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        my $params = _assert_command('dial', undef);
        is(
            $params->{codecs},
            'OPUS,G729,VP8,PCMA',
            'params.codecs is the comma-separated string we sent',
        );
    };

    subtest 'update' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->update(id => 'call-1', state => 'hold');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('update', undef);
        is($params->{id},    'call-1', 'params.id forwarded');
        is($params->{state}, 'hold',   'params.state forwarded');
    };

    subtest 'transfer' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->transfer(
            'call-123',
            destination => '+15551234567',
            from_number => '+15559876543',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.transfer', 'call-123');
        is($params->{destination}, '+15551234567', 'params.destination');
        is($params->{from_number}, '+15559876543', 'params.from_number');
    };

    subtest 'disconnect' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->disconnect('call-456', reason => 'busy');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.disconnect', 'call-456');
        is($params->{reason}, 'busy', 'params.reason');
    };
};

# -------------------- Play --------------------

subtest 'TestCallingPlay' => sub {
    subtest 'play_pause' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->play_pause('call-1', control_id => 'ctrl-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.play.pause', 'call-1');
        is($params->{control_id}, 'ctrl-1', 'params.control_id');
    };

    subtest 'play_resume' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->play_resume('call-1', control_id => 'ctrl-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.play.resume', 'call-1');
        is($params->{control_id}, 'ctrl-1', 'params.control_id');
    };

    subtest 'play_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->play_stop('call-1', control_id => 'ctrl-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.play.stop', 'call-1');
        is($params->{control_id}, 'ctrl-1', 'params.control_id');
    };

    subtest 'play_volume' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->play_volume(
            'call-1', control_id => 'ctrl-1', volume => 2.5,
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.play.volume', 'call-1');
        is($params->{volume}, 2.5, 'params.volume');
    };
};

# -------------------- Record --------------------

subtest 'TestCallingRecord' => sub {
    subtest 'record' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->record('call-1', record => { format => 'mp3' });
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.record', 'call-1');
        is_deeply($params->{record}, { format => 'mp3' }, 'params.record');
    };

    subtest 'record_pause' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->record_pause('call-1', control_id => 'rec-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.record.pause', 'call-1');
        is($params->{control_id}, 'rec-1', 'params.control_id');
    };

    subtest 'record_resume' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->record_resume('call-1', control_id => 'rec-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.record.resume', 'call-1');
        is($params->{control_id}, 'rec-1', 'params.control_id');
    };
};

# -------------------- Collect --------------------

subtest 'TestCallingCollect' => sub {
    subtest 'collect' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->collect(
            'call-1', initial_timeout => 5, digits => { max => 4 },
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.collect', 'call-1');
        is($params->{initial_timeout}, 5, 'params.initial_timeout');
    };

    subtest 'collect_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->collect_stop('call-1', control_id => 'col-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.collect.stop', 'call-1');
        is($params->{control_id}, 'col-1', 'params.control_id');
    };

    subtest 'collect_start_input_timers' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->collect_start_input_timers(
            'call-1', control_id => 'col-1',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.collect.start_input_timers', 'call-1');
        is($params->{control_id}, 'col-1', 'params.control_id');
    };
};

# -------------------- Detect / tap / stream / denoise / transcribe --------------------

subtest 'TestCallingDetect' => sub {
    subtest 'detect' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->detect(
            'call-1', detect => { type => 'machine', params => {} },
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.detect', 'call-1');
        is($params->{detect}{type}, 'machine', 'params.detect.type');
    };

    subtest 'detect_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->detect_stop('call-1', control_id => 'det-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.detect.stop', 'call-1');
        is($params->{control_id}, 'det-1', 'params.control_id');
    };
};

subtest 'TestCallingTap' => sub {
    subtest 'tap' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->tap(
            'call-1', tap => { type => 'audio' }, device => { type => 'rtp' },
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.tap', 'call-1');
        is_deeply($params->{tap}, { type => 'audio' }, 'params.tap');
    };

    subtest 'tap_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->tap_stop('call-1', control_id => 'tap-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.tap.stop', 'call-1');
        is($params->{control_id}, 'tap-1', 'params.control_id');
    };
};

subtest 'TestCallingStream' => sub {
    subtest 'stream' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->stream(
            'call-1', url => 'wss://example.com/audio',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.stream', 'call-1');
        is($params->{url}, 'wss://example.com/audio', 'params.url');
    };

    subtest 'stream_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->stream_stop('call-1', control_id => 'stream-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.stream.stop', 'call-1');
        is($params->{control_id}, 'stream-1', 'params.control_id');
    };
};

subtest 'TestCallingDenoise' => sub {
    subtest 'denoise' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->denoise('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.denoise', 'call-1');
    };

    subtest 'denoise_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->denoise_stop('call-1', control_id => 'dn-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.denoise.stop', 'call-1');
        is($params->{control_id}, 'dn-1', 'params.control_id');
    };
};

subtest 'TestCallingTranscribe' => sub {
    subtest 'transcribe' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->transcribe(
            'call-1', language => 'en-US', transcribe => { engine => 'google' },
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.transcribe', 'call-1');
        is($params->{language}, 'en-US', 'params.language');
    };

    subtest 'transcribe_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->transcribe_stop('call-1', control_id => 'tr-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.transcribe.stop', 'call-1');
        is($params->{control_id}, 'tr-1', 'params.control_id');
    };
};

# -------------------- AI --------------------

subtest 'TestCallingAI' => sub {
    subtest 'ai_hold' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->ai_hold('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.ai_hold', 'call-1');
    };

    subtest 'ai_unhold' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->ai_unhold('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.ai_unhold', 'call-1');
    };

    subtest 'ai_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->ai_stop('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.ai.stop', 'call-1');
    };
};

# -------------------- Live transcribe / translate --------------------

subtest 'TestCallingLive' => sub {
    subtest 'live_transcribe' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->live_transcribe('call-1', language => 'en-US');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.live_transcribe', 'call-1');
        is($params->{language}, 'en-US', 'params.language');
    };

    subtest 'live_translate' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->live_translate(
            'call-1', source_language => 'en', target_language => 'es',
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.live_translate', 'call-1');
        is($params->{source_language}, 'en', 'params.source_language');
        is($params->{target_language}, 'es', 'params.target_language');
    };
};

# -------------------- Fax --------------------

subtest 'TestCallingFax' => sub {
    subtest 'send_fax_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->send_fax_stop('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.send_fax.stop', 'call-1');
    };

    subtest 'receive_fax_stop' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->receive_fax_stop('call-1');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        _assert_command('calling.receive_fax.stop', 'call-1');
    };
};

# -------------------- Misc (refer, user_event) --------------------

subtest 'TestCallingMisc' => sub {
    subtest 'refer' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->refer('call-1', to => 'sip:other@example.com');
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.refer', 'call-1');
        is($params->{to}, 'sip:other@example.com', 'params.to');
    };

    subtest 'user_event' => sub {
        my $client = MockTest::client();
        my $body = $client->calling->user_event(
            'call-1', event_name => 'my-event', payload => { foo => 'bar' },
        );
        is(ref $body, 'HASH', 'response is a hashref');
        ok(exists $body->{id}, 'response has id');
        my $params = _assert_command('calling.user_event', 'call-1');
        is($params->{event_name}, 'my-event', 'params.event_name');
        is_deeply($params->{payload}, { foo => 'bar' }, 'params.payload');
    };
};

done_testing();
