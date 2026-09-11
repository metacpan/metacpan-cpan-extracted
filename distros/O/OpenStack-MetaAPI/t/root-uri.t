#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test::MockModule;

# Test root_uri() version detection in Service.pm
#
# The bug: root_uri() was supposed to detect when the endpoint URL already
# contains a version path (e.g. http://host:8774/v2.1) and skip prepending
# the version_prefix. Two problems:
#   1. The regex m{:[\d]/v} only matched single-digit ports (never real ones)
#   2. On match, it returned undef instead of $uri

use OpenStack::MetaAPI::API::Service;
use OpenStack::MetaAPI::API::Specs::Default;

# Build a Service with a controlled endpoint, bypassing real auth
sub make_service {
    my (%opts) = @_;

    my $endpoint       = $opts{endpoint} // 'http://127.0.0.1:8774';
    my $version_prefix = $opts{version_prefix};

    # Mock BUILD to skip api_specs setup (which needs real specs)
    my $mock_service = Test::MockModule->new('OpenStack::MetaAPI::API::Service');
    $mock_service->redefine('BUILD' => sub { });

    my %args = (
        auth   => bless({}, 'FakeAuth'),
        name   => 'compute',
        region => 'RegionOne',
        api    => bless({}, 'FakeAPI'),
    );
    $args{version_prefix} = $version_prefix if defined $version_prefix;

    my $svc = OpenStack::MetaAPI::API::Service->new(%args);

    # Inject a mock client with the desired endpoint
    $svc->{client} = bless { _endpoint => $endpoint }, 'FakeClient';

    return $svc;
}

# Minimal mock classes
{
    package FakeAuth;
    package FakeAPI;
    package FakeClient;
    sub endpoint { return $_[0]->{_endpoint} }
    sub get      { }
    sub put      { }
    sub post     { }
    sub delete   { }
}

subtest 'endpoint with version path — no prefix added' => sub {
    # Compute endpoint: http://host:8774/v2.1
    my $svc = make_service(endpoint => 'http://127.0.0.1:8774/v2.1');

    is($svc->root_uri('/servers/abc-123'), '/servers/abc-123',
        'returns uri unchanged when endpoint has version path');

    is($svc->root_uri('/flavors'), '/flavors',
        'simple path unchanged');
};

subtest 'endpoint without version — prefix prepended' => sub {
    # Network endpoint: http://host:9696 (no version in URL)
    my $svc = make_service(
        endpoint       => 'http://127.0.0.1:9696',
        version_prefix => 'v2.0',
    );

    is($svc->root_uri('/floatingips'), 'v2.0/floatingips',
        'prepends version_prefix when endpoint has no version');

    is($svc->root_uri('/networks/abc'), 'v2.0/networks/abc',
        'prepends for resource paths');
};

subtest 'versioned endpoint with version_prefix — no double-versioning' => sub {
    # Edge case: endpoint has version AND service defines version_prefix
    my $svc = make_service(
        endpoint       => 'http://127.0.0.1:9696/v2.0',
        version_prefix => 'v2.0',
    );

    is($svc->root_uri('/floatingips'), '/floatingips',
        'skips prefix when endpoint already has version (prevents double-versioning)');
};

subtest 'uri starting with v returned as-is' => sub {
    my $svc = make_service(endpoint => 'http://127.0.0.1:8774/v2.1');

    is($svc->root_uri('v2.0/networks'), 'v2.0/networks',
        'uri starting with v returned unchanged');
};

subtest 'various endpoint formats' => sub {
    # 5-digit port with version
    my $svc = make_service(endpoint => 'http://host:18774/v2.1');
    is($svc->root_uri('/test'), '/test', '5-digit port with version');

    # Cinder-style: version + project ID in path
    $svc = make_service(endpoint => 'http://host:8776/v3/project-id');
    is($svc->root_uri('/volumes'), '/volumes', 'cinder-style path with project');

    # HTTPS without explicit port, but with version
    $svc = make_service(endpoint => 'https://compute.cloud.example.com/v2.1');
    is($svc->root_uri('/servers'), '/servers', 'HTTPS no-port with version');

    # No version, no prefix
    $svc = make_service(endpoint => 'http://host:9292');
    is($svc->root_uri('/images/abc'), '/images/abc', 'no version no prefix');
};

subtest 'undef input' => sub {
    my $svc = make_service(endpoint => 'http://127.0.0.1:8774/v2.1');
    is($svc->root_uri(undef), undef, 'returns undef for undef input');
};

done_testing;
