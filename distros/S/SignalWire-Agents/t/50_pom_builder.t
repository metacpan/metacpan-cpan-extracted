#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use SignalWire::Agents::Agent::AgentBase;

# ============================================================
# POM Builder tests - structured prompt generation
# ============================================================

# Helper to get POM from rendered SWML
sub get_pom {
    my ($agent) = @_;
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    return $ai[0]{ai}{prompt}{pom};
}

# ============================================================
# 1. Single section POM
# ============================================================
subtest 'single section' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom1');
    $a->prompt_add_section('Role', 'You are helpful.');
    my $pom = get_pom($a);
    is(ref $pom, 'ARRAY', 'POM is array');
    is(scalar @$pom, 1, 'one section');
    is($pom->[0]{title}, 'Role', 'title');
    is($pom->[0]{body}, 'You are helpful.', 'body');
};

# ============================================================
# 2. Section with bullets
# ============================================================
subtest 'section with bullets' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom2');
    $a->prompt_add_section('Rules', 'Follow these:', bullets => ['Rule 1', 'Rule 2', 'Rule 3']);
    my $pom = get_pom($a);
    is_deeply($pom->[0]{bullets}, ['Rule 1', 'Rule 2', 'Rule 3'], 'bullets in POM');
};

# ============================================================
# 3. Multiple sections ordering
# ============================================================
subtest 'multiple sections order' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom3');
    $a->prompt_add_section('Alpha', 'First');
    $a->prompt_add_section('Beta', 'Second');
    $a->prompt_add_section('Gamma', 'Third');
    my $pom = get_pom($a);
    is(scalar @$pom, 3, 'three sections');
    is($pom->[0]{title}, 'Alpha', 'first section');
    is($pom->[1]{title}, 'Beta', 'second section');
    is($pom->[2]{title}, 'Gamma', 'third section');
};

# ============================================================
# 4. Subsections
# ============================================================
subtest 'subsections' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom4');
    $a->prompt_add_section('Main', 'Main body');
    $a->prompt_add_subsection('Main', 'Sub1', 'Sub body 1');
    $a->prompt_add_subsection('Main', 'Sub2', 'Sub body 2', bullets => ['b1']);
    my $pom = get_pom($a);
    ok(exists $pom->[0]{subsections}, 'has subsections');
    is(scalar @{$pom->[0]{subsections}}, 2, 'two subsections');
    is($pom->[0]{subsections}[0]{title}, 'Sub1', 'sub1 title');
    is($pom->[0]{subsections}[1]{title}, 'Sub2', 'sub2 title');
};

# ============================================================
# 5. Add to section
# ============================================================
subtest 'add_to_section' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom5');
    $a->prompt_add_section('Sec', 'Initial', bullets => ['b1']);
    $a->prompt_add_to_section('Sec', bullets => ['b2', 'b3']);
    my $pom = get_pom($a);
    is(scalar @{$pom->[0]{bullets}}, 3, 'three bullets after add');
};

# ============================================================
# 6. Complex POM with skills
# ============================================================
subtest 'POM with skills integration' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom6');
    $a->prompt_add_section('Role', 'You are a customer service agent.');
    $a->add_skill('datetime');
    my $pom = get_pom($a);
    ok(scalar @$pom >= 2, 'POM includes skill sections');
    ok($a->prompt_has_section('Date and Time Information'), 'datetime section added');
};

# ============================================================
# 7. POM preserved through clone
# ============================================================
subtest 'POM preserved through clone' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom7');
    $a->prompt_add_section('Original', 'Body');
    my $clone = $a->_clone_for_request;
    $clone->prompt_add_section('Clone', 'Extra');

    my $orig_pom = $a->pom_sections;
    my $clone_pom = $clone->pom_sections;
    is(scalar @$orig_pom, 1, 'original has 1 section');
    is(scalar @$clone_pom, 2, 'clone has 2 sections');
};

# ============================================================
# 8. Empty POM falls back to text
# ============================================================
subtest 'empty POM fallback' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom8');
    $a->set_prompt_text('Fallback text');
    # No POM sections added
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(!exists $ai[0]{ai}{prompt}{pom}, 'no pom key');
    is($ai[0]{ai}{prompt}{text}, 'Fallback text', 'text fallback');
};

# ============================================================
# 9. POM with LLM params
# ============================================================
subtest 'POM with LLM params' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom9');
    $a->prompt_add_section('Role', 'Agent');
    $a->set_prompt_llm_params(temperature => 0.5);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(exists $ai[0]{ai}{prompt}{pom}, 'POM present');
    is($ai[0]{ai}{prompt}{temperature}, 0.5, 'LLM params alongside POM');
};

# ============================================================
# 10. JSON roundtrip of POM SWML
# ============================================================
subtest 'POM SWML JSON roundtrip' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pom10');
    $a->prompt_add_section('Title', 'Body', bullets => ['b1', 'b2']);
    $a->prompt_add_subsection('Title', 'Sub', 'Sub body');
    my $swml = $a->render_swml;
    my $json = encode_json($swml);
    my $parsed = decode_json($json);
    my @ai = grep { exists $_->{ai} } @{$parsed->{sections}{main}};
    my $pom = $ai[0]{ai}{prompt}{pom};
    is($pom->[0]{title}, 'Title', 'title preserved');
    is_deeply($pom->[0]{bullets}, ['b1', 'b2'], 'bullets preserved');
    is($pom->[0]{subsections}[0]{title}, 'Sub', 'subsection preserved');
};

done_testing;
