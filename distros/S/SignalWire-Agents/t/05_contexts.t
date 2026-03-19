#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Agents::Contexts;

# Helper to roundtrip through JSON for comparison
sub jrt {
    return JSON::decode_json(JSON::encode_json(shift));
}

# =============================================
# Test: Step basics
# =============================================
subtest 'Step basics' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'greeting');
    is($step->name, 'greeting', 'step name');

    $step->set_text('Say hello to the user');
    my $h = jrt($step->to_hash);
    is($h->{name}, 'greeting', 'name in hash');
    is($h->{text}, 'Say hello to the user', 'text in hash');
};

subtest 'Step POM sections' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'greet');
    $step->add_section('Task', 'Greet the user');
    $step->add_bullets('Process', ['Say hello', 'Ask name']);

    my $h = jrt($step->to_hash);
    like($h->{text}, qr/## Task/, 'POM has Task header');
    like($h->{text}, qr/Greet the user/, 'POM has body');
    like($h->{text}, qr/- Say hello/, 'POM has bullets');
    like($h->{text}, qr/- Ask name/, 'POM has second bullet');
};

subtest 'Step cannot mix text and POM' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'test');
    $step->set_text('direct text');
    eval { $step->add_section('Title', 'Body') };
    ok($@, 'cannot add POM after set_text');

    $step = SignalWire::Agents::Contexts::Step->new(name => 'test2');
    $step->add_section('Title', 'Body');
    eval { $step->set_text('direct') };
    ok($@, 'cannot set_text after POM');
};

subtest 'Step criteria and functions' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'collect');
    $step->set_text('Collect info')
         ->set_step_criteria('User has provided name and email')
         ->set_functions(['get_name', 'get_email'])
         ->set_valid_steps(['process', 'next'])
         ->set_valid_contexts(['support']);

    my $h = jrt($step->to_hash);
    is($h->{step_criteria}, 'User has provided name and email', 'step_criteria');
    is_deeply($h->{functions}, ['get_name', 'get_email'], 'functions');
    is_deeply($h->{valid_steps}, ['process', 'next'], 'valid_steps');
    is_deeply($h->{valid_contexts}, ['support'], 'valid_contexts');
};

subtest 'Step with none functions' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'readonly');
    $step->set_text('Read only step')
         ->set_functions('none');
    my $h = jrt($step->to_hash);
    is($h->{functions}, 'none', 'functions=none');
};

subtest 'Step behavior flags' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'flags');
    $step->set_text('Flags test')
         ->set_end(1)
         ->set_skip_user_turn(1)
         ->set_skip_to_next_step(1);

    my $h = jrt($step->to_hash);
    ok($h->{end}, 'end flag');
    ok($h->{skip_user_turn}, 'skip_user_turn flag');
    ok($h->{skip_to_next_step}, 'skip_to_next_step flag');
};

subtest 'Step reset object' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'reset');
    $step->set_text('Reset step')
         ->set_reset_system_prompt('New prompt')
         ->set_reset_user_prompt('User msg')
         ->set_reset_consolidate(1)
         ->set_reset_full_reset(1);

    my $h = jrt($step->to_hash);
    my $reset = $h->{reset};
    ok($reset, 'has reset object');
    is($reset->{system_prompt}, 'New prompt', 'reset system_prompt');
    is($reset->{user_prompt}, 'User msg', 'reset user_prompt');
    ok($reset->{consolidate}, 'reset consolidate');
    ok($reset->{full_reset}, 'reset full_reset');
};

subtest 'Step clear_sections' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'clear');
    $step->add_section('Task', 'Original');
    $step->clear_sections;
    $step->set_text('Replaced');
    my $h = jrt($step->to_hash);
    is($h->{text}, 'Replaced', 'clear_sections allows new text');
};

# =============================================
# Test: GatherInfo
# =============================================
subtest 'GatherInfo' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'gather');
    $step->set_text('Gather user info')
         ->set_gather_info(
             output_key       => 'user_data',
             completion_action => 'next_step',
             prompt           => 'Please answer the following questions',
         )
         ->add_gather_question(
             key      => 'name',
             question => 'What is your name?',
         )
         ->add_gather_question(
             key      => 'email',
             question => 'What is your email?',
             type     => 'string',
             confirm  => 1,
         );

    my $h = jrt($step->to_hash);
    my $gi = $h->{gather_info};
    ok($gi, 'has gather_info');
    is($gi->{output_key}, 'user_data', 'output_key');
    is($gi->{completion_action}, 'next_step', 'completion_action');
    is($gi->{prompt}, 'Please answer the following questions', 'prompt');
    is(scalar @{ $gi->{questions} }, 2, 'two questions');
    is($gi->{questions}[0]{key}, 'name', 'first question key');
    is($gi->{questions}[1]{key}, 'email', 'second question key');
    ok($gi->{questions}[1]{confirm}, 'second question has confirm');
};

subtest 'GatherInfo without set_gather_info' => sub {
    my $step = SignalWire::Agents::Contexts::Step->new(name => 'test');
    eval { $step->add_gather_question(key => 'x', question => 'q') };
    ok($@, 'add_gather_question without set_gather_info dies');
};

# =============================================
# Test: Context
# =============================================
subtest 'Context basics' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    is($ctx->name, 'default', 'context name');

    my $step1 = $ctx->add_step('greet');
    $step1->set_text('Hello!');

    my $step2 = $ctx->add_step('collect');
    $step2->set_text('Collect info');

    my $h = jrt($ctx->to_hash);
    is(scalar @{ $h->{steps} }, 2, 'two steps');
    is($h->{steps}[0]{name}, 'greet', 'first step name');
    is($h->{steps}[1]{name}, 'collect', 'second step name');
};

subtest 'Context add_step with options' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    my $step = $ctx->add_step('greet',
        task        => 'Greet the user warmly',
        bullets     => ['Say hello', 'Introduce yourself'],
        criteria    => 'User has responded',
        functions   => ['greet_tool'],
        valid_steps => ['next'],
    );

    my $h = jrt($step->to_hash);
    like($h->{text}, qr/Greet the user warmly/, 'task in text');
    like($h->{text}, qr/- Say hello/, 'bullets in text');
    is($h->{step_criteria}, 'User has responded', 'criteria set');
    is_deeply($h->{functions}, ['greet_tool'], 'functions set');
    is_deeply($h->{valid_steps}, ['next'], 'valid_steps set');
};

subtest 'Context duplicate step' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('greet')->set_text('Hello');
    eval { $ctx->add_step('greet') };
    ok($@, 'duplicate step name dies');
};

subtest 'Context get_step and remove_step' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('greet')->set_text('Hello');
    $ctx->add_step('collect')->set_text('Info');

    my $s = $ctx->get_step('greet');
    ok($s, 'get_step returns step');
    is($s->name, 'greet', 'correct step returned');

    ok(!defined $ctx->get_step('nonexistent'), 'get_step returns undef for missing');

    $ctx->remove_step('greet');
    ok(!defined $ctx->get_step('greet'), 'step removed');
    my $h = jrt($ctx->to_hash);
    is(scalar @{ $h->{steps} }, 1, 'one step after removal');
};

subtest 'Context move_step' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('a')->set_text('A');
    $ctx->add_step('b')->set_text('B');
    $ctx->add_step('c')->set_text('C');

    $ctx->move_step('c', 0);
    my $h = jrt($ctx->to_hash);
    is($h->{steps}[0]{name}, 'c', 'c moved to first');
    is($h->{steps}[1]{name}, 'a', 'a is second');
    is($h->{steps}[2]{name}, 'b', 'b is third');
};

subtest 'Context system prompt' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'support');
    $ctx->add_step('greet')->set_text('Hello');
    $ctx->set_system_prompt('You are a support agent');
    $ctx->set_consolidate(1);
    $ctx->set_full_reset(1);
    $ctx->set_user_prompt('I need help');
    $ctx->set_isolated(1);

    my $h = jrt($ctx->to_hash);
    is($h->{system_prompt}, 'You are a support agent', 'system_prompt');
    ok($h->{consolidate}, 'consolidate');
    ok($h->{full_reset}, 'full_reset');
    is($h->{user_prompt}, 'I need help', 'user_prompt');
    ok($h->{isolated}, 'isolated');
};

subtest 'Context prompt' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('s1')->set_text('step');
    $ctx->set_prompt('Context-level prompt');

    my $h = jrt($ctx->to_hash);
    is($h->{prompt}, 'Context-level prompt', 'context prompt');
};

subtest 'Context POM sections' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('s1')->set_text('step');
    $ctx->add_section('Personality', 'You are friendly');
    $ctx->add_bullets('Rules', ['Be nice', 'Be helpful']);

    my $h = jrt($ctx->to_hash);
    ok(exists $h->{pom}, 'has pom');
    is(scalar @{ $h->{pom} }, 2, 'two POM sections');
};

subtest 'Context fillers' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('s1')->set_text('step');
    $ctx->set_enter_fillers({ 'en-US' => ['Welcome!', 'Hello!'] });
    $ctx->add_exit_filler('en-US', ['Goodbye!']);

    my $h = jrt($ctx->to_hash);
    is_deeply($h->{enter_fillers}{'en-US'}, ['Welcome!', 'Hello!'], 'enter_fillers');
    is_deeply($h->{exit_fillers}{'en-US'}, ['Goodbye!'], 'exit_fillers');
};

subtest 'Context valid_contexts and valid_steps' => sub {
    my $ctx = SignalWire::Agents::Contexts::Context->new(name => 'default');
    $ctx->add_step('s1')->set_text('step');
    $ctx->set_valid_contexts(['support', 'sales']);
    $ctx->set_valid_steps(['s1']);
    $ctx->set_post_prompt('Summarize');

    my $h = jrt($ctx->to_hash);
    is_deeply($h->{valid_contexts}, ['support', 'sales'], 'context valid_contexts');
    is_deeply($h->{valid_steps}, ['s1'], 'context valid_steps');
    is($h->{post_prompt}, 'Summarize', 'post_prompt');
};

# =============================================
# Test: ContextBuilder
# =============================================
subtest 'ContextBuilder single default context' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    $ctx->add_step('greet')->set_text('Hello');
    $ctx->add_step('help')->set_text('How can I help?');

    my $h = jrt($builder->to_hash);
    ok(exists $h->{default}, 'has default context');
    is(scalar @{ $h->{default}{steps} }, 2, 'default has 2 steps');
};

subtest 'ContextBuilder multiple contexts' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();

    my $sales = $builder->add_context('sales');
    $sales->add_step('intro')->set_text('Welcome to sales');

    my $support = $builder->add_context('support');
    $support->add_step('intro')->set_text('Welcome to support');
    $support->set_valid_contexts(['sales']);
    $sales->set_valid_contexts(['support']);

    my $h = jrt($builder->to_hash);
    ok(exists $h->{sales}, 'has sales context');
    ok(exists $h->{support}, 'has support context');
};

subtest 'ContextBuilder validation - no contexts' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    eval { $builder->to_hash };
    ok($@, 'no contexts dies');
};

subtest 'ContextBuilder validation - single non-default' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    $builder->add_context('other')->add_step('s1')->set_text('step');
    eval { $builder->to_hash };
    ok($@, 'single non-default context dies');
    like($@, qr/default/, 'error mentions default');
};

subtest 'ContextBuilder validation - empty context' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    $builder->add_context('default');
    eval { $builder->to_hash };
    ok($@, 'empty context dies');
};

subtest 'ContextBuilder validation - invalid step reference' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    $ctx->add_step('s1')->set_text('step')->set_valid_steps(['nonexistent']);
    eval { $builder->to_hash };
    ok($@, 'invalid step reference dies');
    like($@, qr/unknown step/, 'error mentions unknown step');
};

subtest 'ContextBuilder validation - invalid context reference' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    $ctx->add_step('s1')->set_text('step');
    $ctx->set_valid_contexts(['nonexistent']);
    eval { $builder->to_hash };
    ok($@, 'invalid context reference dies');
    like($@, qr/unknown context/, 'error mentions unknown context');
};

subtest 'ContextBuilder validation - gather_info' => sub {
    # Gather with no questions
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    my $step = $ctx->add_step('gather')->set_text('gather');
    $step->set_gather_info();
    eval { $builder->to_hash };
    ok($@, 'gather_info with no questions dies');

    # Duplicate question keys
    $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    $ctx = $builder->add_context('default');
    $step = $ctx->add_step('gather')->set_text('gather');
    $step->set_gather_info()
         ->add_gather_question(key => 'name', question => 'Name?')
         ->add_gather_question(key => 'name', question => 'Name again?');
    eval { $builder->to_hash };
    ok($@, 'duplicate question keys dies');
    like($@, qr/duplicate/, 'error mentions duplicate');
};

subtest 'ContextBuilder validation - next_step at end' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    my $step = $ctx->add_step('last')->set_text('last step');
    $step->set_gather_info(completion_action => 'next_step')
         ->add_gather_question(key => 'q1', question => 'Q?');
    eval { $builder->to_hash };
    ok($@, 'next_step on last step dies');
};

subtest 'ContextBuilder get_context' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    $builder->add_context('default')->add_step('s1')->set_text('step');
    my $ctx = $builder->get_context('default');
    ok($ctx, 'get_context returns context');
    is($ctx->name, 'default', 'correct context');
    ok(!defined $builder->get_context('nonexistent'), 'get_context returns undef for missing');
};

subtest 'ContextBuilder duplicate context' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    $builder->add_context('default');
    eval { $builder->add_context('default') };
    ok($@, 'duplicate context dies');
};

# =============================================
# Test: valid_steps "next" is allowed
# =============================================
subtest 'valid_steps with next' => sub {
    my $builder = SignalWire::Agents::Contexts::ContextBuilder->new();
    my $ctx = $builder->add_context('default');
    $ctx->add_step('s1')->set_text('step 1')->set_valid_steps(['next']);
    $ctx->add_step('s2')->set_text('step 2');

    my $h = jrt($builder->to_hash);
    is_deeply($h->{default}{steps}[0]{valid_steps}, ['next'], '"next" is valid');
};

# =============================================
# Test: create_simple_context
# =============================================
subtest 'create_simple_context' => sub {
    my $ctx = SignalWire::Agents::Contexts->create_simple_context();
    is($ctx->name, 'default', 'default name');

    $ctx = SignalWire::Agents::Contexts->create_simple_context('custom');
    is($ctx->name, 'custom', 'custom name');
};

done_testing;
