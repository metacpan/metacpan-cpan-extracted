#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agent::AgentBase');

# ============================================================
# 1. define_tool basic registration
# ============================================================
subtest 'define_tool basic' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tool');
    my $ret = $agent->define_tool(
        name        => 'greet',
        description => 'Greet someone',
        parameters  => {
            type => 'object',
            properties => { name => { type => 'string' } },
            required => ['name'],
        },
        handler => sub { { response => "Hello $_[0]->{name}" } },
    );
    is($ret, $agent, 'returns self');
    ok(exists $agent->tools->{greet}, 'tool registered');
    is($agent->tools->{greet}{function}, 'greet', 'function name stored');
    is($agent->tools->{greet}{description}, 'Greet someone', 'description stored');
    is(scalar @{$agent->tool_order}, 1, 'tool_order has one entry');
};

# ============================================================
# 2. define_tool without handler
# ============================================================
subtest 'define_tool no handler' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_handler');
    $agent->define_tool(name => 'stub', description => 'stub tool');
    ok(exists $agent->tools->{stub}, 'tool registered');
    ok(!exists $agent->tools->{stub}{_handler}, 'no handler');
    my $result = $agent->on_function_call('stub', {}, {});
    ok(!defined $result, 'on_function_call returns undef without handler');
};

# ============================================================
# 3. define_tool requires name
# ============================================================
subtest 'define_tool requires name' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'noname');
    eval { $agent->define_tool(description => 'No name') };
    ok($@, 'dies without name');
};

# ============================================================
# 4. on_function_call dispatch
# ============================================================
subtest 'on_function_call dispatch' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'dispatch');
    $agent->define_tool(
        name    => 'add',
        handler => sub { { response => "sum=" . ($_[0]->{a} + $_[0]->{b}) } },
    );
    my $result = $agent->on_function_call('add', { a => 3, b => 4 }, {});
    is($result->{response}, 'sum=7', 'handler receives args');
};

subtest 'on_function_call missing function' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'missing');
    my $result = $agent->on_function_call('nonexistent', {}, {});
    ok(!defined $result, 'returns undef for missing');
};

# ============================================================
# 5. on_function_call with raw_data
# ============================================================
subtest 'on_function_call raw data' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'raw');
    $agent->define_tool(
        name    => 'check',
        handler => sub {
            my ($args, $raw) = @_;
            return { response => "raw_exists=" . (defined $raw ? 'yes' : 'no') };
        },
    );
    my $result = $agent->on_function_call('check', {}, { call_id => '123' });
    is($result->{response}, 'raw_exists=yes', 'raw data passed to handler');
};

# ============================================================
# 6. register_swaig_function (DataMap style)
# ============================================================
subtest 'register_swaig_function' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'swaig');
    $agent->register_swaig_function({
        function    => 'weather',
        description => 'Get weather',
        parameters  => { type => 'object', properties => {} },
        data_map    => { webhooks => [{ url => 'https://api.test.com', method => 'GET' }] },
    });
    ok(exists $agent->tools->{weather}, 'swaig function registered');
    ok(exists $agent->tools->{weather}{data_map}, 'data_map preserved');
    is($agent->tools->{weather}{data_map}{webhooks}[0]{method}, 'GET', 'data_map content intact');
};

subtest 'register_swaig_function requires function key' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'no_func');
    eval { $agent->register_swaig_function({ description => 'No function key' }) };
    ok($@, 'dies without function key');
};

# ============================================================
# 7. define_tools (multiple)
# ============================================================
subtest 'define_tools multiple' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'multi');
    $agent->define_tools(
        { name => 'tool_a', description => 'A' },
        { function => 'tool_b', description => 'B', parameters => {} },
    );
    ok(exists $agent->tools->{tool_a}, 'tool_a registered via define_tool');
    ok(exists $agent->tools->{tool_b}, 'tool_b registered via register_swaig_function');
    is(scalar @{$agent->tool_order}, 2, 'two tools in order');
};

# ============================================================
# 8. Tool order preservation
# ============================================================
subtest 'tool order preserved' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'order');
    $agent->define_tool(name => 'first',  description => '1');
    $agent->define_tool(name => 'second', description => '2');
    $agent->define_tool(name => 'third',  description => '3');
    is_deeply($agent->tool_order, ['first', 'second', 'third'], 'order preserved');
};

# ============================================================
# 9. Duplicate tool name does not duplicate order
# ============================================================
subtest 'duplicate tool name no order dup' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'dup');
    $agent->define_tool(name => 'tool1', description => 'v1');
    $agent->define_tool(name => 'tool1', description => 'v2');
    is(scalar @{$agent->tool_order}, 1, 'no duplicate in tool_order');
    is($agent->tools->{tool1}{description}, 'v2', 'tool overwritten');
};

# ============================================================
# 10. Extra fields in define_tool
# ============================================================
subtest 'extra fields in define_tool' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'extra');
    $agent->define_tool(
        name         => 'tool_x',
        description  => 'X',
        fillers      => { en => ['one moment'] },
        meta_data_token => 'abc123',
    );
    is($agent->tools->{tool_x}{fillers}{en}[0], 'one moment', 'fillers preserved');
    is($agent->tools->{tool_x}{meta_data_token}, 'abc123', 'meta_data_token preserved');
};

# ============================================================
# 11. Tools in rendered SWML
# ============================================================
subtest 'tools in SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'swml_tools');
    $agent->define_tool(
        name        => 'my_tool',
        description => 'My tool',
        parameters  => { type => 'object', properties => {} },
        handler     => sub { { response => 'ok' } },
    );
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $funcs = $ai[0]{ai}{SWAIG}{functions};
    is(scalar @$funcs, 1, 'one function in SWML');
    is($funcs->[0]{function}, 'my_tool', 'function name in SWML');
    ok(!exists $funcs->[0]{_handler}, 'handler stripped from SWML');
    ok(exists $funcs->[0]{web_hook_url}, 'web_hook_url set');
};

# ============================================================
# 12. DataMap tool in SWML (no handler, has data_map)
# ============================================================
subtest 'DataMap tool in SWML' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'dm_swml');
    $agent->register_swaig_function({
        function    => 'dm_tool',
        description => 'DM tool',
        parameters  => { type => 'object', properties => {} },
        data_map    => { webhooks => [{ url => 'https://api.test.com', method => 'GET', output => { response => 'ok' } }] },
    });
    my $swml = $agent->render_swml;
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    my $func = $ai[0]{ai}{SWAIG}{functions}[0];
    is($func->{function}, 'dm_tool', 'DataMap tool in SWML');
    ok(exists $func->{data_map}, 'data_map preserved in SWML');
};

done_testing;
