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

use OpenStack::MetaAPI::Routes;

# --- list_all returns the expected route names ---
{
    my @routes = OpenStack::MetaAPI::Routes->list_all();

    ok scalar(@routes) > 0, "list_all returns routes";

    my %route_set = map { $_ => 1 } @routes;

    ok $route_set{servers},       "routes include 'servers'";
    ok $route_set{flavors},       "routes include 'flavors'";
    ok $route_set{keypairs},      "routes include 'keypairs'";
    ok $route_set{floatingips},   "routes include 'floatingips'";
    ok $route_set{networks},      "routes include 'networks'";
    ok $route_set{image_from_uid}, "routes include 'image_from_uid'";
    ok $route_set{create_server}, "routes include 'create_server'";
    ok $route_set{delete_server}, "routes include 'delete_server'";

    # list_all returns sorted
    my @sorted = sort @routes;
    is \@routes, \@sorted, "list_all returns routes in sorted order";
}

# --- AUTOLOAD dispatches to the correct service ---
{
    mock_lwp_useragent();

    $Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 0;

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object" or die;

    # Mock a servers endpoint
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json('{"servers": [{"id": "abc-123", "name": "test-server"}]}'),
    );

    my @servers = $api->servers();
    ok scalar(@servers) >= 1, "AUTOLOAD dispatched servers() to compute service";
    is $servers[0]->{name}, 'test-server', "server data returned correctly";
}

# --- AUTOLOAD dies on unknown method ---
{
    mock_lwp_useragent();

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object for unknown method test" or die;

    like(
        dies { $api->completely_unknown_method_xyz() },
        qr/(?:Unknown function|Can't locate object method)/,
        "unknown method dies with appropriate error"
    );
}

# --- service() caches service objects ---
{
    mock_lwp_useragent();

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object for cache test" or die;

    my $route = $api->route;
    my $svc1 = $route->service('compute');
    my $svc2 = $route->service('compute');

    ok $svc1 == $svc2, "service() returns cached object on second call";
}

done_testing;
