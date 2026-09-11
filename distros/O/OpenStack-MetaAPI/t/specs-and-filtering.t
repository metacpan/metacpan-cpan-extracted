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

$Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 1;

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

# =============================================================================
# Test 1: Listable filtering with regex
# =============================================================================
{
    note "=== Listable filtering with regex ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    my @matches = $api->servers(name => qr/^server (one|three)$/);
    is scalar @matches, 2, "regex filter matches exactly 2 servers";
    is [sort map { $_->{name} } @matches],
      ['server one', 'server three'],
      "regex filter returns correct servers";
}

# =============================================================================
# Test 2: Listable filtering returns single result (not a list)
# =============================================================================
{
    note "=== Listable single result returns hashref ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    my $result = $api->servers(name => qr/two/);
    is ref $result, 'HASH', "single regex match returns hashref, not list";
    is $result->{name}, 'server two', "correct server returned";
}

# =============================================================================
# Test 3: Listable filtering with no matches returns undef
# =============================================================================
{
    note "=== Listable filtering with no matches ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    my $result = $api->servers(name => 'nonexistent');
    ok !defined($result), "no match returns undef";
}

# =============================================================================
# Test 4: Listable filtering with multiple criteria
# =============================================================================
{
    note "=== Listable filtering with multiple criteria ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers_with_status()),
    );

    # Filter by both status and name pattern
    my $result = $api->servers(status => 'ACTIVE', name => 'prod-web-1');
    is ref $result, 'HASH', "multi-criteria filter returns hashref";
    is $result->{name}, 'prod-web-1', "correct server matches both criteria";
    is $result->{status}, 'ACTIVE', "status matches";
}

# =============================================================================
# Test 5: Listable filtering where field is missing on some candidates
# =============================================================================
{
    note "=== Listable filtering with missing fields ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers_sparse()),
    );

    # Filter by a field that not all candidates have
    my $result = $api->servers(description => 'important');
    is ref $result, 'HASH', "filter skips candidates missing the field";
    is $result->{name}, 'with-desc', "returns the one with matching field";
}

# =============================================================================
# Test 6: Spec-generated getfromid unwraps single-key responses
# =============================================================================
{
    note "=== getfromid unwraps single-key responses ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        application_json('{"server": {"id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", "name": "test-srv"}}'),
    );

    my $server = $api->server_from_uid('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
    is ref $server, 'HASH', "getfromid returns hashref";
    is $server->{name}, 'test-srv', "single-key response is unwrapped";
    is $server->{id}, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', "id preserved";
}

# =============================================================================
# Test 7: Spec-generated getfromid passes through multi-key responses as-is
# =============================================================================
{
    note "=== getfromid preserves multi-key responses ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/11111111-2222-3333-4444-555555555555',
        application_json('{"server": {"id": "11111111-2222-3333-4444-555555555555"}, "extra": "data"}'),
    );

    my $result = $api->server_from_uid('11111111-2222-3333-4444-555555555555');
    is ref $result, 'HASH', "multi-key response returns hashref";
    ok exists $result->{server}, "multi-key response is NOT unwrapped";
    ok exists $result->{extra}, "extra key preserved";
}

# =============================================================================
# Test 8: Specs query_filters_for validates filter keys against spec
# =============================================================================
{
    note "=== query_filters_for validates against specs ===";

    # The compute v2_1 specs define query filters for /servers:
    # host, flavor, hostname, image, ip
    my $specs = OpenStack::MetaAPI::API::Specs::Compute::v2_1->new();

    # Valid filter
    my $filters = $specs->query_filters_for('/get', '/servers', [host => 'myhost']);
    is $filters, {host => 'myhost'}, "valid filter key passes through";

    # Invalid filter (not in spec)
    my $bad_filters = $specs->query_filters_for('/get', '/servers', [bogus => 'value']);
    ok !defined($bad_filters), "invalid filter key returns undef";

    # Mix of valid and invalid
    my $mixed = $specs->query_filters_for('/get', '/servers', [host => 'myhost', bogus => 'nope', flavor => 'small']);
    is $mixed, {host => 'myhost', flavor => 'small'}, "mixed filters: only valid keys pass";
}

# =============================================================================
# Test 9: Specs query_filters_for handles edge cases
# =============================================================================
{
    note "=== query_filters_for edge cases ===";

    my $specs = OpenStack::MetaAPI::API::Specs::Compute::v2_1->new();

    # Odd number of args (not key-value pairs)
    my $result = $specs->query_filters_for('/get', '/servers', ['only_one']);
    ok !defined($result), "odd number of args returns undef";

    # Empty args
    my $empty = $specs->query_filters_for('/get', '/servers', []);
    ok !defined($empty), "empty args returns undef";

    # Route with no query spec defined
    my $no_spec = $specs->query_filters_for('/get', '/nonexistent', [key => 'val']);
    ok !defined($no_spec), "nonexistent route returns undef";
}

# =============================================================================
# Test 10: Network specs - server-side port filtering
# =============================================================================
{
    note "=== Network specs port filters ===";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/ports?device_id=srv-123',
        application_json(json_for_ports()),
    );

    my $port = $api->ports(device_id => 'srv-123');
    is ref $port, 'HASH', "port filtering returns result";
    is $port->{device_id}, 'srv-123', "port has correct device_id";

    like last_http_request(),
      qr{device_id=srv-123},
      "device_id passed as server-side query filter";
}

# =============================================================================
# Test 11: Routes list_all returns all registered routes
# =============================================================================
{
    note "=== Routes list_all ===";

    my @routes = OpenStack::MetaAPI::Routes->list_all();
    ok scalar @routes > 0, "list_all returns routes";

    # Check some expected routes exist
    my %route_set = map { $_ => 1 } @routes;
    ok $route_set{servers}, "servers route exists";
    ok $route_set{flavors}, "flavors route exists";
    ok $route_set{floatingips}, "floatingips route exists";
    ok $route_set{image_from_uid}, "image_from_uid route exists";
    ok $route_set{create_server}, "create_server route exists";
    ok $route_set{delete_floatingip}, "delete_floatingip route exists";
    ok $route_set{ports}, "ports route exists";
    ok $route_set{security_groups}, "security_groups route exists";
}

# =============================================================================
# Test 12: Specs method generation - error on unknown type
# =============================================================================
{
    note "=== Specs method generation error handling ===";

    require OpenStack::MetaAPI::API::Specs::Roles::Service;

    # Create a minimal specs-like object to test type validation
    my $fake_specs_pkg = 'FakeSpecs::Test';
    {
        no strict 'refs';
        @{"${fake_specs_pkg}::ISA"} = ();
    }

    # We can test query_filters_for validation directly
    my $specs = OpenStack::MetaAPI::API::Specs::Compute::v2_1->new();

    # Missing method argument
    like dies { $specs->query_filters_for(undef, '/servers', []) },
      qr/./,
      "query_filters_for dies with undef method";

    # Missing route argument
    like dies { $specs->query_filters_for('/get', undef, []) },
      qr/./,
      "query_filters_for dies with undef route";

    # Wrong args type
    like dies { $specs->query_filters_for('/get', '/servers', 'not-an-array') },
      qr/./,
      "query_filters_for dies with non-arrayref args";
}

# =============================================================================
# Test 13: Network service spec-generated methods work correctly
# =============================================================================
{
    note "=== Network service spec-generated methods ===";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/security-groups',
        application_json(json_for_security_groups()),
    );

    my @groups = $api->security_groups();
    is scalar @groups, 2, "security_groups returns correct count";
    is $groups[0]->{name}, 'default', "first security group is default";
}

# =============================================================================
# Test 14: Listable filtering with regex on non-string fields is safe
# =============================================================================
{
    note "=== Regex filtering safety on missing/undef fields ===";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    # Filter by a field that doesn't exist on the objects
    my $result = $api->servers(nonexistent_field => qr/anything/);
    ok !defined($result), "regex on missing field returns undef (no crash)";
}

done_testing;

# =============================================================================
# JSON fixtures
# =============================================================================

sub json_for_servers {
    return <<'JSON';
{
   "servers" : [
      {
         "name" : "server one",
         "links" : [],
         "id" : "595bdd3d10d95bb1a570603015bceeee"
      },
      {
         "name" : "server two",
         "id" : "433bef2eda384218df1f3fe032d3c6cc",
         "links" : []
      },
      {
         "id" : "8b6da0864b308971b13d03d6ccd348f5",
         "links" : [],
         "name" : "server three"
      }
   ]
}
JSON
}

sub json_for_servers_with_status {
    return <<'JSON';
{
   "servers" : [
      {
         "name" : "prod-web-1",
         "id" : "aaa111",
         "status" : "ACTIVE",
         "links" : []
      },
      {
         "name" : "prod-web-2",
         "id" : "bbb222",
         "status" : "SHUTOFF",
         "links" : []
      },
      {
         "name" : "staging-web-1",
         "id" : "ccc333",
         "status" : "ACTIVE",
         "links" : []
      }
   ]
}
JSON
}

sub json_for_servers_sparse {
    return <<'JSON';
{
   "servers" : [
      {
         "name" : "no-desc",
         "id" : "aaa111",
         "links" : []
      },
      {
         "name" : "with-desc",
         "id" : "bbb222",
         "description" : "important",
         "links" : []
      },
      {
         "name" : "wrong-desc",
         "id" : "ccc333",
         "description" : "trivial",
         "links" : []
      }
   ]
}
JSON
}

sub json_for_ports {
    return <<'JSON';
{
   "ports" : [
      {
         "id" : "port-uuid-1",
         "device_id" : "srv-123",
         "network_id" : "net-456",
         "status" : "ACTIVE"
      }
   ]
}
JSON
}

sub json_for_security_groups {
    return <<'JSON';
{
   "security_groups" : [
      {
         "id" : "sg-uuid-1",
         "name" : "default",
         "description" : "Default security group"
      },
      {
         "id" : "sg-uuid-2",
         "name" : "web",
         "description" : "Web security group"
      }
   ]
}
JSON
}

__END__
