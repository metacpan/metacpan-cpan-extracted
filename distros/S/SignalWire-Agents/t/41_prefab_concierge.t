#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agents::Prefabs::Concierge');

subtest 'construction defaults' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Grand Hotel',
        services   => ['room service'],
        amenities  => { pool => { hours => '9-5' } },
    );
    is($a->name, 'concierge', 'default name');
    is($a->route, '/concierge', 'default route');
    ok($a->isa('SignalWire::Agents::Agent::AgentBase'), 'isa AgentBase');
};

subtest 'tools registered' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Hotel',
        services   => ['room service'],
        amenities  => { pool => {} },
    );
    ok(exists $a->tools->{check_availability}, 'check_availability tool');
};

subtest 'prompt sections' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name           => 'Hotel',
        services             => ['room service', 'spa'],
        amenities            => { pool => { hours => '9-5', location => '2F' } },
        hours_of_operation   => { Monday => '9-5' },
        special_instructions => ['VIP priority'],
    );
    ok($a->prompt_has_section('Concierge Role'), 'role');
    ok($a->prompt_has_section('Available Services'), 'services');
    ok($a->prompt_has_section('Amenities'), 'amenities');
    ok($a->prompt_has_section('Hours of Operation'), 'hours');
    ok($a->prompt_has_section('Special Instructions'), 'instructions');
};

subtest 'global data' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Test Hotel',
        services   => ['room service'],
        amenities  => { pool => {} },
    );
    is($a->global_data->{venue_name}, 'Test Hotel', 'venue in global data');
};

subtest 'tool execution' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Hotel',
        services   => ['room service'],
        amenities  => { pool => {} },
    );
    my $result = $a->on_function_call('check_availability', { service => 'pool' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/pool/, 'mentions service');
};

subtest 'render_swml' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Hotel',
        services   => ['room service'],
        amenities  => { pool => {} },
    );
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version');
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    is($ai[0]{ai}{global_data}{venue_name}, 'Hotel', 'venue in SWML');
};

subtest 'custom welcome message' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name      => 'Hotel',
        services        => ['rs'],
        amenities       => {},
        welcome_message => 'Custom welcome!',
    );
    my $pom = $a->pom_sections;
    my ($role) = grep { $_->{title} eq 'Concierge Role' } @$pom;
    like($role->{body}, qr/Custom welcome/, 'custom welcome in prompt');
};

subtest 'no optional sections' => sub {
    my $a = SignalWire::Agents::Prefabs::Concierge->new(
        venue_name => 'Minimal',
        services   => [],
        amenities  => {},
    );
    ok(!$a->prompt_has_section('Available Services'), 'no services section when empty');
    ok(!$a->prompt_has_section('Amenities'), 'no amenities section when empty');
    ok(!$a->prompt_has_section('Hours of Operation'), 'no hours section when empty');
    ok(!$a->prompt_has_section('Special Instructions'), 'no instructions section when empty');
};

done_testing;
