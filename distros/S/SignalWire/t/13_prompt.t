#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. POM mode: add sections
# ============================================================
subtest 'prompt_add_section' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom');
    my $ret = $agent->prompt_add_section('Role', 'Be helpful.');
    is($ret, $agent, 'returns self for chaining');
    is(scalar @{$agent->pom_sections}, 1, 'one section');
    is($agent->pom_sections->[0]{title}, 'Role', 'title correct');
    is($agent->pom_sections->[0]{body}, 'Be helpful.', 'body correct');
};

subtest 'prompt_add_section with bullets' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'bullets');
    $agent->prompt_add_section('Rules', 'Follow these:', bullets => ['Rule 1', 'Rule 2']);
    my $sec = $agent->pom_sections->[0];
    is_deeply($sec->{bullets}, ['Rule 1', 'Rule 2'], 'bullets stored');
};

subtest 'prompt_add_section empty body' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'empty');
    $agent->prompt_add_section('Title', undef);
    is($agent->pom_sections->[0]{body}, '', 'undef body becomes empty string');
};

# ============================================================
# 2. prompt_has_section
# ============================================================
subtest 'prompt_has_section' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'has');
    $agent->prompt_add_section('Exists', 'Yes');
    ok($agent->prompt_has_section('Exists'), 'finds existing section');
    ok(!$agent->prompt_has_section('Missing'), 'does not find missing section');
};

# ============================================================
# 3. Multiple sections
# ============================================================
subtest 'multiple sections' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'multi');
    $agent->prompt_add_section('A', 'Body A');
    $agent->prompt_add_section('B', 'Body B');
    $agent->prompt_add_section('C', 'Body C');
    is(scalar @{$agent->pom_sections}, 3, 'three sections');
    is($agent->pom_sections->[2]{title}, 'C', 'order preserved');
};

# ============================================================
# 4. prompt_add_subsection
# ============================================================
subtest 'prompt_add_subsection' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sub');
    $agent->prompt_add_section('Parent', 'Parent body');
    my $ret = $agent->prompt_add_subsection('Parent', 'Child', 'Child body');
    is($ret, $agent, 'returns self');
    my $sec = $agent->pom_sections->[0];
    ok(exists $sec->{subsections}, 'subsections created');
    is(scalar @{$sec->{subsections}}, 1, 'one subsection');
    is($sec->{subsections}[0]{title}, 'Child', 'subsection title');
    is($sec->{subsections}[0]{body}, 'Child body', 'subsection body');
};

subtest 'prompt_add_subsection with bullets' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sub_b');
    $agent->prompt_add_section('P', 'body');
    $agent->prompt_add_subsection('P', 'C', 'body', bullets => ['b1', 'b2']);
    is_deeply($agent->pom_sections->[0]{subsections}[0]{bullets}, ['b1', 'b2'], 'subsection bullets');
};

subtest 'prompt_add_subsection nonexistent parent' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_parent');
    $agent->prompt_add_subsection('NoParent', 'Child', 'Body');
    # Should not crash, just silently skip
    is(scalar @{$agent->pom_sections}, 0, 'no sections added');
};

# ============================================================
# 5. prompt_add_to_section
# ============================================================
subtest 'prompt_add_to_section body' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'add_to');
    $agent->prompt_add_section('Sec', 'Original');
    $agent->prompt_add_to_section('Sec', body => ' appended');
    like($agent->pom_sections->[0]{body}, qr/Original\n appended/, 'body appended');
};

subtest 'prompt_add_to_section bullets' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'add_bullets');
    $agent->prompt_add_section('Sec', 'body', bullets => ['existing']);
    $agent->prompt_add_to_section('Sec', bullets => ['new1', 'new2']);
    is(scalar @{$agent->pom_sections->[0]{bullets}}, 3, 'three bullets total');
    is($agent->pom_sections->[0]{bullets}[2], 'new2', 'new bullet added');
};

subtest 'prompt_add_to_section creates bullets if none' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_bullets');
    $agent->prompt_add_section('Sec', 'body');
    $agent->prompt_add_to_section('Sec', bullets => ['first']);
    is_deeply($agent->pom_sections->[0]{bullets}, ['first'], 'bullets created');
};

# ============================================================
# 6. get_prompt (POM mode)
# ============================================================
subtest 'get_prompt POM mode' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'gp');
    $agent->prompt_add_section('Role', 'Be helpful');
    my $prompt = $agent->get_prompt;
    is(ref $prompt, 'ARRAY', 'returns arrayref in POM mode');
    is($prompt->[0]{title}, 'Role', 'contains section');
};

# ============================================================
# 7. get_prompt (raw text mode)
# ============================================================
subtest 'get_prompt raw text mode' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'raw', use_pom => 0);
    $agent->set_prompt_text('Hello world');
    is($agent->get_prompt, 'Hello world', 'returns text in raw mode');
};

# ============================================================
# 8. set_prompt_text
# ============================================================
subtest 'set_prompt_text chaining' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'spt');
    my $ret = $agent->set_prompt_text('Prompt text');
    is($ret, $agent, 'returns self');
    is($agent->prompt_text, 'Prompt text', 'text stored');
};

# ============================================================
# 9. set_post_prompt
# ============================================================
subtest 'set_post_prompt' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'spp');
    my $ret = $agent->set_post_prompt('Summarize');
    is($ret, $agent, 'returns self');
    is($agent->post_prompt, 'Summarize', 'post_prompt stored');
};

# ============================================================
# 10. POM in rendered SWML
# ============================================================
subtest 'POM sections in rendered SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'render_pom');
    $agent->prompt_add_section('Role', 'Helpful', bullets => ['Be nice']);
    $agent->prompt_add_section('Rules', '', bullets => ['No swearing']);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $pom = $ai[0]{ai}{prompt}{pom};
    is(ref $pom, 'ARRAY', 'pom is array');
    is(scalar @$pom, 2, 'two POM sections');
    is($pom->[0]{title}, 'Role', 'first section title');
};

# ============================================================
# 11. Raw text in rendered SWML
# ============================================================
subtest 'raw text in rendered SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'render_raw', use_pom => 0);
    $agent->set_prompt_text('Direct prompt');
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{prompt}{text}, 'Direct prompt', 'raw text in SWML');
};

# ============================================================
# 12. Post prompt in rendered SWML
# ============================================================
subtest 'post_prompt in rendered SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pp_render');
    $agent->set_post_prompt('End summary');
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{post_prompt}{text}, 'End summary', 'post_prompt text in SWML');
};

# ============================================================
# 13. Empty prompt modes
# ============================================================
subtest 'empty POM returns text prompt' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'empty_pom');
    $agent->set_prompt_text('fallback');
    # No POM sections, should fall back to text
    is($agent->get_prompt, 'fallback', 'falls back to text when POM empty');
};

# ============================================================
# 14. Post prompt with LLM params
# ============================================================
subtest 'post_prompt with LLM params in SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pp_llm');
    $agent->set_post_prompt('Summarize');
    $agent->set_post_prompt_llm_params(temperature => 0.2);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{post_prompt}{temperature}, 0.2, 'post_prompt LLM param');
};

# ============================================================
# 15. Prompt LLM params in SWML
# ============================================================
subtest 'prompt LLM params in SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'p_llm');
    $agent->set_prompt_text('test');
    $agent->set_prompt_llm_params(temperature => 0.8, top_p => 0.95);
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{prompt}{temperature}, 0.8, 'prompt temperature');
    is($ai[0]{ai}{prompt}{top_p}, 0.95, 'prompt top_p');
};

# ============================================================
# 16. pom accessor (Python parity: agent.pom)
#
# Mirrors signalwire-python tests/unit/core/test_agent_base.py::
#   TestAgentBasePromptMethods::test_set_prompt_pom_succeeds_when_use_pom_true
#
# As of 2026-04-30: ``$agent->pom`` returns a typed
# SignalWire::POM::PromptObjectModel object (was an arrayref of section
# hashes). The typed object exposes the same data via Section accessors
# plus markdown/xml/json rendering — matching Python's PromptObjectModel.
# ============================================================
subtest 'pom returns PromptObjectModel after prompt_add_section' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom1');
    $agent->prompt_add_section('Greeting', 'Hello');
    my $pom = $agent->pom;
    ok(defined $pom, 'pom is defined');
    isa_ok($pom, 'SignalWire::POM::PromptObjectModel');
    is(scalar @{ $pom->sections }, 1, 'one section');
    is($pom->sections->[0]->title, 'Greeting', 'title');
    is($pom->sections->[0]->body, 'Hello', 'body');
};

subtest 'pom returns undef when use_pom is false' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_pom', use_pom => 0);
    is($agent->pom, undef, 'pom returns undef when use_pom is false');
};

subtest 'pom returns a fresh object — caller mutation cannot leak' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pom_clone');
    $agent->prompt_add_section('Original', 'Body');
    my $pom = $agent->pom;
    # Mutate the returned PromptObjectModel: add a new section, rename
    # the existing one. Neither change must leak back to the agent.
    $pom->add_section(title => 'Injected', body => 'leaked');
    $pom->sections->[0]->title('Hijacked');

    my $fresh = $agent->pom;
    is(scalar @{ $fresh->sections }, 1, 'caller add_section did not leak');
    is($fresh->sections->[0]->title, 'Original', 'caller mutation did not leak');
};

done_testing;
