#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agents::Agent::AgentBase');

# ============================================================
# 1. Hints
# ============================================================
subtest 'add_hint' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'h');
    my $ret = $a->add_hint('SignalWire');
    is($ret, $a, 'returns self');
    is(scalar @{$a->hints}, 1, 'one hint');
    is($a->hints->[0], 'SignalWire', 'hint stored');
};

subtest 'add_hints' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'hs');
    $a->add_hints('AI', 'agent', 'cloud');
    is(scalar @{$a->hints}, 3, 'three hints');
};

subtest 'hints in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'h_swml');
    $a->add_hints('hint1', 'hint2');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is_deeply($ai[0]{ai}{hints}, ['hint1', 'hint2'], 'hints in SWML');
};

subtest 'pattern hints in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'ph');
    $a->add_hint('normal');
    $a->add_pattern_hint('pattern1');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is_deeply($ai[0]{ai}{hints}, ['normal', 'pattern1'], 'combined hints');
};

# ============================================================
# 2. Languages
# ============================================================
subtest 'add_language' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'lang');
    my $ret = $a->add_language(name => 'English', code => 'en-US', voice => 'rachel');
    is($ret, $a, 'returns self');
    is(scalar @{$a->languages}, 1, 'one language');
    is($a->languages->[0]{code}, 'en-US', 'language code');
};

subtest 'set_languages' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'sl');
    $a->set_languages([{ name => 'Spanish', code => 'es-ES' }]);
    is(scalar @{$a->languages}, 1, 'languages replaced');
};

subtest 'languages in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'l_swml');
    $a->add_language(name => 'English', code => 'en-US');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{languages}[0]{code}, 'en-US', 'language in SWML');
};

# ============================================================
# 3. Pronunciations
# ============================================================
subtest 'add_pronunciation' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pron');
    my $ret = $a->add_pronunciation(replace => 'SW', with => 'SignalWire');
    is($ret, $a, 'returns self');
    is(scalar @{$a->pronunciations}, 1, 'one pronunciation');
};

subtest 'set_pronunciations' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'sp');
    $a->set_pronunciations([{ replace => 'AI', with => 'Artificial Intelligence' }]);
    is(scalar @{$a->pronunciations}, 1, 'pronunciations replaced');
};

subtest 'pronunciations in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'p_swml');
    $a->add_pronunciation(replace => 'API', with => 'A.P.I.');
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{pronounce}[0]{replace}, 'API', 'pronunciation in SWML');
};

# ============================================================
# 4. Params
# ============================================================
subtest 'set_param' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'p');
    my $ret = $a->set_param('temperature', 0.7);
    is($ret, $a, 'returns self');
    is($a->params->{temperature}, 0.7, 'param set');
};

subtest 'set_params merge' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pm');
    $a->set_param('temperature', 0.7);
    $a->set_params({ top_p => 0.9, presence_penalty => 0.1 });
    is($a->params->{temperature}, 0.7, 'original param preserved');
    is($a->params->{top_p}, 0.9, 'new param merged');
    is($a->params->{presence_penalty}, 0.1, 'another param merged');
};

subtest 'params in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'p_swml');
    $a->set_param('temperature', 0.5);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{params}{temperature}, 0.5, 'params in SWML');
};

# ============================================================
# 5. Global data
# ============================================================
subtest 'set_global_data' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'gd');
    my $ret = $a->set_global_data({ key => 'value' });
    is($ret, $a, 'returns self');
    is($a->global_data->{key}, 'value', 'global data set');
};

subtest 'update_global_data' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'ugd');
    $a->set_global_data({ k1 => 'v1' });
    my $ret = $a->update_global_data({ k2 => 'v2' });
    is($ret, $a, 'returns self');
    is($a->global_data->{k1}, 'v1', 'original preserved');
    is($a->global_data->{k2}, 'v2', 'new key added');
};

subtest 'global_data in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'gd_swml');
    $a->set_global_data({ mode => 'test' });
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{global_data}{mode}, 'test', 'global_data in SWML');
};

# ============================================================
# 6. Native functions
# ============================================================
subtest 'set_native_functions' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'nf');
    my $ret = $a->set_native_functions(['check_for_input']);
    is($ret, $a, 'returns self');
    is_deeply($a->native_functions, ['check_for_input'], 'native functions set');
};

subtest 'native_functions in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'nf_swml');
    $a->set_native_functions(['check_for_input']);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is_deeply($ai[0]{ai}{SWAIG}{native_functions}, ['check_for_input'], 'native functions in SWML');
};

# ============================================================
# 7. Prompt LLM params
# ============================================================
subtest 'set_prompt_llm_params' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'plp');
    my $ret = $a->set_prompt_llm_params(temperature => 0.5, top_p => 0.9);
    is($ret, $a, 'returns self');
    is($a->prompt_llm_params->{temperature}, 0.5, 'temperature set');
    is($a->prompt_llm_params->{top_p}, 0.9, 'top_p set');
};

subtest 'set_prompt_llm_params merge' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'plpm');
    $a->set_prompt_llm_params(temperature => 0.5);
    $a->set_prompt_llm_params(top_p => 0.9);
    is($a->prompt_llm_params->{temperature}, 0.5, 'first param preserved');
    is($a->prompt_llm_params->{top_p}, 0.9, 'second param merged');
};

# ============================================================
# 8. Post-prompt LLM params
# ============================================================
subtest 'set_post_prompt_llm_params' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'pplp');
    my $ret = $a->set_post_prompt_llm_params(temperature => 0.3);
    is($ret, $a, 'returns self');
    is($a->post_prompt_llm_params->{temperature}, 0.3, 'post-prompt param set');
};

# ============================================================
# 9. Internal fillers
# ============================================================
subtest 'set_internal_fillers' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'if');
    my $ret = $a->set_internal_fillers(['one moment', 'please wait']);
    is($ret, $a, 'returns self');
    is_deeply($a->internal_fillers, ['one moment', 'please wait'], 'fillers set');
};

subtest 'add_internal_filler' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'aif');
    $a->add_internal_filler('hold on');
    $a->add_internal_filler('just a sec');
    is(scalar @{$a->internal_fillers}, 2, 'two fillers');
};

subtest 'internal_fillers in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'if_swml');
    $a->set_internal_fillers(['moment']);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is_deeply($ai[0]{ai}{params}{internal_fillers}, ['moment'], 'fillers in SWML');
};

# ============================================================
# 10. Debug events
# ============================================================
subtest 'enable_debug_events' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'de');
    my $ret = $a->enable_debug_events(2);
    is($ret, $a, 'returns self');
    is($a->debug_events_level, 2, 'level set');
};

subtest 'enable_debug_events default' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'de_def');
    $a->enable_debug_events;
    is($a->debug_events_level, 1, 'default level is 1');
};

subtest 'debug_events in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'de_swml');
    $a->enable_debug_events(3);
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{params}{debug_events}, 3, 'debug_events in SWML');
};

# ============================================================
# 11. Function includes
# ============================================================
subtest 'add_function_include' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'fi');
    my $ret = $a->add_function_include({ url => 'https://example.com/swaig', functions => ['f1'] });
    is($ret, $a, 'returns self');
    is(scalar @{$a->function_includes}, 1, 'one include');
};

subtest 'function_includes in SWML' => sub {
    my $a = SignalWire::Agents::Agent::AgentBase->new(name => 'fi_swml');
    $a->add_function_include({ url => 'https://example.com/swaig', functions => ['f1'] });
    my $swml = $a->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(exists $ai[0]{ai}{SWAIG}{includes}, 'includes in SWML');
};

done_testing;
