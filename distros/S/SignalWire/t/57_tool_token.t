#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use SignalWire::Agent::AgentBase;

# Parity with signalwire-python:
#   tests/unit/core/test_agent_base.py::TestAgentBaseTokenMethods::test_validate_tool_token
#   tests/unit/core/test_agent_base.py::TestAgentBaseTokenMethods::test_create_tool_token
#
# Python's StateMixin._create_tool_token catches all exceptions and returns ""
# on failure. validate_tool_token rejects unknown function names up front.

sub make_agent_with_tool {
    my $a = SignalWire::Agent::AgentBase->new(name => 'test_agent');
    $a->define_tool(
        name        => 'test_tool',
        description => 't',
        parameters  => {},
        secure      => 1,
        handler     => sub { return { response => 'ok' } },
    );
    return $a;
}

subtest 'create_tool_token round-trip' => sub {
    my $agent = make_agent_with_tool();
    my $token = $agent->create_tool_token('test_tool', 'call_123');
    isnt($token, '', 'expected non-empty SessionManager-issued token');
    ok(
        $agent->validate_tool_token('test_tool', $token, 'call_123'),
        'validate_tool_token accepts the token we just created',
    );
};

subtest 'validate_tool_token rejects unknown function' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'test_agent');
    ok(
        !$agent->validate_tool_token('not_registered', 'any_token', 'call_123'),
        'expected false for unregistered function',
    );
};

subtest 'validate_tool_token rejects bad token' => sub {
    my $agent = make_agent_with_tool();
    ok(
        !$agent->validate_tool_token('test_tool', 'garbage_token_value', 'call_123'),
        'expected false for garbage token',
    );
};

subtest 'validate_tool_token rejects wrong call_id' => sub {
    my $agent = make_agent_with_tool();
    my $token = $agent->create_tool_token('test_tool', 'call_A');
    isnt($token, '', 'token minted for call_A');
    ok(
        !$agent->validate_tool_token('test_tool', $token, 'call_B'),
        'expected false when token bound to a different call_id',
    );
};

done_testing();
