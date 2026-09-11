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

# ----------------------------------------------------------------
# Routes: list_all returns all known routes
# ----------------------------------------------------------------
{
    note "Testing Routes::list_all";

    my @routes = OpenStack::MetaAPI::Routes->list_all();
    ok scalar @routes > 0, "list_all returns routes";

    # verify some expected routes exist
    my %route_set = map { $_ => 1 } @routes;
    ok $route_set{servers},         "servers route exists";
    ok $route_set{flavors},         "flavors route exists";
    ok $route_set{networks},        "networks route exists";
    ok $route_set{floatingips},     "floatingips route exists";
    ok $route_set{security_groups}, "security_groups route exists";
    ok $route_set{image_from_uid},  "image_from_uid route exists";
    ok $route_set{image_from_name}, "image_from_name route exists";
    ok $route_set{keypairs},        "keypairs route exists";
    ok $route_set{ports},           "ports route exists";
    ok $route_set{port_from_uid},   "port_from_uid route exists";
}

# ----------------------------------------------------------------
# Routes: unknown function dies
# ----------------------------------------------------------------
{
    note "Testing unknown route";

    like(
        dies { $api->route->this_route_does_not_exist() },
        qr/Unknown function this_route_does_not_exist/,
        "calling unknown route dies with descriptive message"
    );
}

# ----------------------------------------------------------------
# Filtering: regex filter on list results
# ----------------------------------------------------------------
{
    note "Testing regex filtering";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    # regex filter: match names containing "alpha"
    my @alpha = $api->servers(name => qr/alpha/);
    is scalar @alpha, 2, "regex filter matches two alpha servers";

    # regex filter: case-insensitive
    my @upper = $api->servers(name => qr/BRAVO/i);
    is $upper[0]->{name}, "bravo-1", "case-insensitive regex filter works";

    # regex filter: no matches returns undef (single-element list squashed)
    my $none = $api->servers(name => qr/zzzznotfound/);
    ok !defined $none, "regex filter with no matches returns undef";
}

# ----------------------------------------------------------------
# Filtering: exact match
# ----------------------------------------------------------------
{
    note "Testing exact match filtering";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    my $server = $api->servers(name => 'bravo-1');
    is $server->{id}, 'bbbb-2222-3333-4444', "exact match by name works";

    # exact match: value that doesn't exist
    my $missing = $api->servers(name => 'nonexistent-server');
    ok !defined $missing, "exact match with no result returns undef";
}

# ----------------------------------------------------------------
# Filtering: multiple fields
# ----------------------------------------------------------------
{
    note "Testing multi-field filtering";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    # filter by both name regex and status
    my $server = $api->servers(name => qr/alpha/, status => 'BUILD');
    is $server->{name}, 'alpha-2',
        "multi-field filter narrows results correctly";
}

# ----------------------------------------------------------------
# look_by_id_or_name: lookup by name
# ----------------------------------------------------------------
{
    note "Testing look_by_id_or_name with name";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/flavors',
        application_json(json_for_flavors()),
    );

    my $flavor = $api->look_by_id_or_name(flavors => 'small');
    is $flavor->{name}, 'small', "look_by_id_or_name finds flavor by name";
    is $flavor->{id}, '2', "returns correct flavor id";
}

# ----------------------------------------------------------------
# look_by_id_or_name: lookup by ID (numeric, flavor-style)
# ----------------------------------------------------------------
{
    note "Testing look_by_id_or_name with numeric ID";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/flavors',
        application_json(json_for_flavors()),
    );

    # "2" looks like a valid ID (hex chars), so it tries ID lookup first
    my $flavor = $api->look_by_id_or_name(flavors => '2');
    is $flavor->{id}, '2', "look_by_id_or_name finds flavor by numeric id";
}

# ----------------------------------------------------------------
# look_by_id_or_name: dies on missing resource
# ----------------------------------------------------------------
{
    note "Testing look_by_id_or_name with missing resource";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/flavors',
        application_json(json_for_flavors()),
    );

    like(
        dies { $api->look_by_id_or_name(flavors => 'does-not-exist-flavor') },
        qr{Cannot find 'flavors' for id/name 'does-not-exist-flavor'},
        "look_by_id_or_name dies with descriptive message for missing resource"
    );
}

# ----------------------------------------------------------------
# Service: keypairs route
# ----------------------------------------------------------------
{
    note "Testing keypairs route";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/os-keypairs',
        application_json(json_for_keypairs()),
    );

    my @kps = $api->keypairs();
    is scalar @kps, 2, "keypairs returns two entries";
    is $kps[0]->{keypair}{name}, 'key-one', "first keypair name correct";
    is $kps[1]->{keypair}{name}, 'key-two', "second keypair name correct";
}

# ----------------------------------------------------------------
# Service: networks route
# ----------------------------------------------------------------
{
    note "Testing networks route";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/networks',
        application_json(json_for_networks()),
    );

    my @nets = $api->networks();
    is scalar @nets, 2, "networks returns two entries";
    is $nets[0]->{name}, 'prod-net', "first network name correct";
    is $nets[1]->{name}, 'dev-net',  "second network name correct";

    # filter networks by name
    my $net = $api->networks(name => 'dev-net');
    is $net->{id}, 'db193ab3-96e3-4cb3-8fc5-05f4296d0324',
        "filter network by name returns correct entry";
}

# ----------------------------------------------------------------
# Service: ports route
# ----------------------------------------------------------------
{
    note "Testing ports route";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/ports',
        application_json(json_for_ports()),
    );

    my $port = $api->ports();
    is $port->{id}, 'd80b1a3b-4fc1-49f3-952e-1e2ab7081d8b',
        "ports returns single port (squashed from list)";
    is $port->{device_id}, 'aaaaa-bbbb-ccccc-dddd',
        "port has correct device_id";
}

done_testing;

# ----------------------------------------------------------------
# Test data fixtures
# ----------------------------------------------------------------

sub json_for_servers {
    return <<'JSON';
{
    "servers": [
        {
            "id": "aaaa-1111-2222-3333",
            "name": "alpha-1",
            "status": "ACTIVE"
        },
        {
            "id": "aaaa-1111-2222-4444",
            "name": "alpha-2",
            "status": "BUILD"
        },
        {
            "id": "bbbb-2222-3333-4444",
            "name": "bravo-1",
            "status": "ACTIVE"
        },
        {
            "id": "cccc-3333-4444-5555",
            "name": "charlie-1",
            "status": "ACTIVE"
        }
    ]
}
JSON
}

sub json_for_flavors {
    return <<'JSON';
{
    "flavors": [
        {
            "id": "1",
            "name": "tiny"
        },
        {
            "id": "2",
            "name": "small"
        },
        {
            "id": "3",
            "name": "medium"
        }
    ]
}
JSON
}

sub json_for_keypairs {
    return <<'JSON';
{
    "keypairs": [
        {
            "keypair": {
                "fingerprint": "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99",
                "name": "key-one",
                "public_key": "ssh-rsa AAAA... user@host"
            }
        },
        {
            "keypair": {
                "fingerprint": "11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff:00",
                "name": "key-two",
                "public_key": "ssh-rsa BBBB... user@host"
            }
        }
    ]
}
JSON
}

sub json_for_networks {
    return <<'JSON';
{
    "networks": [
        {
            "id": "d32019d3-bc6e-4319-9c1d-6722fc136a22",
            "name": "prod-net",
            "status": "ACTIVE",
            "admin_state_up": true,
            "project_id": "4fd44f30292945e481c7b8a0c8908869",
            "shared": false,
            "subnets": ["54d6f61d-db07-451c-9ab3-b9609b6b6f0b"]
        },
        {
            "id": "db193ab3-96e3-4cb3-8fc5-05f4296d0324",
            "name": "dev-net",
            "status": "ACTIVE",
            "admin_state_up": true,
            "project_id": "26a7980765d0414dbc1fc1f88cdb7e6e",
            "shared": false,
            "subnets": ["08eae331-0402-425a-923c-34f7cfe39c1b"]
        }
    ]
}
JSON
}

sub json_for_ports {
    return <<'JSON';
{
    "ports": [
        {
            "id": "d80b1a3b-4fc1-49f3-952e-1e2ab7081d8b",
            "name": "",
            "network_id": "70c1db1f-b701-45bd-96e0-a313ee3430b3",
            "admin_state_up": true,
            "device_id": "aaaaa-bbbb-ccccc-dddd",
            "device_owner": "compute:nova",
            "mac_address": "fa:16:3e:58:42:ed",
            "status": "ACTIVE"
        }
    ]
}
JSON
}

__END__
