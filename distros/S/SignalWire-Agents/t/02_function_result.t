#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Agents::SWAIG::FunctionResult;

# Helper to decode the result for comparison
sub result_hash {
    my ($fr) = @_;
    # Roundtrip through JSON to normalize booleans
    return JSON::decode_json(JSON::encode_json($fr->to_hash));
}

# =============================================
# Test: Basic construction
# =============================================
subtest 'Construction' => sub {
    # Default
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new();
    is($r->response, '', 'default response is empty string');
    is($r->post_process, 0, 'default post_process is false');
    is(scalar @{ $r->action }, 0, 'default actions empty');

    # Positional string
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('Hello');
    is($r->response, 'Hello', 'positional string constructor');

    # Named args
    $r = SignalWire::Agents::SWAIG::FunctionResult->new(
        response     => 'test',
        post_process => 1,
    );
    is($r->response, 'test', 'named response');
    is($r->post_process, 1, 'named post_process');
};

# =============================================
# Test: Core methods
# =============================================
subtest 'Core methods' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('initial');

    # set_response
    my $ret = $r->set_response('updated');
    is($r->response, 'updated', 'set_response works');
    is($ret, $r, 'set_response returns self');

    # set_post_process
    $ret = $r->set_post_process(1);
    is($r->post_process, 1, 'set_post_process works');
    is($ret, $r, 'set_post_process returns self');

    # add_action
    $ret = $r->add_action('say', 'hello');
    is(scalar @{ $r->action }, 1, 'add_action adds one action');
    is_deeply($r->action->[0], { say => 'hello' }, 'action content correct');
    is($ret, $r, 'add_action returns self');

    # add_actions
    $r->add_actions([{ stop => JSON::true }, { hangup => JSON::true }]);
    is(scalar @{ $r->action }, 3, 'add_actions adds multiple');
};

# =============================================
# Test: Serialization
# =============================================
subtest 'Serialization' => sub {
    # Response only
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('test');
    my $h = result_hash($r);
    is($h->{response}, 'test', 'response in hash');
    ok(!exists $h->{action}, 'no action when empty');
    ok(!exists $h->{post_process}, 'no post_process when false');

    # With action and post_process
    $r->add_action('say', 'hello');
    $r->set_post_process(1);
    $h = result_hash($r);
    is($h->{response}, 'test', 'response preserved');
    is(scalar @{ $h->{action} }, 1, 'action included');
    ok($h->{post_process}, 'post_process included when true');

    # Empty result
    $r = SignalWire::Agents::SWAIG::FunctionResult->new();
    $h = result_hash($r);
    is($h->{response}, 'Action completed.', 'empty result gets default response');
};

# =============================================
# Test: Call Control
# =============================================
subtest 'connect' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('transferring');
    $r->connect('+15551234567', final => 1, from => '+15559876543');
    my $h = result_hash($r);
    my $action = $h->{action}[0];
    ok(exists $action->{SWML}, 'connect creates SWML action');
    is($action->{SWML}{sections}{main}[0]{connect}{to}, '+15551234567', 'connect to correct');
    is($action->{SWML}{sections}{main}[0]{connect}{from}, '+15559876543', 'connect from correct');
    is($action->{transfer}, 'true', 'final=true sets transfer');

    # Without from
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('test');
    $r->connect('sip:test@example.com', final => 0);
    $h = result_hash($r);
    $action = $h->{action}[0];
    ok(!exists $action->{SWML}{sections}{main}[0]{connect}{from}, 'no from when not specified');
    is($action->{transfer}, 'false', 'final=false sets transfer=false');
};

subtest 'swml_transfer' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('bye');
    $r->swml_transfer('https://example.com/swml', 'Transfer complete');
    my $h = result_hash($r);
    my $action = $h->{action}[0];
    my $main = $action->{SWML}{sections}{main};
    is_deeply($main->[0], { set => { ai_response => 'Transfer complete' } }, 'set ai_response');
    is_deeply($main->[1], { transfer => { dest => 'https://example.com/swml' } }, 'transfer dest');
    is($action->{transfer}, 'true', 'default final is true');
};

subtest 'hangup' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('goodbye');
    $r->hangup;
    my $h = result_hash($r);
    ok($h->{action}[0]{hangup}, 'hangup action is true');
};

subtest 'hold' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('hold');
    $r->hold(500);
    my $h = result_hash($r);
    is($h->{action}[0]{hold}, 500, 'hold with timeout');

    # Clamping
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('hold');
    $r->hold(9999);
    $h = result_hash($r);
    is($h->{action}[0]{hold}, 900, 'hold clamped to 900');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('hold');
    $r->hold(-5);
    $h = result_hash($r);
    is($h->{action}[0]{hold}, 0, 'hold clamped to 0');
};

subtest 'wait_for_user' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('wait');
    $r->wait_for_user();
    my $h = result_hash($r);
    ok($h->{action}[0]{wait_for_user}, 'default wait_for_user is true');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('wait');
    $r->wait_for_user(answer_first => 1);
    $h = result_hash($r);
    is($h->{action}[0]{wait_for_user}, 'answer_first', 'answer_first mode');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('wait');
    $r->wait_for_user(timeout => 30);
    $h = result_hash($r);
    is($h->{action}[0]{wait_for_user}, 30, 'timeout mode');
};

subtest 'stop' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('stop');
    $r->stop;
    my $h = result_hash($r);
    ok($h->{action}[0]{stop}, 'stop is true');
};

# =============================================
# Test: State & Data
# =============================================
subtest 'State & Data' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('state');

    $r->update_global_data({ key1 => 'v1', key2 => 'v2' });
    my $h = result_hash($r);
    is_deeply($h->{action}[0]{set_global_data}, { key1 => 'v1', key2 => 'v2' }, 'update_global_data');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('state');
    $r->remove_global_data(['key1', 'key2']);
    $h = result_hash($r);
    is_deeply($h->{action}[0]{unset_global_data}, ['key1', 'key2'], 'remove_global_data');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('state');
    $r->set_metadata({ meta_key => 'meta_val' });
    $h = result_hash($r);
    is_deeply($h->{action}[0]{set_meta_data}, { meta_key => 'meta_val' }, 'set_metadata');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('state');
    $r->remove_metadata(['meta_key']);
    $h = result_hash($r);
    is_deeply($h->{action}[0]{unset_meta_data}, ['meta_key'], 'remove_metadata');
};

subtest 'Context switching' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('ctx');
    $r->swml_change_step('step2');
    my $h = result_hash($r);
    is($h->{action}[0]{change_step}, 'step2', 'swml_change_step');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('ctx');
    $r->swml_change_context('support');
    $h = result_hash($r);
    is($h->{action}[0]{change_context}, 'support', 'swml_change_context');

    # Simple context switch
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('ctx');
    $r->switch_context(system_prompt => 'You are a helper');
    $h = result_hash($r);
    is($h->{action}[0]{context_switch}, 'You are a helper', 'simple context switch');

    # Advanced context switch
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('ctx');
    $r->switch_context(
        system_prompt => 'new prompt',
        user_prompt   => 'hi there',
        consolidate   => 1,
        full_reset    => 1,
    );
    $h = result_hash($r);
    my $cs = $h->{action}[0]{context_switch};
    is($cs->{system_prompt}, 'new prompt', 'advanced: system_prompt');
    is($cs->{user_prompt}, 'hi there', 'advanced: user_prompt');
    ok($cs->{consolidate}, 'advanced: consolidate');
    ok($cs->{full_reset}, 'advanced: full_reset');
};

subtest 'replace_in_history' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('history');
    $r->replace_in_history('summary text');
    my $h = result_hash($r);
    is($h->{action}[0]{replace_in_history}, 'summary text', 'replace_in_history with text');
};

# =============================================
# Test: Media
# =============================================
subtest 'Media' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('media');
    $r->say('Hello world');
    my $h = result_hash($r);
    is($h->{action}[0]{say}, 'Hello world', 'say action');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('media');
    $r->play_background_file('music.mp3');
    $h = result_hash($r);
    is($h->{action}[0]{playback_bg}, 'music.mp3', 'play_background_file without wait');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('media');
    $r->play_background_file('music.mp3', wait => 1);
    $h = result_hash($r);
    is($h->{action}[0]{playback_bg}{file}, 'music.mp3', 'play_background_file with wait - file');
    ok($h->{action}[0]{playback_bg}{wait}, 'play_background_file with wait - wait true');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('media');
    $r->stop_background_file;
    $h = result_hash($r);
    ok($h->{action}[0]{stop_playback_bg}, 'stop_background_file');
};

# =============================================
# Test: Speech & AI
# =============================================
subtest 'Speech & AI' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->add_dynamic_hints(['hint1', 'hint2']);
    my $h = result_hash($r);
    is_deeply($h->{action}[0]{add_dynamic_hints}, ['hint1', 'hint2'], 'add_dynamic_hints');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->clear_dynamic_hints;
    $h = result_hash($r);
    is_deeply($h->{action}[0]{clear_dynamic_hints}, {}, 'clear_dynamic_hints');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->set_end_of_speech_timeout(500);
    $h = result_hash($r);
    is($h->{action}[0]{end_of_speech_timeout}, 500, 'set_end_of_speech_timeout');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->set_speech_event_timeout(3000);
    $h = result_hash($r);
    is($h->{action}[0]{speech_event_timeout}, 3000, 'set_speech_event_timeout');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->toggle_functions([
        { function => 'f1', active => JSON::true },
        { function => 'f2', active => JSON::false },
    ]);
    $h = result_hash($r);
    is($h->{action}[0]{toggle_functions}[0]{function}, 'f1', 'toggle_functions');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->enable_functions_on_timeout(1);
    $h = result_hash($r);
    ok($h->{action}[0]{functions_on_speaker_timeout}, 'enable_functions_on_timeout');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->enable_extensive_data(1);
    $h = result_hash($r);
    ok($h->{action}[0]{extensive_data}, 'enable_extensive_data');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('speech');
    $r->update_settings({ temperature => 0.5, top_p => 0.9 });
    $h = result_hash($r);
    is($h->{action}[0]{settings}{temperature}, 0.5, 'update_settings');
};

# =============================================
# Test: Advanced
# =============================================
subtest 'execute_swml' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('swml');
    $r->execute_swml({ version => '1.0.0', sections => { main => [{ hangup => {} }] } });
    my $h = result_hash($r);
    my $swml = $h->{action}[0]{SWML};
    is($swml->{version}, '1.0.0', 'execute_swml hashref');

    # With transfer
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('swml');
    $r->execute_swml({ version => '1.0.0', sections => { main => [] } }, transfer => 1);
    $h = result_hash($r);
    is($h->{action}[0]{SWML}{transfer}, 'true', 'execute_swml with transfer');

    # String input
    $r = SignalWire::Agents::SWAIG::FunctionResult->new('swml');
    $r->execute_swml('{"version":"1.0.0","sections":{"main":[]}}');
    $h = result_hash($r);
    is($h->{action}[0]{SWML}{version}, '1.0.0', 'execute_swml from JSON string');
};

subtest 'join_room' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('room');
    $r->join_room('my-room');
    my $h = result_hash($r);
    my $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{join_room}{name}, 'my-room', 'join_room');
};

subtest 'sip_refer' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('sip');
    $r->sip_refer('sip:user@example.com');
    my $h = result_hash($r);
    my $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{sip_refer}{to_uri}, 'sip:user@example.com', 'sip_refer');
};

subtest 'simulate_user_input' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('sim');
    $r->simulate_user_input('hello bot');
    my $h = result_hash($r);
    is($h->{action}[0]{user_input}, 'hello bot', 'simulate_user_input');
};

# =============================================
# Test: RPC
# =============================================
subtest 'RPC methods' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('rpc');
    $r->execute_rpc(method => 'test_method', params => { key => 'value' });
    my $h = result_hash($r);
    my $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{execute_rpc}{method}, 'test_method', 'execute_rpc method');
    is($main->[0]{execute_rpc}{params}{key}, 'value', 'execute_rpc params');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('rpc');
    $r->rpc_dial(
        to_number   => '+15551234567',
        from_number => '+15559876543',
        dest_swml   => 'https://example.com/agent',
    );
    $h = result_hash($r);
    $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{execute_rpc}{method}, 'dial', 'rpc_dial method');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('rpc');
    $r->rpc_ai_message(
        call_id      => 'call-123',
        message_text => 'Hello agent',
    );
    $h = result_hash($r);
    $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{execute_rpc}{method}, 'ai_message', 'rpc_ai_message');
    is($main->[0]{execute_rpc}{call_id}, 'call-123', 'rpc_ai_message call_id');

    $r = SignalWire::Agents::SWAIG::FunctionResult->new('rpc');
    $r->rpc_ai_unhold(call_id => 'call-456');
    $h = result_hash($r);
    $main = $h->{action}[0]{SWML}{sections}{main};
    is($main->[0]{execute_rpc}{method}, 'ai_unhold', 'rpc_ai_unhold');
};

# =============================================
# Test: Chaining
# =============================================
subtest 'Method chaining' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('chained')
        ->say('Please hold')
        ->hold(120)
        ->update_global_data({ status => 'on_hold' })
        ->set_post_process(1);
    my $h = result_hash($r);
    is($h->{response}, 'chained', 'chained response');
    is(scalar @{ $h->{action} }, 3, 'chained actions count');
    ok($h->{post_process}, 'chained post_process');
};

# =============================================
# Test: Payment helpers
# =============================================
subtest 'Payment class methods' => sub {
    my $action = SignalWire::Agents::SWAIG::FunctionResult->create_payment_action('Say', 'Enter your card');
    is($action->{type}, 'Say', 'payment action type');
    is($action->{phrase}, 'Enter your card', 'payment action phrase');

    my $param = SignalWire::Agents::SWAIG::FunctionResult->create_payment_parameter('amount', '10.00');
    is($param->{name}, 'amount', 'payment parameter name');
    is($param->{value}, '10.00', 'payment parameter value');

    my $prompt = SignalWire::Agents::SWAIG::FunctionResult->create_payment_prompt(
        for_situation => 'payment-card-number',
        actions       => [$action],
        card_type     => 'visa',
    );
    is($prompt->{for}, 'payment-card-number', 'payment prompt for');
    is($prompt->{card_type}, 'visa', 'payment prompt card_type');
};

# =============================================
# Test: swml_user_event
# =============================================
subtest 'swml_user_event' => sub {
    my $r = SignalWire::Agents::SWAIG::FunctionResult->new('event');
    $r->swml_user_event({ type => 'cards_dealt', score => 21 });
    my $h = result_hash($r);
    my $swml = $h->{action}[0]{SWML};
    my $main = $swml->{sections}{main};
    is($main->[0]{user_event}{event}{type}, 'cards_dealt', 'user event type');
    is($main->[0]{user_event}{event}{score}, 21, 'user event data');
};

done_testing;
