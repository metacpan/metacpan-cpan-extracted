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
    note "Testing servers";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_for_servers()),
    );

    is [$api->servers()],
      [
        {   'id'    => '595bdd3d10d95bb1a570603015bceeee',
            'links' => [
                {   'href' =>
                      'http://127.0.0.1:8774/v2.1/servers/595bdd3d10d95bb1a570603015bceeee',
                    'rel' => 'self'
                },
                {   'href' =>
                      'http://127.0.0.1:8774/servers/595bdd3d10d95bb1a570603015bceeee',
                    'rel' => 'bookmark'
                }
            ],
            'name' => 'server one'
        },
        {   'id'    => '433bef2eda384218df1f3fe032d3c6cc',
            'links' => [
                {   'href' =>
                      'http://127.0.0.1:8774/v2.1/servers/433bef2eda384218df1f3fe032d3c6cc',
                    'rel' => 'self'
                },
                {   'href' =>
                      'http://127.0.0.1:8774/servers/433bef2eda384218df1f3fe032d3c6cc',
                    'rel' => 'bookmark'
                }
            ],
            'name' => 'server two'
        },
        {   'id'    => '8b6da0864b308971b13d03d6ccd348f5',
            'links' => [
                {   'href' =>
                      'http://127.0.0.1:8774/v2.1/servers/8b6da0864b308971b13d03d6ccd348f5',
                    'rel' => 'self'
                },
                {   'href' =>
                      'http://127.0.0.1:8774/servers/8b6da0864b308971b13d03d6ccd348f5',
                    'rel' => 'bookmark'
                }
            ],
            'name' => 'server three'
        }
      ],
      "got three servers returned";

    is $api->servers(name => 'server two'),
      { 'id'    => '433bef2eda384218df1f3fe032d3c6cc',
        'links' => [
            {   'href' =>
                  'http://127.0.0.1:8774/v2.1/servers/433bef2eda384218df1f3fe032d3c6cc',
                'rel' => 'self'
            },
            {   'href' =>
                  'http://127.0.0.1:8774/servers/433bef2eda384218df1f3fe032d3c6cc',
                'rel' => 'bookmark'
            }
        ],
        'name' => 'server two'
      },
      "api->servers( name => 'server two' )";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/33748c23-38dd-4f70-b774-522fc69e7b67',
        application_json(json_for_server()),
    );

    my $output = $api->server_from_uid('33748c23-38dd-4f70-b774-522fc69e7b67');
    is last_http_request(),
      "GET http://127.0.0.1:8774/v2.1/servers/33748c23-38dd-4f70-b774-522fc69e7b67",
      "last_http_request";

    is $output, JSON::decode_json(json_for_server())->{server},
      "get a server from uid";

}

done_testing;

sub json_for_server {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
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
        "id": "33748c23-38dd-4f70-b774-522fc69e7b67",
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

sub json_for_servers {
    return <<'JSON';
{
   "servers" : [
      {
         "name" : "server one",
         "links" : [
            {
               "rel" : "self",
               "href" : "http://127.0.0.1:8774/v2.1/servers/595bdd3d10d95bb1a570603015bceeee"
            },
            {
               "href" : "http://127.0.0.1:8774/servers/595bdd3d10d95bb1a570603015bceeee",
               "rel" : "bookmark"
            }
         ],
         "id" : "595bdd3d10d95bb1a570603015bceeee"
      },
      {
         "name" : "server two",
         "id" : "433bef2eda384218df1f3fe032d3c6cc",
         "links" : [
            {
               "rel" : "self",
               "href" : "http://127.0.0.1:8774/v2.1/servers/433bef2eda384218df1f3fe032d3c6cc"
            },
            {
               "rel" : "bookmark",
               "href" : "http://127.0.0.1:8774/servers/433bef2eda384218df1f3fe032d3c6cc"
            }
         ]
      },
      {
         "id" : "8b6da0864b308971b13d03d6ccd348f5",
         "links" : [
            {
               "rel" : "self",
               "href" : "http://127.0.0.1:8774/v2.1/servers/8b6da0864b308971b13d03d6ccd348f5"
            },
            {
               "rel" : "bookmark",
               "href" : "http://127.0.0.1:8774/servers/8b6da0864b308971b13d03d6ccd348f5"
            }
         ],
         "name" : "server three"
      }
   ]
}
JSON
}

__END__
