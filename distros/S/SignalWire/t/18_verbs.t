#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. Pre-answer verbs
# ============================================================
subtest 'add_pre_answer_verb' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'pre');
    my $ret = $a->add_pre_answer_verb('play', { url => 'ring.wav' });
    is($ret, $a, 'returns self');
    is(scalar @{$a->pre_answer_verbs}, 1, 'one pre-answer verb');
    is_deeply($a->pre_answer_verbs->[0], { play => { url => 'ring.wav' } }, 'verb content');
};

subtest 'multiple pre-answer verbs' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'multi_pre');
    $a->add_pre_answer_verb('play', { url => 'ring1.wav' });
    $a->add_pre_answer_verb('play', { url => 'ring2.wav' });
    is(scalar @{$a->pre_answer_verbs}, 2, 'two pre-answer verbs');
};

subtest 'clear_pre_answer_verbs' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'clear_pre');
    $a->add_pre_answer_verb('play', { url => 'ring.wav' });
    my $ret = $a->clear_pre_answer_verbs;
    is($ret, $a, 'returns self');
    is(scalar @{$a->pre_answer_verbs}, 0, 'cleared');
};

# ============================================================
# 2. Post-answer verbs
# ============================================================
subtest 'add_post_answer_verb' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'post');
    my $ret = $a->add_post_answer_verb('play', { url => 'welcome.wav' });
    is($ret, $a, 'returns self');
    is(scalar @{$a->post_answer_verbs}, 1, 'one post-answer verb');
    is_deeply($a->post_answer_verbs->[0], { play => { url => 'welcome.wav' } }, 'verb content');
};

subtest 'clear_post_answer_verbs' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'clear_post');
    $a->add_post_answer_verb('play', { url => 'x.wav' });
    my $ret = $a->clear_post_answer_verbs;
    is($ret, $a, 'returns self');
    is(scalar @{$a->post_answer_verbs}, 0, 'cleared');
};

# ============================================================
# 3. Post-AI verbs
# ============================================================
subtest 'add_post_ai_verb' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'post_ai');
    my $ret = $a->add_post_ai_verb('hangup', {});
    is($ret, $a, 'returns self');
    is(scalar @{$a->post_ai_verbs}, 1, 'one post-AI verb');
};

subtest 'clear_post_ai_verbs' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'clear_ai');
    $a->add_post_ai_verb('hangup', {});
    my $ret = $a->clear_post_ai_verbs;
    is($ret, $a, 'returns self');
    is(scalar @{$a->post_ai_verbs}, 0, 'cleared');
};

# ============================================================
# 4. Verb ordering in SWML
# ============================================================
subtest 'verb ordering in SWML' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'order');
    $a->add_pre_answer_verb('play', { url => 'ring.wav' });
    $a->add_post_answer_verb('play', { url => 'welcome.wav' });
    $a->add_post_ai_verb('hangup', {});

    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};

    # Pre-answer should be first
    ok(exists $main[0]{play}, 'pre-answer verb is first');

    # Post-AI should be last
    ok(exists $main[-1]{hangup}, 'post-AI verb is last');

    # Answer verb should be second (after pre-answer)
    ok(exists $main[1]{answer}, 'answer verb is second');

    # Post-answer should come after answer but before AI
    my $has_welcome = 0;
    for my $i (2 .. $#main - 2) {
        if (exists $main[$i]{play} && $main[$i]{play}{url} eq 'welcome.wav') {
            $has_welcome = 1;
            last;
        }
    }
    ok($has_welcome, 'post-answer verb is after answer');
};

# ============================================================
# 5. set_answer_config
# ============================================================
subtest 'set_answer_config' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'answer_cfg');
    my $ret = $a->set_answer_config({ max_duration => 7200 });
    is($ret, $a, 'returns self');
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    my @answers = grep { exists $_->{answer} } @main;
    is($answers[0]{answer}{max_duration}, 7200, 'custom answer max_duration');
};

# ============================================================
# 6. auto_answer false
# ============================================================
subtest 'auto_answer false' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'no_answer', auto_answer => 0);
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    my @answers = grep { exists $_->{answer} } @main;
    is(scalar @answers, 0, 'no answer verb when auto_answer is false');
};

# ============================================================
# 7. record_call in SWML
# ============================================================
subtest 'record_call in SWML' => sub {
    my $a = SignalWire::Agent::AgentBase->new(
        name        => 'record',
        record_call => 1,
    );
    my $swml = $a->render_swml;
    my @main = @{$swml->{sections}{main}};
    my @records = grep { exists $_->{record_call} } @main;
    ok(scalar @records >= 1, 'record_call verb present');
    is($records[0]{record_call}{format}, 'mp4', 'default format mp4');
};

# ============================================================
# 8. Verbs with chaining
# ============================================================
subtest 'verb chaining' => sub {
    my $a = SignalWire::Agent::AgentBase->new(name => 'chain');
    my $ret = $a->add_pre_answer_verb('play', { url => 'a.wav' })
               ->add_post_answer_verb('play', { url => 'b.wav' })
               ->add_post_ai_verb('hangup', {});
    is($ret, $a, 'chaining works through all verb methods');
    is(scalar @{$a->pre_answer_verbs}, 1, 'pre-answer set');
    is(scalar @{$a->post_answer_verbs}, 1, 'post-answer set');
    is(scalar @{$a->post_ai_verbs}, 1, 'post-AI set');
};

done_testing;
