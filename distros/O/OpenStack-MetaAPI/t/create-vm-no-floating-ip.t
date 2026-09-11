#!/usr/bin/env perl

# create_vm() must work on a cloud with no tenant network to escape from.
# There the only network is external and shared, the server is given a
# routable address directly, and there is no floating IP to attach.
# 'network_for_floating_ip' is optional for exactly that reason.

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

my $IMAGE_UID  = '170fafa5-1329-44a3-9c27-9bb77b77206d';
my $SERVER_UID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

mock_get_request(
    'http://127.0.0.1:8774/v2.1/flavors',
    application_json(json_for_flavors()),
);

mock_get_request(
    'http://127.0.0.1:9696/v2.0/networks',
    application_json(json_for_networks()),
);

mock_get_request(
    'http://127.0.0.1:9292/v2/images/' . $IMAGE_UID,
    application_json(json_imageid()),
);

mock_get_request(
    'http://127.0.0.1:9696/v2.0/security-groups',
    application_json(json_for_security_groups()),
);

mock_post_request(
    'http://127.0.0.1:8774/v2.1/servers',
    application_json(json_create_server()),
);

mock_get_request(
    'http://127.0.0.1:8774/v2.1/servers/' . $SERVER_UID,
    application_json(json_active_server()),
);

# Note: POST /v2.0/floatingips is intentionally NOT mocked.  Asking for one
# would escape the mock layer and fail the test, which is the point.

$api->create_max_timeout(60);
$api->create_loop_sleep(0);

my $vm;
ok lives {
    $vm = $api->create_vm(
        name    => "vm-no-floating-ip",
        image   => $IMAGE_UID,
        flavor  => 'small',
        network => 'net1',
    );
}, "create_vm() succeeds without 'network_for_floating_ip'"
  or note $@;

is ref $vm, 'HASH', "got the server back";
is $vm->{id},     $SERVER_UID, "server id is returned";
is $vm->{status}, 'ACTIVE',    "server is active";

is $vm->{floating_ip_address}, undef, "no floating ip address was set";
is $vm->{floating_ip_id},      undef, "no floating ip id was set";

like last_http_request(),
  qr{^GET \Qhttp://127.0.0.1:8774/v2.1/servers/$SERVER_UID\E$},
  "last call was the status poll, no floating ip was requested";

done_testing;

# --- mock fixtures ------------------------------------------------------------

sub json_active_server {
    return JSON::encode_json(
        {server => {id => $SERVER_UID, status => 'ACTIVE'}});
}

sub json_create_server {
    return <<'JSON';
{
    "server" : {
        "id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        "name" : "vm-no-floating-ip"
    }
}
JSON
}

sub json_imageid {
    return <<'JSON';
{
    "OS-DCF:diskConfig": "AUTO",
    "id": "70a599e0-31e7-49b7-b260-868f441e862b",
    "name": "fakeimage7",
    "status": "ACTIVE"
}
JSON
}

sub json_for_flavors {
    return <<'JSON';
{
    "flavors": [
        { "id": "1", "name": "tiny" },
        { "id": "2", "name": "small" }
    ]
}
JSON
}

sub json_for_networks {
    return <<'JSON';
{
    "networks": [
        { "id": "d32019d3-bc6e-4319-9c1d-6722fc136a22", "name": "net1" }
    ]
}
JSON
}

sub json_for_security_groups {
    return <<'JSON';
{
    "security_groups": [
        { "id": "85cc3048-abc3-43cc-89b3-377341426ac5", "name": "default" }
    ]
}
JSON
}
