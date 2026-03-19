#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
    project => 'p', token => 't', host => 'h',
);

# ============================================================
# 1. Calling namespace construction
# ============================================================
subtest 'calling namespace' => sub {
    my $c = $client->calling;
    isa_ok($c, 'SignalWire::Agents::REST::Namespaces::Calling');
    is($c->_base_path, '/api/calling/calls', 'base path');
};

# ============================================================
# 2. Call control methods
# ============================================================
subtest 'call control methods' => sub {
    my $c = $client->calling;
    my @methods = qw(dial update_call end transfer disconnect);
    for my $m (@methods) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 3. Play methods
# ============================================================
subtest 'play methods' => sub {
    my $c = $client->calling;
    for my $m (qw(play play_pause play_resume play_stop play_volume)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 4. Record methods
# ============================================================
subtest 'record methods' => sub {
    my $c = $client->calling;
    for my $m (qw(record record_pause record_resume record_stop)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 5. Collect methods
# ============================================================
subtest 'collect methods' => sub {
    my $c = $client->calling;
    for my $m (qw(collect collect_stop collect_start_input_timers)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 6. Detect methods
# ============================================================
subtest 'detect methods' => sub {
    my $c = $client->calling;
    for my $m (qw(detect detect_stop)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 7. Tap and stream methods
# ============================================================
subtest 'tap and stream methods' => sub {
    my $c = $client->calling;
    for my $m (qw(tap tap_stop stream stream_stop)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 8. AI methods
# ============================================================
subtest 'AI methods' => sub {
    my $c = $client->calling;
    for my $m (qw(ai_message ai_hold ai_unhold ai_stop)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 9. Denoise and transcribe
# ============================================================
subtest 'denoise and transcribe' => sub {
    my $c = $client->calling;
    for my $m (qw(denoise denoise_stop transcribe transcribe_stop)) {
        ok($c->can($m), "has $m");
    }
};

# ============================================================
# 10. Other methods
# ============================================================
subtest 'other calling methods' => sub {
    my $c = $client->calling;
    for my $m (qw(refer user_event live_transcribe live_translate
                   send_fax_stop receive_fax_stop)) {
        ok($c->can($m), "has $m");
    }
};

done_testing;
