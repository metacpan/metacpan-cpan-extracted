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

mock_lwp_useragent();

# ============================================================
# Specs::Roles::Service — query_filters_for
# ============================================================
{
    note "Testing Specs::Roles::Service query_filters_for";

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object" or die;

    my $route = $api->route;
    my $compute = $route->service('compute');
    my $specs = $compute->api_specs;

    # query_filters_for with valid filters for /servers
    {
        my $filters = $specs->query_filters_for('/get', '/servers', [host => 'myhost', image => 'img-1']);
        ok ref $filters eq 'HASH', "query_filters_for returns hashref for valid filters";
        is $filters->{host}, 'myhost', "host filter passed through";
        is $filters->{image}, 'img-1', "image filter passed through";
    }

    # query_filters_for ignores unknown filters
    {
        my $filters = $specs->query_filters_for('/get', '/servers', [unknown_param => 'val']);
        ok !defined $filters, "query_filters_for returns undef for unknown-only filters";
    }

    # query_filters_for with mixed known/unknown filters
    {
        my $filters = $specs->query_filters_for('/get', '/servers', [host => 'h1', bogus => 'x']);
        ok ref $filters eq 'HASH', "mixed filters return hashref";
        is $filters->{host}, 'h1', "known filter kept";
        ok !exists $filters->{bogus}, "unknown filter excluded";
    }

    # query_filters_for with odd number of args (not key-value pairs)
    {
        my $filters = $specs->query_filters_for('/get', '/servers', ['just_one']);
        ok !defined $filters, "odd-number args returns undef";
    }

    # query_filters_for with empty args
    {
        my $filters = $specs->query_filters_for('/get', '/servers', []);
        ok !defined $filters, "empty args returns undef";
    }

    # query_filters_for dies on missing method
    {
        like(
            dies { $specs->query_filters_for(undef, '/servers', []) },
            qr/.+/,
            "query_filters_for dies on undef method"
        );
    }

    # query_filters_for dies on non-arrayref args
    {
        like(
            dies { $specs->query_filters_for('/get', '/servers', 'not_an_array') },
            qr/.+/,
            "query_filters_for dies on non-arrayref args"
        );
    }
}

# ============================================================
# Specs::Roles::Service — specs lazy loading and structure
# ============================================================
{
    note "Testing specs structure";

    my $api = get_api_object(use_env => 0);
    my $route = $api->route;
    my $compute = $route->service('compute');
    my $specs = $compute->api_specs;

    my $spec_data = $specs->specs;
    ok ref $spec_data eq 'HASH', "specs returns a hashref";
    ok exists $spec_data->{get}, "specs has 'get' section";
    ok exists $spec_data->{post}, "specs has 'post' section (populated default)";
    ok exists $spec_data->{put}, "specs has 'put' section (populated default)";
    ok exists $spec_data->{delete}, "specs has 'delete' section";

    # get() accessor for a known route
    my $servers_spec = $specs->get('/servers');
    ok ref $servers_spec eq 'HASH', "get('/servers') returns spec hashref";
    is $servers_spec->{perl_api}{method}, 'servers', "perl_api method is 'servers'";
    is $servers_spec->{perl_api}{type}, 'listable', "perl_api type is 'listable'";

    # get() for unknown route returns undef
    my $unknown = $specs->get('/nonexistent');
    ok !defined $unknown, "get() returns undef for unknown route";
}

# ============================================================
# Listable role — _list with filtering
# ============================================================
{
    note "Testing Listable _list via servers()";

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object for listable test" or die;

    # Multiple servers
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json('{"servers": [
            {"id": "aaa-111", "name": "web-1", "status": "ACTIVE"},
            {"id": "bbb-222", "name": "web-2", "status": "ACTIVE"},
            {"id": "ccc-333", "name": "db-1", "status": "SHUTOFF"}
        ]}'),
    );

    # No filter — returns all 3
    my @all = $api->servers();
    is scalar(@all), 3, "servers() returns all 3 servers without filter";

    # Exact filter on name
    my $db = $api->servers(name => 'db-1');
    ok ref $db eq 'HASH', "single result returns hashref";
    is $db->{name}, 'db-1', "exact name filter works";

    # Exact filter on status
    my @active = $api->servers(status => 'ACTIVE');
    is scalar(@active), 2, "status filter returns matching servers";

    # Regexp filter
    my @web = $api->servers(name => qr/^web-/);
    is scalar(@web), 2, "regexp filter matches web-* servers";

    # Filter with no matches returns undef (single result path with 0 items)
    my $none = $api->servers(name => 'nonexistent-server');
    ok !defined $none, "filter with no matches returns undef";
}

# ============================================================
# GetFromId role — _get_from_id_spec via server_from_uid
# ============================================================
{
    note "Testing GetFromId via server_from_uid";

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object for getfromid test" or die;

    my $server_uid = 'abcdef01-2345-6789-abcd-ef0123456789';
    mock_get_request(
        "http://127.0.0.1:8774/v2.1/servers/$server_uid",
        application_json('{"server": {"id": "abcdef01-2345-6789-abcd-ef0123456789", "name": "my-server", "status": "ACTIVE"}}'),
    );

    my $server = $api->server_from_uid($server_uid);
    ok ref $server eq 'HASH', "server_from_uid returns hashref";
    is $server->{id}, $server_uid, "correct server id returned";
    is $server->{name}, 'my-server', "server name unwrapped from single-key hash";
}

# ============================================================
# Service.pm — setup_method and can_method
# ============================================================
{
    note "Testing Service setup_method / can_method";

    my $api = get_api_object(use_env => 0);
    my $route = $api->route;
    my $compute = $route->service('compute');

    # can_method finds dynamically registered methods
    my $servers_sub = $compute->can_method('servers');
    ok defined $servers_sub, "can_method finds dynamically registered 'servers'";
    ok ref $servers_sub eq 'CODE', "can_method returns a coderef";

    # can_method returns undef for unknown methods
    my $unknown = $compute->can_method('totally_unknown_method');
    ok !defined $unknown, "can_method returns undef for unknown method";

    # setup_method rejects duplicate registration
    like(
        dies { $compute->setup_method('servers', sub { 1 }) },
        qr/Method 'servers' already exists/,
        "setup_method rejects duplicate method name"
    );
}

# ============================================================
# Service.pm — root_uri
# ============================================================
{
    note "Testing Service root_uri";

    my $api = get_api_object(use_env => 0);
    my $route = $api->route;
    my $compute = $route->service('compute');

    # URI already containing version prefix is returned as-is
    is $compute->root_uri('v2.1/servers'), 'v2.1/servers',
        "root_uri returns versioned URI unchanged";

    # undef returns undef
    is $compute->root_uri(undef), undef, "root_uri returns undef for undef input";
}

# ============================================================
# Service.pm — BUILD_version
# ============================================================
{
    note "Testing Service BUILD_version";

    my $api = get_api_object(use_env => 0);
    my $route = $api->route;
    my $compute = $route->service('compute');

    # Compute endpoint is http://127.0.0.1:8774/v2.1
    is $compute->version, 'v2.1', "BUILD_version extracts version from endpoint URL";
}

done_testing;
