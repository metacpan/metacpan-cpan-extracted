#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. Basic document structure
# ============================================================
subtest 'basic SWML structure' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'basic');
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version');
    ok(exists $swml->{sections}{main}, 'main section exists');
    ok(ref $swml->{sections}{main} eq 'ARRAY', 'main is array');
};

# ============================================================
# 2. Phase 1: Pre-answer verbs
# ============================================================
subtest 'phase 1: pre-answer' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'p1');
    $a->add_pre_answer_verb('play', { url => 'ring.wav' });
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    ok(exists $main[0]{play}, 'pre-answer verb is first in main');
    is($main[0]{play}{url}, 'ring.wav', 'pre-answer content correct');
};

# ============================================================
# 3. Phase 2: Answer verb
# ============================================================
subtest 'phase 2: answer' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'p2', auto_answer => 1);
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    my @answers = grep { exists $_->{answer} } @main;
    ok(scalar @answers >= 1, 'answer verb present');
    is($answers[0]{answer}{max_duration}, 14400, 'default max_duration');
};

# ============================================================
# 4. Phase 2b: record_call
# ============================================================
subtest 'phase 2b: record_call' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name          => 'p2b',
        record_call   => 1,
        record_format => 'wav',
        record_stereo => 0,
    );
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    my @records = grep { exists $_->{record_call} } @main;
    ok(scalar @records >= 1, 'record_call present');
    is($records[0]{record_call}{format}, 'wav', 'custom format');
};

# ============================================================
# 5. Phase 3: Post-answer verbs
# ============================================================
subtest 'phase 3: post-answer' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'p3');
    $a->add_post_answer_verb('play', { url => 'welcome.wav' });
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    # Post-answer should be between answer and AI
    my ($answer_idx, $ai_idx, $play_idx);
    for my $i (0 .. $#main) {
        $answer_idx = $i if exists $main[$i]{answer};
        $ai_idx = $i     if exists $main[$i]{ai};
        $play_idx = $i   if exists $main[$i]{play} && ($main[$i]{play}{url} // '') eq 'welcome.wav';
    }
    ok($play_idx > $answer_idx, 'post-answer after answer');
    ok($play_idx < $ai_idx, 'post-answer before AI');
};

# ============================================================
# 6. Phase 4: AI verb
# ============================================================
subtest 'phase 4: AI verb' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'p4');
    $a->prompt_add_section('Role', 'Test agent');
    $a->add_hint('test');
    $a->set_param('temperature', 0.5);
    $a->set_global_data({ key => 'val' });
    $a->define_tool(name => 'tool1', description => 'T', handler => sub { {} });

    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is(scalar @ai, 1, 'one AI verb');
    my $ai = $ai[0]{ai};

    ok(exists $ai->{prompt}, 'prompt exists');
    ok(exists $ai->{hints}, 'hints exist');
    ok(exists $ai->{params}, 'params exist');
    ok(exists $ai->{global_data}, 'global_data exists');
    ok(exists $ai->{SWAIG}, 'SWAIG exists');
    ok(exists $ai->{SWAIG}{functions}, 'functions exist');
};

# ============================================================
# 7. Phase 5: Post-AI verbs
# ============================================================
subtest 'phase 5: post-AI' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'p5');
    $a->add_post_ai_verb('hangup', {});
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    ok(exists $main[-1]{hangup}, 'post-AI verb is last');
};

# ============================================================
# 8. All 5 phases together
# ============================================================
subtest 'all 5 phases' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'all5', record_call => 1);
    $a->add_pre_answer_verb('play', { url => 'pre.wav' });
    $a->add_post_answer_verb('play', { url => 'post.wav' });
    $a->prompt_add_section('Role', 'Agent');
    $a->add_post_ai_verb('hangup', {});

    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};

    # Verify ordering: pre-answer, answer, record, post-answer, ai, post-ai
    my @types;
    for my $v (@main) {
        my ($key) = keys %$v;
        push @types, $key;
    }

    is($types[0], 'play', 'first is pre-answer play');
    is($types[1], 'answer', 'second is answer');
    is($types[2], 'record_call', 'third is record_call');
    is($types[3], 'play', 'fourth is post-answer play');
    is($types[4], 'ai', 'fifth is ai');
    is($types[5], 'hangup', 'sixth is post-ai hangup');
};

# ============================================================
# 9. POM mode prompt rendering
# ============================================================
subtest 'POM mode rendering' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'pom_r');
    $a->prompt_add_section('Role', 'Helpful', bullets => ['Be nice']);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $prompt = $ai[0]{ai}{prompt};
    ok(exists $prompt->{pom}, 'POM mode');
    is(ref $prompt->{pom}, 'ARRAY', 'POM is array');
    is($prompt->{pom}[0]{title}, 'Role', 'POM section title');
};

# ============================================================
# 10. Raw text prompt rendering
# ============================================================
subtest 'raw text rendering' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'raw_r', use_pom => 0);
    $a->set_prompt_text('Hello');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{prompt}{text}, 'Hello', 'raw text mode');
};

# ============================================================
# 11. Post prompt URL in AI verb
# ============================================================
subtest 'post_prompt_url in AI' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'pp_url');
    $a->set_post_prompt('Summarize');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(exists $ai[0]{ai}{post_prompt_url}, 'post_prompt_url present');
};

# ============================================================
# 12. Webhook URL embedded in functions
# ============================================================
subtest 'webhook URL in functions' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name               => 'wh_func',
        basic_auth_user    => 'u',
        basic_auth_password => 'p',
    );
    $a->define_tool(name => 'tool1', description => 'T', handler => sub { {} });
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $func = $ai[0]{ai}{SWAIG}{functions}[0];
    like($func->{web_hook_url}, qr{u:p\@}, 'auth embedded in webhook URL');
    like($func->{web_hook_url}, qr{/swaig$}, 'URL ends with /swaig');
};

# ============================================================
# 13. Empty agent renders valid SWML
# ============================================================
subtest 'empty agent renders valid SWML' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'empty');
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version valid');
    ok(exists $swml->{sections}{main}, 'main section exists');
    # Should have at least the answer and ai verbs
    my @main = @{$swml->{sections}{main}};
    ok(scalar @main >= 2, 'at least 2 verbs');
};

# ============================================================
# 14. Contexts rendered under ai.prompt.contexts (per Python parity:
#     signalwire-python /core/agent/prompt/manager.py + swml_handler.py
#     build_config — contexts attach to the ai.prompt object, not as a
#     standalone ai.context_switch sibling).
# ============================================================
subtest 'contexts rendered under ai.prompt' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'ctx_r');
    my $builder = $a->define_contexts;
    my $ctx = $builder->add_context('default');
    # ContextBuilder.validate (called by to_hash) requires every context to
    # have at least one step, so add a real step.
    my $step = $ctx->add_step('greet');
    $step->set_text('Hello.');

    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(exists $ai[0]{ai}{prompt}{contexts}, 'contexts attached to ai.prompt');
    ok(exists $ai[0]{ai}{prompt}{contexts}{default}, 'default context present');
    ok(
        exists $ai[0]{ai}{prompt}{contexts}{default}{steps},
        'context has steps',
    );
};

# ============================================================
# 15. JSON roundtrip
# ============================================================
subtest 'SWML JSON roundtrip' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'rt');
    $a->prompt_add_section('Role', 'Agent');
    $a->add_hint('test');
    $a->define_tool(name => 't1', description => 'T', handler => sub { {} });

    my $swml = $a->render_swml;
    my $json = encode_json($swml);
    my $parsed = decode_json($json);
    is($parsed->{version}, '1.0.0', 'JSON roundtrip preserves version');
    ok(exists $parsed->{sections}{main}, 'JSON roundtrip preserves sections');
};

done_testing;
