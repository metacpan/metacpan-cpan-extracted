#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use JSON;

mock_lwp_useragent();

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

# Servers with falsy-but-valid field values
my $servers_json = encode_json({
    servers => [
        {
            id     => 'aaa11111-1111-1111-1111-111111111111',
            name   => 'server-running',
            status => 'ACTIVE',
            'OS-EXT-STS:power_state' => 1,
        },
        {
            id     => 'bbb22222-2222-2222-2222-222222222222',
            name   => 'server-stopped',
            status => 'SHUTOFF',
            'OS-EXT-STS:power_state' => 0,
        },
        {
            id     => 'ccc33333-3333-3333-3333-333333333333',
            name   => 'server-nogroup',
            status => 'ACTIVE',
            'OS-EXT-STS:power_state' => 1,
            'OS-EXT-SRV-ATTR:host' => '',
        },
    ],
});

mock_get_request(
    'http://127.0.0.1:8774/v2.1/servers',
    application_json($servers_json),
);

{
    note "Filter by numeric zero value (power_state => 0)";

    my $result = $api->servers('OS-EXT-STS:power_state' => 0);

    is $result,
      {
        id     => 'bbb22222-2222-2222-2222-222222222222',
        name   => 'server-stopped',
        status => 'SHUTOFF',
        'OS-EXT-STS:power_state' => 0,
      },
      "filtering by zero value returns the matching server";
}

{
    note "Filter by empty string value (OS-EXT-SRV-ATTR:host => '')";

    my $result = $api->servers('OS-EXT-SRV-ATTR:host' => '');

    is $result,
      {
        id     => 'ccc33333-3333-3333-3333-333333333333',
        name   => 'server-nogroup',
        status => 'ACTIVE',
        'OS-EXT-STS:power_state' => 1,
        'OS-EXT-SRV-ATTR:host' => '',
      },
      "filtering by empty string value returns the matching server";
}

{
    note "Filter by regex on field with zero value";

    my $result = $api->servers('OS-EXT-STS:power_state' => qr/^0$/);

    is $result,
      {
        id     => 'bbb22222-2222-2222-2222-222222222222',
        name   => 'server-stopped',
        status => 'SHUTOFF',
        'OS-EXT-STS:power_state' => 0,
      },
      "regex filter matches zero value";
}

{
    note "Filter by undef field still excludes (field not present)";

    my @results = $api->servers('OS-EXT-SRV-ATTR:hypervisor_hostname' => 'some-host');

    is \@results, [undef],
      "filtering by field not present on entries returns no match";
}

done_testing;
