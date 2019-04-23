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

my $SERVER_NAME = 'testsuite OpenStack::MetaAPI';

{
    note "Testing Delete VM logic";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_servers()),
    );

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/000000-1111-22222-33333-444444',
        application_json(json_servers_id()),
    );

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/ports?device_id=000000-1111-22222-33333-444444',
        application_json(json_for_ports_device_id_unused()),
    );

    mock_delete_request(
        'http://127.0.0.1:8774/v2.1/servers/000000-1111-22222-33333-444444',
        txt_plain("ok delete server"),
    );

    {
        my ($server) = $api->servers(name => $SERVER_NAME);
        is $api->delete_server($server->{id}), "ok delete server",
          "delete a server without a floating IP attached to it";
    }

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/ports?device_id=000000-1111-22222-33333-444444',
        application_json(json_for_ports_device_id_used()),
    );

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/floatingips',
        application_json(json_for_floatingips()),
    );

    mock_delete_request(
        'http://127.0.0.1:9696/v2.0/floatingips/ffff-1111-00000-aaaaaaa-777777',
        txt_plain("ok delete floating ip ok"),
    );

    {
        my ($server) = $api->servers(name => $SERVER_NAME);
        is $api->delete_server($server->{id}), "ok delete server",
          "delete a server with a floating ip attached to it";
    }

}

done_testing;

sub json_for_floatingips {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
{
    "floatingips": [
        {
            "router_id": "d23abc8d-2991-4a55-ba98-2aaea84cc72f",
            "description": "for test",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip",
            "created_at": "2016-12-21T10:55:50Z",
            "updated_at": "2016-12-21T10:55:53Z",
            "revision_number": 1,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": "10.0.0.3",
            "floating_ip_address": "172.24.4.228",
            "port_id": "d80b1a3b-4fc1-49f3-952e-1e2ab7081d8b",
            "id": "ffff-1111-00000-aaaaaaa-777777",
            "status": "ACTIVE",
            "port_details": {
                "status": "ACTIVE",
                "name": "",
                "admin_state_up": true,
                "network_id": "02dd8479-ef26-4398-a102-d19d0a7b3a1f",
                "device_owner": "compute:nova",
                "mac_address": "fa:16:3e:b1:3b:30",
                "device_id": "8e3941b4-a6e9-499f-a1ac-2a4662025cba"
            },
            "tags": ["tag1,tag2"],
            "port_forwardings": []
        }
    ]
}
JSON
}

sub json_for_ports_device_id_used {
    return <<'JSON';
{
    "ports": [
        {
            "admin_state_up": true,
            "allowed_address_pairs": [],
            "created_at": "2016-03-08T20:19:41",
            "data_plane_status": null,
            "description": "",
            "device_id": "000000-1111-22222-33333-444444",
            "device_owner": "network:router_gateway",
            "dns_assignment": {
                "hostname": "myport",
                "ip_address": "172.24.4.2",
                "fqdn": "myport.my-domain.org"
            },
            "dns_domain": "my-domain.org.",
            "dns_name": "myport",
            "extra_dhcp_opts": [
            {
                "opt_value": "pxelinux.0",
                "ip_version": 4,
                "opt_name": "bootfile-name"
            }
            ],
            "fixed_ips": [
                {
                    "ip_address": "172.24.4.2",
                    "subnet_id": "008ba151-0b8c-4a67-98b5-0d2b87666062"
                }
            ],
            "id": "d80b1a3b-4fc1-49f3-952e-1e2ab7081d8b",
            "ip_allocation": "immediate",
            "mac_address": "fa:16:3e:58:42:ed",
            "name": "",
            "network_id": "70c1db1f-b701-45bd-96e0-a313ee3430b3",
            "project_id": "",
            "revision_number": 1,
            "security_groups": [],
            "status": "ACTIVE",
            "tags": ["tag1,tag2"],
            "tenant_id": "",
            "updated_at": "2016-03-08T20:19:41",
            "qos_policy_id": "29d5e02e-d5ab-4929-bee4-4a9fc12e22ae",
            "port_security_enabled": false,
            "uplink_status_propagation": false
        }
    ]
}
JSON
}

sub json_for_ports_device_id_unused {
    return <<'JSON';
{
    "ports": [
        {
            "admin_state_up": true,
            "allowed_address_pairs": [],
            "created_at": "2016-03-08T20:19:41",
            "data_plane_status": null,
            "description": "",
            "device_id": "0000-00000-0000-0000-0000",
            "device_owner": "network:router_gateway",
            "dns_assignment": {
                "hostname": "myport",
                "ip_address": "172.24.4.2",
                "fqdn": "myport.my-domain.org"
            },
            "dns_domain": "my-domain.org.",
            "dns_name": "myport",
            "extra_dhcp_opts": [
            {
                "opt_value": "pxelinux.0",
                "ip_version": 4,
                "opt_name": "bootfile-name"
            }
            ],
            "fixed_ips": [
                {
                    "ip_address": "172.24.4.2",
                    "subnet_id": "008ba151-0b8c-4a67-98b5-0d2b87666062"
                }
            ],
            "id": "d80b1a3b-4fc1-49f3-952e-1e2ab7081d8b",
            "ip_allocation": "immediate",
            "mac_address": "fa:16:3e:58:42:ed",
            "name": "",
            "network_id": "70c1db1f-b701-45bd-96e0-a313ee3430b3",
            "project_id": "",
            "revision_number": 1,
            "security_groups": [],
            "status": "ACTIVE",
            "tags": ["tag1,tag2"],
            "tenant_id": "",
            "updated_at": "2016-03-08T20:19:41",
            "qos_policy_id": "29d5e02e-d5ab-4929-bee4-4a9fc12e22ae",
            "port_security_enabled": false,
            "uplink_status_propagation": false
        }
    ]
}
JSON
}

sub json_servers_id {
    my $json = <<'JSON';
{
    "server": {
        "OS-EXT-AZ:availability_zone": "UNKNOWN",
        "OS-EXT-STS:power_state": 0,
        "created": "2018-12-03T21:06:18Z",
        "flavor": {
            "disk": 1,
            "ephemeral": 0,
            "extra_specs": {},
            "original_name": "m1.tiny",
            "ram": 512,
            "swap": 0,
            "vcpus": 1
        },
        "id": "000000-1111-22222-33333-444444",
        "image": {
            "id": "70a599e0-31e7-49b7-b260-868f441e862b",
            "links": [
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/images/70a599e0-31e7-49b7-b260-868f441e862b",
                    "rel": "bookmark"
                }
            ]
        },
        "status": "UNKNOWN",
        "tenant_id": "project",
        "user_id": "fake",
        "links": [
            {
                "href": "http://openstack.example.com/v2.1/6f70656e737461636b20342065766572/servers/33748c23-38dd-4f70-b774-522fc69e7b67",
                "rel": "self"
            },
            {
                "href": "http://openstack.example.com/6f70656e737461636b20342065766572/servers/33748c23-38dd-4f70-b774-522fc69e7b67",
                "rel": "bookmark"
            }
        ]
    }
}
JSON

}

sub json_servers {
    my $json = <<'JSON';
{
    "servers": [
        {
            "id": "000000-1111-22222-33333-444444",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/servers/22c91117-08de-4894-9aa9-6ef382400985",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/servers/22c91117-08de-4894-9aa9-6ef382400985",
                    "rel": "bookmark"
                }
            ],
            "name": "~NAME~"
        }
    ],
    "servers_links": [
        {
            "href": "http://openstack.example.com/v2.1/6f70656e737461636b20342065766572/servers?limit=1&marker=22c91117-08de-4894-9aa9-6ef382400985",
            "rel": "next"
        }
    ]
}
JSON

    $json =~ s{~NAME~}{$SERVER_NAME};

    return $json;
}

__END__
