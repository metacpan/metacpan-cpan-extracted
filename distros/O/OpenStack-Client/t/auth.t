#! /usr/bin/perl
#
# Copyright (c) 2015 cPanel, Inc.
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

throws_ok {
    OpenStack::Client::Auth->new()
} qr/No OpenStack authentication endpoint provided/, "OpenStack::Client::Auth->new() dies if no endpoint is provided";

throws_ok {
    OpenStack::Client::Auth->new($test_endpoint);
} qr/No OpenStack tenant name provided in "tenant"/, "OpenStack::Client::Auth->new() dies if no tenant name is provided";

throws_ok {
    OpenStack::Client::Auth->new($test_endpoint,
        'tenant' => $test_credentials{'tenant'}
    );
} qr/No OpenStack username provided in "username"/, "OpenStack::Client::Auth->new() dies if no username is provided";

throws_ok {
    OpenStack::Client::Auth->new($test_endpoint,
        'tenant'   => $test_credentials{'tenant'},
        'username' => $test_credentials{'username'}
    );
} qr/No OpenStack password provided in "password"/, "OpenStack::Client::Auth->new() dies if no password is provided";

Test::OpenStack::Client->run_client_tests({
    'responses' => [{
        'content' => '{}'
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        throws_ok {
            OpenStack::Client::Auth->new($test_endpoint, %test_credentials,
                'package_ua'      => $ua,
                'package_request' => 'Test::OpenStack::Client::Request'
            );
        } qr/No token found in response/, "OpenStack::Client::Auth->new() dies when service does not return authorization token";
    }
});

my $full_content = JSON::encode_json({
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

Test::OpenStack::Client->run_auth_tests({
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

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
            my $expected = $content->{'access'}->{'token'};

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
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'public'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'publicURL'};

        is($got => $expected, "\$auth->service() returns client for public endpoint when requested");
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'admin'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'adminURL'};

        is($got => $expected, "\$auth->service() returns client for admin endpoint when requested");
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'endpoint' => 'internal'
        );

        my $got      = $client->endpoint;
        my $expected = JSON::decode_json($full_content)
            ->{'access'}
            ->{'serviceCatalog'}
            ->[0]
            ->{'endpoints'}
            ->[0]
            ->{'internalURL'};

        is($got => $expected, "\$auth->service() returns client for internal endpoint when requested");
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'uri' => 'http://meow.cats/'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/';

        is($got => $expected, "\$auth->service() returns client for an endpoint whose URI is explicitly provided");
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'id' => 'cafebabe'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose ID is specified");
    }
}, {
    'responses' => [{
        'content' => $full_content
    }],

    'test' => sub {
        my ($auth, $ua) = @_;

        my $client = $auth->service('image',
            'region' => 'Morocco'
        );

        my $got      = $client->endpoint;
        my $expected = 'http://meow.cats/public/image/v2';

        is ($got => $expected, "\$auth->service() returns client for an endpoint whose region is specified");
    }
});
