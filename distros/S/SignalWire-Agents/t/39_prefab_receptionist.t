#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('SignalWire::Agents::Prefabs::Receptionist');

subtest 'construction defaults' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [
            { name => 'sales',   description => 'Sales dept',   number => '+15551235555' },
            { name => 'support', description => 'Support dept', number => '+15551236666' },
        ],
    );
    is($a->name, 'receptionist', 'default name');
    is($a->route, '/receptionist', 'default route');
    ok($a->isa('SignalWire::Agents::Agent::AgentBase'), 'isa AgentBase');
};

subtest 'tools registered' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 'sales', description => 'S', number => '+1' }],
    );
    ok(exists $a->tools->{transfer_to_department}, 'transfer tool');
};

subtest 'prompt section' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 'sales', description => 'S', number => '+1' }],
    );
    ok($a->prompt_has_section('Receptionist Role'), 'has role section');
};

subtest 'global data' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [
            { name => 'sales', description => 'S', number => '+1' },
            { name => 'tech',  description => 'T', number => '+2' },
        ],
    );
    is(scalar @{$a->global_data->{departments}}, 2, 'two departments');
};

subtest 'transfer tool execution - found' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 'sales', description => 'Sales', number => '+15551235555' }],
    );
    my $result = $a->on_function_call('transfer_to_department', { department => 'sales' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/sales/i, 'mentions department');
};

subtest 'transfer tool execution - not found' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 'sales', description => 'Sales', number => '+1' }],
    );
    my $result = $a->on_function_call('transfer_to_department', { department => 'unknown' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/not found/i, 'mentions not found');
};

subtest 'custom greeting' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 's', description => 'S', number => '+1' }],
        greeting    => 'Welcome to Acme!',
    );
    my $pom = $a->pom_sections;
    my ($role) = grep { $_->{title} eq 'Receptionist Role' } @$pom;
    like($role->{body}, qr/Acme/, 'custom greeting in prompt');
};

subtest 'render_swml' => sub {
    my $a = SignalWire::Agents::Prefabs::Receptionist->new(
        departments => [{ name => 's', description => 'S', number => '+1' }],
    );
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version');
};

done_testing;
