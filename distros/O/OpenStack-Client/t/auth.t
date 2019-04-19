#! /usr/bin/perl
#
# Copyright (c) 2019 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#

use strict;
use warnings;

use JSON ();

use OpenStack::Client::Auth ();

use lib 't/lib';
use Test::OpenStack::Client ();

use Test::More qw(no_plan);
use Test::Exception;

my $test_endpoint = 'http://foo.bar/';

my %test_credentials = (
    'tenant'   => 'foo',
    'username' => 'foo',
    'password' => 'bar'
);

my @test_versions = (
    undef, '2.0', 3
);

throws_ok {
    OpenStack::Client::Auth->new()
} qr/No OpenStack authentication endpoint provided/, "OpenStack::Client::Auth->new() dies if no endpoint is provided";

foreach my $test_version (@test_versions) {
    my $version = defined $test_version? $test_version: 'undefined';

    if ( $test_version && $test_version < 3 ) {
        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint,
                (defined $test_version? ('version' => $test_version): ()),
            );
        } qr/No OpenStack tenant name provided in "tenant"/, "OpenStack::Client::Auth->new() dies if no tenant name is provided for version $version";
    }

    throws_ok {
        OpenStack::Client::Auth->new($test_endpoint,
            (defined $test_version? ('version' => $test_version): ()),
            'tenant' => $test_credentials{'tenant'}
        );
    } qr/No OpenStack username provided in "username"/, "OpenStack::Client::Auth->new() dies if no username is provided for version $version";

    throws_ok {
        OpenStack::Client::Auth->new($test_endpoint,
            (defined $test_version? ('version' => $test_version): ()),
            'tenant'   => $test_credentials{'tenant'},
            'username' => $test_credentials{'username'}
        );
    } qr/No OpenStack password provided in "password"/, "OpenStack::Client::Auth->new() dies if no password is provided for version $version";
}

throws_ok {
    OpenStack::Client::Auth->new($test_endpoint, %test_credentials,
        'version' => 'poop'
    );
} qr/Unsupported Identity endpoint version poop/, "OpenStack::Client::Auth->new() dies if invalid version is provided";

my $full_content_v3 = JSON::encode_json({
    'token' => {
        'audit_ids' => ['3T2dc1CGQxyJsHdDu1xkcw'],
        'catalog'   => [
            {
                'endpoints' => [
                    {   'id'        => 'cafebabe',
                        'interface' => 'public',
                        'region'    => 'Morocco',
                        'region_id' => 'Morocco',
                        'url'       => 'http://example.com/public/image/v2'
                    },
                    {   'id'        => '8bfc846841ab441ca38471be6d164ced',
                        'interface' => 'admin',
                        'region'    => 'Morocco',
                        'region_id' => 'Morocco',
                        'url'       => 'http://example.com/admin/image/v2'
                    },
                    {   'id'        => 'beb6d358c3654b4bada04d4663b640b9',
                        'interface' => 'internal',
                        'region'    => 'Morocco',
                        'region_id' => 'Morocco',
                        'url'       => 'http://example.com/internal/image/v2'
                    }
                ],
                'id'   => '050726f278654128aba89757ae25950c',
                'name' => 'glance',
                'type' => 'image'
            }
        ],
        'expires_at' => '2015-11-07T02 =>58 =>43.578887Z',
        'issued_at'  => '2015-11-07T01 =>58 =>43.578929Z',
        'methods'    => ['password'],
        'roles'      => [
            {   'id'   => '51cc68287d524c759f47c811e6463340',
                'name' => 'admin'
            }
        ],
        'system' => {'all' => JSON::true},
        'user'   => {
            'domain' => {
                'id'   => 'default',
                'name' => 'Default'
            },
            'id'                  => 'ee4dfb6e5540447cb3741905149d9b6e',
            'name'                => 'admin',
            'password_expires_at' => '2016-11-06T15 =>32 =>17.000000'
        }
    }
});

Test::OpenStack::Client->run_client_tests({
    'responses' => [{
        'content' => $full_content_v3,
        'headers' => {
            'X-Subject-Token' => 'foobarbaz'
        }
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        my $auth;
        
        lives_ok {
            $auth = OpenStack::Client::Auth->new($test_endpoint,
                %test_credentials,
                'version'          => '3',
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } "OpenStack::Client::Auth->new() doesn't die with 'version' => '3'";

        like ref($auth) => qr/^OpenStack::Client::Auth::v3/,
            "OpenStack::Client::Auth->new() will use Identity v3 when asked";
    }
}, {
    'responses' => [{
        'content' => '{}',
    }, {
        'headers' => {
            'X-Subject-Token' => 'foobarbaz'
        },
        'content' => '{}'
    }, {
        'headers' => {
            'X-Subject-Token' => 'foobarbaz'
        },
        'content' => '{"token":{}}'
    }, {
        'headers' => {
            'X-Subject-Token' => 'foobarbaz'
        },
        'content' => '{"token":{"catalog":[]}}'
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint,
                %test_credentials,
                'version'          => '3',
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } qr/No token found in response headers/, "OpenStack::Client::Auth->new() dies when no token found in response headers for v3";

        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint,
                %test_credentials,
                'version'          => '3',
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } qr/No token found in response body/, "OpenStack::Client::Auth->new() dies when no token found in response body for v3";

        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint,
                %test_credentials,
                'version'          => '3',
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } qr/No service catalog found in response body token/, "OpenStack::Client::Auth->new() dies when no service catalog found in response body token for v3";

        lives_ok {
            OpenStack::Client::Auth->new($test_endpoint,
                %test_credentials,
                'version'          => '3',
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } "OpenStack::Client::Auth->new() lives when service catalog is found in response body token for v3";
    }
});

Test::OpenStack::Client->run_client_tests({
    'responses' => [{
        'content' => '{}'
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint, %test_credentials,
                'package_ua'       => $ua,
                'package_request'  => 'Test::OpenStack::Client::Request',
                'package_response' => 'Test::OpenStack::Client::Response'
            );
        } qr/No token found in response/, "OpenStack::Client::Auth->new() dies when service does not return authorization token for v2";
    }
});

my $full_content_v2 = JSON::encode_json({
    'access' => {
        'token' => {
            'id' => 'abc123'
        },

        'serviceCatalog' => [{
            'type'      => 'image',
            'endpoints' => [{
                'id'          => 'deadbeef',
                'region'      => 'Papua New Guinea',
                'publicURL'   => 'http://foo.bar/public/image/v2',
                'internalURL' => 'http://foo.bar/internal/image/v2',
                'adminURL'    => 'http://foo.bar/admin/image/v2'
            }]
        }, {
            'type'      => 'image',
            'endpoints' => [{
                'id'          => 'cafebabe',
                'region'      => 'Morocco',
                'publicURL'   => 'http://meow.cats/public/image/v2',
                'internalURL' => 'http://meow.cats/internal/image/v2',
                'adminURL'    => 'http://meow.cats/admin/image/v2'
            }]
        }]
    },
});

Test::OpenStack::Client->run_auth_tests(
    'version' => '2.0',
    'content' => $full_content_v2,
    'tests'   => [sub {
        my ($auth, $ua) = @_;

        like ref($auth) => qr/^OpenStack::Client::Auth::v2/,
            'OpenStack::Client::Auth->new() defaults to Identity v2';

        throws_ok {
            $auth->service('image',
                'endpoint' => 'poop'
            );
        } qr/Invalid endpoint type specified in "endpoint"/, "\$auth->service() dies when specified an 'endpoint' value other than 'public', 'internal' or 'admin'";

        throws_ok {
            $auth->service('foo');
        } qr/No service type 'foo' found/, "\$auth->service() dies when asked to return a client for a service that does not exist";

        lives_ok {
            $auth->service('image');
        } "\$auth->service() doesn't die when expected to return client for default endpoint for requested service";

        {
            my $got      = JSON::decode_json($ua->{'requests'}->[0]->content);
            my $expected = {
                'auth' => {
                    'tenantName'          => $test_credentials{'tenant'},
                    'passwordCredentials' => {
                        'username' => $test_credentials{'username'},
                        'password' => $test_credentials{'password'}
                    }
                }
            };

            is_deeply($got => $expected, "OpenStack::Client::Auth->new() issues an HTTP request to a Keystone endpoint with expected credentials");
        }

        my $content = JSON::decode_json($ua->{'responses'}->[0]->content);

        {
            my $got      = $auth->response;
            my $expected = $content;

            is_deeply($got => $expected, "\$auth->response() returns whole authentication response body as expected");
        }

        {
            my $got      = $auth->access;
            my $expected = $content->{'access'};

            is_deeply($got => $expected, "\$auth->access() returns systems access data from authentication response body as expected");
        }

        {
            my $got      = $auth->token;
            my $expected = $content->{'access'}->{'token'}->{'id'};

            is_deeply($got => $expected, "\$auth->token() returns authorization token from response body as expected");
        }

        {
            my @got      = $auth->services;
            my @expected = qw(image);

            is_deeply(\@got => \@expected, "\$auth->services() returns list of service types as expected");
        }

        {
            my $got      = $auth->service('image');
            my $expected = $auth->service('image');

            is($got => $expected, "\$auth->service() returns a cached client object across calls");
        }
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'public'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v2)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'publicURL'};

        is($got => $expected, "\$auth->service() returns client for public endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'admin'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v2)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'adminURL'};

        is($got => $expected, "\$auth->service() returns client for admin endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'internal'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v2)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'internalURL'};

        is($got => $expected, "\$auth->service() returns client for internal endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'uri' => 'http://meow.cats/'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/';

        is($got => $expected, "\$auth->service() returns client for an endpoint whose URI is explicitly provided");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'id' => 'cafebabe'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose ID is specified");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'region' => 'Morocco'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose region is specified");
    }
]);

Test::OpenStack::Client->run_auth_tests(
    'version' => '3',
    'headers' => {
        'X-Subject-Token' => 'foobarbaz'
    },
    'content' => $full_content_v3,
    'tests'   => [sub {
        my ($auth, $ua) = @_;

        my $content = JSON::decode_json($ua->{'responses'}->[0]->content);

        throws_ok {
            $auth->service('foo');
        } qr/No service type 'foo' found/, "\$auth->service() dies when asked to return a client for a service that does not exist";

        lives_ok {
            $auth->service('image');
        } "\$auth->service() doesn't die when expected to return client for default endpoint for requested service";

        {
            my $got = JSON::decode_json($ua->{'requests'}->[0]->content);

            ok defined($got->{'auth'}->{'identity'}->{'password'}),
                "OpenStack::Client::Auth->new() issues an HTTP request to a Keystone endpoint with expected credentials for v3";
        }

        {
            my $got      = $auth->response->decode_json;
            my $expected = $content;

            is_deeply($got => $expected, "\$auth->response() returns whole authentication response body as expected");
        }

        {
            my $got      = $auth->access;
            my $expected = $content->{'access'};

            is_deeply($got => $expected, "\$auth->access() returns systems access data from authentication response body as expected");
        }

        {
            my $got      = $auth->token;
            my $expected = $ua->{'responses'}->[0]->header('X-Subject-Token');

            is_deeply($got => $expected, "\$auth->token() returns authorization token from response body as expected");
        }

        {
            my @got      = $auth->services;
            my @expected = qw(image);

            is_deeply(\@got => \@expected, "\$auth->services() returns list of service types as expected");
        }

        {
            my $got      = $auth->service('image');
            my $expected = $auth->service('image');

            is($got => $expected, "\$auth->service() returns a cached client object across calls");
        }
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'public'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v3)
            ->{'token'}
            ->{'catalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'url'};

        is($got => $expected, "\$auth->service() returns client for public endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'admin'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v3)
            ->{'token'}
            ->{'catalog'}
            ->[0]
            ->{'endpoints'}
            ->[1]
            ->{'url'};

        is($got => $expected, "\$auth->service() returns client for admin endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'internal'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content_v3)
            ->{'token'}
            ->{'catalog'}
            ->[0]
            ->{'endpoints'}
            ->[2]
            ->{'url'};

        is($got => $expected, "\$auth->service() returns client for internal endpoint when requested");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'uri' => 'http://example.com/identity'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://example.com/identity';

        is($got => $expected, "\$auth->service() returns client for an endpoint whose URI is explicitly provided");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'id' => 'cafebabe'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://example.com/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose ID is specified");
    }, sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'region' => 'Morocco'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://example.com/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose region is specified");
    }
]);
