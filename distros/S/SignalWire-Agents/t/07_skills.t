#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('SignalWire::Agents::Skills::SkillBase');
use_ok('SignalWire::Agents::Skills::SkillManager');
use_ok('SignalWire::Agents::Skills::SkillRegistry');
use_ok('SignalWire::Agents::Agent::AgentBase');

# ============================================================
# 1. SkillRegistry - list all 18 skills
# ============================================================
subtest 'registry lists 18 skills' => sub {
    SignalWire::Agents::Skills::SkillRegistry->clear_registry;
    my $skills = SignalWire::Agents::Skills::SkillRegistry->list_skills;
    is(scalar @$skills, 18, '18 built-in skills registered');

    my @expected = sort qw(
        api_ninjas_trivia claude_skills datasphere datasphere_serverless
        datetime google_maps info_gatherer joke math mcp_gateway
        native_vector_search play_background_file spider swml_transfer
        weather_api web_search wikipedia_search custom_skills
    );
    is_deeply($skills, \@expected, 'all expected skills present');
};

# ============================================================
# 2. SkillRegistry - get_factory
# ============================================================
subtest 'registry get_factory' => sub {
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
    ok(defined $factory, 'datetime factory found');
    is($factory, 'SignalWire::Agents::Skills::Builtin::Datetime', 'correct class');

    my $missing = SignalWire::Agents::Skills::SkillRegistry->get_factory('nonexistent_skill');
    ok(!defined $missing, 'nonexistent skill returns undef');
};

# ============================================================
# 3. SkillBase construction
# ============================================================
subtest 'skill construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'skill_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');

    my $skill = $factory->new(
        agent  => $agent,
        params => {},
    );
    is($skill->skill_name, 'datetime', 'skill_name is datetime');
    is($skill->skill_description, 'Get current date, time, and timezone information', 'description');
    is($skill->skill_version, '1.0.0', 'version');
    ok(!$skill->supports_multiple_instances, 'datetime does not support multiple instances');
};

# ============================================================
# 4. SkillBase - setup and register_tools
# ============================================================
subtest 'skill setup and register' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'skill_reg_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
    my $skill = $factory->new(agent => $agent, params => {});

    ok($skill->setup, 'setup returns true');
    $skill->register_tools;

    ok(exists $agent->tools->{get_current_time}, 'get_current_time registered');
    ok(exists $agent->tools->{get_current_date}, 'get_current_date registered');
};

# ============================================================
# 5. SkillBase - get_hints
# ============================================================
subtest 'skill hints' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'hint_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('google_maps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $hints = $skill->get_hints;
    ok(scalar @$hints > 0, 'google_maps has hints');
    ok(grep({ $_ eq 'address' } @$hints), 'includes address hint');
};

# ============================================================
# 6. SkillBase - get_global_data
# ============================================================
subtest 'skill global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'gdata_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datasphere');
    my $skill = $factory->new(
        agent  => $agent,
        params => { document_id => 'doc123' },
    );
    my $gdata = $skill->get_global_data;
    ok(exists $gdata->{datasphere_enabled}, 'datasphere_enabled in global data');
    is($gdata->{document_id}, 'doc123', 'document_id in global data');
};

# ============================================================
# 7. SkillBase - get_prompt_sections
# ============================================================
subtest 'skill prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'prompt_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    ok(scalar @$sections > 0, 'datetime has prompt sections');
    is($sections->[0]{title}, 'Date and Time Information', 'correct section title');
};

# ============================================================
# 8. SkillBase - skip_prompt
# ============================================================
subtest 'skill skip_prompt' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'skip_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
    my $skill = $factory->new(agent => $agent, params => { skip_prompt => 1 });
    my $sections = $skill->get_prompt_sections;
    is(scalar @$sections, 0, 'sections empty when skip_prompt is set');
};

# ============================================================
# 9. SkillBase - get_instance_key
# ============================================================
subtest 'skill instance key' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'key_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('api_ninjas_trivia');

    my $skill1 = $factory->new(agent => $agent, params => {});
    is($skill1->get_instance_key, 'api_ninjas_trivia', 'default instance key');

    my $skill2 = $factory->new(agent => $agent, params => { tool_name => 'custom_trivia' });
    is($skill2->get_instance_key, 'api_ninjas_trivia:custom_trivia', 'custom instance key');
};

# ============================================================
# 10. SkillBase - get_parameter_schema
# ============================================================
subtest 'skill parameter schema' => sub {
    my $schema = SignalWire::Agents::Skills::Builtin::Datetime->get_parameter_schema;
    ok(exists $schema->{swaig_fields}, 'base schema has swaig_fields');
    ok(exists $schema->{skip_prompt}, 'base schema has skip_prompt');
    ok(exists $schema->{tool_name}, 'base schema has tool_name');
};

# ============================================================
# 11. SkillManager - load_skill
# ============================================================
subtest 'manager load_skill' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'mgr_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    my ($ok, $err) = $mgr->load_skill('datetime');
    ok($ok, 'datetime loaded successfully') or diag($err);

    # Tools should be registered on the agent
    ok(exists $agent->tools->{get_current_time}, 'tool registered on agent');

    # Hints should be merged (datetime has empty hints, check it doesn't crash)
    ok(ref $agent->hints eq 'ARRAY', 'hints array intact');
};

# ============================================================
# 12. SkillManager - duplicate prevention
# ============================================================
subtest 'manager duplicate prevention' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dup_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    my ($ok1, $err1) = $mgr->load_skill('datetime');
    ok($ok1, 'first load succeeds');

    my ($ok2, $err2) = $mgr->load_skill('datetime');
    ok(!$ok2, 'duplicate load fails');
    like($err2, qr/already loaded/, 'error mentions already loaded');
};

# ============================================================
# 13. SkillManager - multiple instances
# ============================================================
subtest 'manager multiple instances' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'multi_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    my ($ok1, $err1) = $mgr->load_skill('api_ninjas_trivia', undef, { tool_name => 'trivia1' });
    ok($ok1, 'first trivia instance loaded') or diag($err1);

    my ($ok2, $err2) = $mgr->load_skill('api_ninjas_trivia', undef, { tool_name => 'trivia2' });
    ok($ok2, 'second trivia instance loaded') or diag($err2);
};

# ============================================================
# 14. SkillManager - list and has_skill
# ============================================================
subtest 'manager list and has' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'list_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    $mgr->load_skill('math');
    my $list = $mgr->list_skills;
    ok(scalar @$list >= 1, 'list has at least one skill');
    ok($mgr->has_skill('math'), 'has math skill');
    ok(!$mgr->has_skill('nonexistent'), 'does not have nonexistent skill');
};

# ============================================================
# 15. SkillManager - unload_skill
# ============================================================
subtest 'manager unload' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'unload_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    $mgr->load_skill('math');
    ok($mgr->has_skill('math'), 'math loaded');

    my $removed = $mgr->unload_skill('math');
    ok($removed, 'unload returns true');
    ok(!$mgr->has_skill('math'), 'math no longer loaded');
};

# ============================================================
# 16. SkillManager - nonexistent skill
# ============================================================
subtest 'manager nonexistent skill' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'noexist_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    my ($ok, $err) = $mgr->load_skill('totally_fake_skill');
    ok(!$ok, 'nonexistent skill fails to load');
    like($err, qr/not found/, 'error mentions not found');
};

# ============================================================
# 17. Agent add_skill integration
# ============================================================
subtest 'agent add_skill' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'add_skill_test');
    my ($ok, $err) = $agent->add_skill('datetime');
    ok($ok, 'add_skill succeeds') or diag($err);
    ok($agent->has_skill('datetime'), 'agent has_skill returns true');
    ok(exists $agent->tools->{get_current_time}, 'tool registered on agent');
};

# ============================================================
# 18. SkillManager - hints and global data merged
# ============================================================
subtest 'manager merges hints and global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'merge_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    $mgr->load_skill('google_maps');
    ok(grep({ $_ eq 'address' } @{$agent->hints}), 'google_maps hints merged');
};

# ============================================================
# 19. SkillManager - prompt sections merged
# ============================================================
subtest 'manager merges prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'sec_merge_test');
    my $mgr = SignalWire::Agents::Skills::SkillManager->new(agent => $agent);

    $mgr->load_skill('datetime');
    ok($agent->prompt_has_section('Date and Time Information'), 'datetime prompt section added to agent');
};

# ============================================================
# 20. All 18 skills instantiate
# ============================================================
subtest 'all 18 skills instantiate' => sub {
    my @skill_names = qw(
        api_ninjas_trivia claude_skills datasphere datasphere_serverless
        datetime google_maps info_gatherer joke math mcp_gateway
        native_vector_search play_background_file spider swml_transfer
        weather_api web_search wikipedia_search custom_skills
    );

    for my $name (@skill_names) {
        my $agent = SignalWire::Agents::Agent::AgentBase->new(name => "test_$name");
        my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory($name);
        ok(defined $factory, "$name: factory found");

        my $skill = eval { $factory->new(agent => $agent, params => {}) };
        ok(defined $skill, "$name: instantiated") or diag($@);
        is($skill->skill_name, $name, "$name: correct skill_name");

        my $ok = eval { $skill->setup };
        ok($ok, "$name: setup succeeds") or diag($@);

        eval { $skill->register_tools };
        ok(!$@, "$name: register_tools succeeds") or diag($@);
    }
};

# ============================================================
# 21. Skills with tool_name override
# ============================================================
subtest 'skill tool_name override' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'override_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('weather_api');
    my $skill = $factory->new(
        agent  => $agent,
        params => { tool_name => 'my_weather', api_key => 'test-key' },
    );
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{my_weather}, 'custom tool name registered');
    ok(!exists $agent->tools->{get_weather}, 'default tool name not used');
};

# ============================================================
# 22. SkillBase - swaig_fields extraction
# ============================================================
subtest 'swaig_fields extraction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'swaig_fields_test');
    my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
    my $skill = $factory->new(
        agent  => $agent,
        params => { swaig_fields => { fillers => { en => ['one moment'] } } },
    );
    ok(exists $skill->swaig_fields->{fillers}, 'swaig_fields extracted from params');
    ok(!exists $skill->params->{swaig_fields}, 'swaig_fields removed from params');
};

done_testing;
