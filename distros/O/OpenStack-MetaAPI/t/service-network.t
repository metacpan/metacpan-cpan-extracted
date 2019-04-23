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

{
    note "Testing Network service";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/floatingips',
        application_json(json_for_floatingips()),
    );

    my $IMAGE_UID  = '170fafa5-1329-44a3-9c27-9bb77b77206d';
    my $IMAGE_NAME = 'myimage';

    like [$api->floatingips()],

      [
        {   'created_at'          => '2016-12-21T10:55:50Z',
            'description'         => 'for test',
            'dns_domain'          => 'my-domain.org.',
            'dns_name'            => 'myfip',
            'fixed_ip_address'    => '10.0.0.3',
            'floating_ip_address' => '172.24.4.228',
            'floating_network_id' => '376da547-b977-4cfe-9cba-275c80debf57',
            'id'                  => '2f245a7b-796b-4f26-9cf9-9e82d248fda7',
            'port_details'        => {
                'admin_state_up' =>
                  bless(do { \(my $o = 1) }, 'JSON::PP::Boolean'),
                'device_id'    => '8e3941b4-a6e9-499f-a1ac-2a4662025cba',
                'device_owner' => 'compute:nova',
                'mac_address'  => 'fa:16:3e:b1:3b:30',
                'name'         => '',
                'network_id'   => '02dd8479-ef26-4398-a102-d19d0a7b3a1f',
                'status'       => 'ACTIVE'
            },
            'port_forwardings' => [],
            'port_id'          => 'ce705c24-c1ef-408a-bda3-7bbd946164ab',
            'project_id'       => '4969c491a3c74ee4af974e6d800c62de',
            'revision_number'  => 1,
            'router_id'        => 'd23abc8d-2991-4a55-ba98-2aaea84cc72f',
            'status'           => 'ACTIVE',
            'tags'             => ['tag1,tag2'],
            'tenant_id'        => '4969c491a3c74ee4af974e6d800c62de',
            'updated_at'       => '2016-12-21T10:55:53Z'
        },
        {   'created_at'          => '2016-12-21T11:55:50Z',
            'description'         => 'for test',
            'dns_domain'          => 'my-domain.org.',
            'dns_name'            => 'myfip2',
            'fixed_ip_address'    => undef,
            'floating_ip_address' => '172.24.4.227',
            'floating_network_id' => '376da547-b977-4cfe-9cba-275c80debf57',
            'id'                  => '61cea855-49cb-4846-997d-801b70c71bdd',
            'port_details'        => undef,
            'port_forwardings'    => [],
            'port_id'             => undef,
            'project_id'          => '4969c491a3c74ee4af974e6d800c62de',
            'revision_number'     => 2,
            'router_id'           => undef,
            'status'              => 'DOWN',
            'tags'                => ['tag1,tag2'],
            'tenant_id'           => '4969c491a3c74ee4af974e6d800c62de',
            'updated_at'          => '2016-12-21T11:55:53Z'
        },
        {   'created_at'          => '2018-06-15T02:12:48Z',
            'description'         => 'for test with port forwarding',
            'dns_domain'          => 'my-domain.org.',
            'dns_name'            => 'myfip3',
            'fixed_ip_address'    => undef,
            'floating_ip_address' => '172.24.4.42',
            'floating_network_id' => '376da547-b977-4cfe-9cba-275c80debf57',
            'id'                  => '898b198e-49f7-47d6-a7e1-53f626a548e6',
            'port_forwardings'    => [
                {   'external_port'       => 2225,
                    'internal_ip_address' => '10.0.0.19',
                    'internal_port'       => 25,
                    'protocol'            => 'tcp'
                },
                {   'external_port'       => 8786,
                    'internal_ip_address' => '10.0.0.18',
                    'internal_port'       => 16666,
                    'protocol'            => 'tcp'
                }
            ],
            'port_id'         => undef,
            'project_id'      => '4969c491a3c74ee4af974e6d800c62de',
            'revision_number' => 1,
            'router_id'       => '0303bf18-2c52-479c-bd68-e0ad712a1639',
            'status'          => 'ACTIVE',
            'tags'            => [],
            'tenant_id'       => '4969c491a3c74ee4af974e6d800c62de',
            'updated_at'      => '2018-06-15T02:12:57Z'
        }]

      , "floatingips";
    #

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/security-groups',
        application_json(json_for_security_groups()),
    );

    is $api->security_groups, {
        'created_at'           => '2018-03-19T19:16:56Z',
        'description'          => 'default',
        'id'                   => '85cc3048-abc3-43cc-89b3-377341426ac5',
        'name'                 => 'default',
        'project_id'           => 'e4f50856753b4dc6afee5fa6b9b6c550',
        'revision_number'      => 8,
        'security_group_rules' => [
            {   'created_at'        => '2018-03-19T19:16:56Z',
                'description'       => '',
                'direction'         => 'egress',
                'ethertype'         => 'IPv6',
                'id'                => '3c0e45ff-adaf-4124-b083-bf390e5482ff',
                'port_range_max'    => undef,
                'port_range_min'    => undef,
                'project_id'        => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'protocol'          => undef,
                'remote_group_id'   => undef,
                'remote_ip_prefix'  => undef,
                'revision_number'   => 1,
                'security_group_id' => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'tags'              => ['tag1,tag2'],
                'tenant_id'         => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'updated_at'        => '2018-03-19T19:16:56Z'
            },
            {   'created_at'        => '2018-03-19T19:16:56Z',
                'description'       => '',
                'direction'         => 'egress',
                'ethertype'         => 'IPv4',
                'id'                => '93aa42e5-80db-4581-9391-3a608bd0e448',
                'port_range_max'    => undef,
                'port_range_min'    => undef,
                'project_id'        => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'protocol'          => undef,
                'remote_group_id'   => undef,
                'remote_ip_prefix'  => undef,
                'revision_number'   => 2,
                'security_group_id' => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'tags'              => ['tag1,tag2'],
                'tenant_id'         => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'updated_at'        => '2018-03-19T19:16:56Z'
            },
            {   'created_at'        => '2018-03-19T19:16:56Z',
                'description'       => '',
                'direction'         => 'ingress',
                'ethertype'         => 'IPv6',
                'id'                => 'c0b09f00-1d49-4e64-a0a7-8a186d928138',
                'port_range_max'    => undef,
                'port_range_min'    => undef,
                'project_id'        => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'protocol'          => undef,
                'remote_group_id'   => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'remote_ip_prefix'  => undef,
                'revision_number'   => 1,
                'security_group_id' => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'tags'              => ['tag1,tag2'],
                'tenant_id'         => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'updated_at'        => '2018-03-19T19:16:56Z'
            },
            {   'created_at'        => '2018-03-19T19:16:56Z',
                'description'       => '',
                'direction'         => 'ingress',
                'ethertype'         => 'IPv4',
                'id'                => 'f7d45c89-008e-4bab-88ad-d6811724c51c',
                'port_range_max'    => undef,
                'port_range_min'    => undef,
                'project_id'        => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'protocol'          => undef,
                'remote_group_id'   => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'remote_ip_prefix'  => undef,
                'revision_number'   => 1,
                'security_group_id' => '85cc3048-abc3-43cc-89b3-377341426ac5',
                'tags'              => ['tag1,tag2'],
                'tenant_id'         => 'e4f50856753b4dc6afee5fa6b9b6c550',
                'updated_at'        => '2018-03-19T19:16:56Z'
            }
        ],
        'tags'       => ['tag1,tag2'],
        'tenant_id'  => 'e4f50856753b4dc6afee5fa6b9b6c550',
        'updated_at' => '2018-03-19T19:16:56Z'

      },
      "security_groups";

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
            "port_id": "ce705c24-c1ef-408a-bda3-7bbd946164ab",
            "id": "2f245a7b-796b-4f26-9cf9-9e82d248fda7",
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
        },
        {
            "router_id": null,
            "description": "for test",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip2",
            "created_at": "2016-12-21T11:55:50Z",
            "updated_at": "2016-12-21T11:55:53Z",
            "revision_number": 2,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": null,
            "floating_ip_address": "172.24.4.227",
            "port_id": null,
            "id": "61cea855-49cb-4846-997d-801b70c71bdd",
            "status": "DOWN",
            "port_details": null,
            "tags": ["tag1,tag2"],
            "port_forwardings": []
        },
        {
            "router_id": "0303bf18-2c52-479c-bd68-e0ad712a1639",
            "description": "for test with port forwarding",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip3",
            "created_at": "2018-06-15T02:12:48Z",
            "updated_at": "2018-06-15T02:12:57Z",
            "revision_number": 1,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": null,
            "floating_ip_address": "172.24.4.42",
            "port_id": null,
            "id": "898b198e-49f7-47d6-a7e1-53f626a548e6",
            "status": "ACTIVE",
            "tags": [],
            "port_forwardings": [
                {
                    "protocol": "tcp",
                    "internal_ip_address": "10.0.0.19",
                    "internal_port": 25,
                    "external_port": 2225
                },
                {
                    "protocol": "tcp",
                    "internal_ip_address": "10.0.0.18",
                    "internal_port": 16666,
                    "external_port": 8786
                }
            ]
        }
    ]
}
JSON
}

sub json_for_security_groups {
    return <<JSON;
{
    "security_groups": [
        {
            "description": "default",
            "id": "85cc3048-abc3-43cc-89b3-377341426ac5",
            "name": "default",
            "security_group_rules": [
                {
                    "direction": "egress",
                    "ethertype": "IPv6",
                    "id": "3c0e45ff-adaf-4124-b083-bf390e5482ff",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": null,
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "egress",
                    "ethertype": "IPv4",
                    "id": "93aa42e5-80db-4581-9391-3a608bd0e448",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": null,
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 2,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "ingress",
                    "ethertype": "IPv6",
                    "id": "c0b09f00-1d49-4e64-a0a7-8a186d928138",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "ingress",
                    "ethertype": "IPv4",
                    "id": "f7d45c89-008e-4bab-88ad-d6811724c51c",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                }
            ],
            "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
            "revision_number": 8,
            "created_at": "2018-03-19T19:16:56Z",
            "updated_at": "2018-03-19T19:16:56Z",
            "tags": ["tag1,tag2"],
            "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550"
        }
    ]
}
JSON
}

__END__
