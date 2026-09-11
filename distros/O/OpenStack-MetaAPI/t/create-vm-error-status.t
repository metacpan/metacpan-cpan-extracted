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

# Tight loop so the test exits fast — we want to prove ERROR aborts
# the wait, not that the timeout eventually fires.
$api->create_max_timeout(60);
$api->create_loop_sleep(0);

my $create_vm = sub {
    return $api->create_vm(
        name                    => "vm-error-test",
        image                   => $IMAGE_UID,
        flavor                  => 'small',
        network                 => 'net1',
        network_for_floating_ip => 'net2',
    );
};

subtest "ERROR status with fault detail dies fast" => sub {
    my $polls = 0;
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/' . $SERVER_UID,
        sub {
            ++$polls;
            return {
                code => 200,
                msg  => "server is in ERROR",
                %{application_json(json_for_server_with_status_and_fault(
                    'ERROR',
                    {code => 500, message => 'No valid host was found'}
                ))},
            };
        },
    );

    like(
        dies { $create_vm->() },
        qr{Failed to create server \Q$SERVER_UID\E:\s*status=ERROR},
        "dies with explicit ERROR status");

    like(
        dies { $create_vm->() },
        qr{No valid host was found},
        "fault message surfaced in the die");

    is $polls > 0 && $polls < 5, T(),
      "abandoned waiting after seeing ERROR (polls=$polls), did not loop to timeout";
};

subtest "lower-case error status also detected" => sub {
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/' . $SERVER_UID,
        application_json(
            json_for_server_with_status_and_fault('error', undef)),
    );

    like(
        dies { $create_vm->() },
        qr{status=ERROR},
        "case-insensitive error detection");
};

subtest "ERROR without fault structure still dies cleanly" => sub {
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/' . $SERVER_UID,
        application_json(
            json_for_server_with_status_and_fault('ERROR', undef)),
    );

    like(
        dies { $create_vm->() },
        qr{Failed to create server \Q$SERVER_UID\E:\s*status=ERROR},
        "no fault data is fine");
};

done_testing;

sub json_for_server_with_status_and_fault {
    my ($status, $fault) = @_;

    my $server = {
        id     => $SERVER_UID,
        status => $status,
    };
    $server->{fault} = $fault if $fault;

    return JSON::encode_json({server => $server});
}

# --- mock fixtures (reused from xtra-create-vm.t) -----------------------------

sub json_create_server {
    return <<'JSON';
{
    "server" : {
        "id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        "name" : "vm-error-test"
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
        { "id": "d32019d3-bc6e-4319-9c1d-6722fc136a22", "name": "net1" },
        { "id": "db193ab3-96e3-4cb3-8fc5-05f4296d0324", "name": "net2" }
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
