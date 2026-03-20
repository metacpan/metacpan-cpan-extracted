# $Id$

use strict;
use warnings;

use Test::More;
use Test::Exception;
use HTTP::Request;
use HTTP::Response;
use JSON;

# use this until _get_agent behavior is worked out
# and we can subclass it. once that's done, switch
# to using Test::LWP::UserAgent as it avoids bugs that
# can occur when MockObject overrides ISA
use Test::Mock::LWP::Dispatch;

use Restish::Client;

# Accessing previous response returns undefined if no previous respose
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

is( $client->response_code,
    undef,
    'Return undef is no previous response code'
);

is( $client->response_header('Content-Type'),
    undef,
    'Return undef is no previous response header'
);

is( $client->response_body,
    undef,
    'Return undef is no previous response body'
);
}

# Invalid named parameter
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');
    throws_ok(sub { $client->request(method => 'GET', uri => '/', quey_params => {}) },
        qr/Invalid named parameter/,
        'Invalid named parameter');
}

# Invalid method
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');
    throws_ok(sub { $client->request(method => 'internet', uri => '/') },
        qr/Invalid/,
        'Invalid method');
}

# Invalid URI
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');
    throws_ok(sub { $client->request(method => 'GET') },
        qr/Missing/,
        'Invalid URI');
}

# Failed request with 404
{
$mock_ua->map(
    'https://ident.os.example.com/dont_go_here',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method      => 'GET',
    uri         => '/v3/invalid_path',
    );

is( $res,
    0,
    'Failed request with 404 returns false value' );

is( $client->response_code,
    404,
    'Failed request with 404 sets response_code to 404' );
}

# Tests for a successful request
# Using sample API response from v2.0 Identity
# http://docs.openstack.org/api/quick-start/content/
{
my $identity_response = <<'EOF';
{
    "access":{
        "token":{
            "issued_at":"2013-11-06T20:06:24.113908",
            "expires":"2013-11-07T20:06:24Z",
            "id":"a_token",
            "tenant":{
                "description":null,
                "enabled":true,
                "id":"604bbe45ac7143a79e14f3158df67091",
                "name":"admin"
            }
        },
        "serviceCatalog":[
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:8774/v2/604bbe45ac7143a79e14f3158df67091",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:8774/v2/604bbe45ac7143a79e14f3158df67091",
                "id":"9851cb538ce04283b770820acc24e898",
                "publicURL":"http://166.78.21.23:8774/v2/604bbe45ac7143a79e14f3158df67091"
            }
            ],
            "endpoints_links":[
            ],
            "type":"compute",
            "name":"nova"
        },
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:3333",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:3333",
                "id":"0bee9a113d294dda86fc23ac22dce1e3",
                "publicURL":"http://166.78.21.23:3333"
            }
            ],
            "endpoints_links":[
            ],
            "type":"s3",
            "name":"s3"
        },
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:9292",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:9292",
                "id":"4b6e9ece7e25479a8f7bb07eb58845af",
                "publicURL":"http://166.78.21.23:9292"
            }
            ],
            "endpoints_links":[
            ],
            "type":"image",
            "name":"glance"
        },
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:8776/v1/604bbe45ac7143a79e14f3158df67091",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:8776/v1/604bbe45ac7143a79e14f3158df67091",
                "id":"221a2df63537400e929c0ce7184c5d68",
                "publicURL":"http://166.78.21.23:8776/v1/604bbe45ac7143a79e14f3158df67091"
            }
            ],
            "endpoints_links":[
            ],
            "type":"volume",
            "name":"cinder"
        },
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:8773/services/Admin",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:8773/services/Cloud",
                "id":"356f334fdb7045f7a35b0eebe26fca53",
                "publicURL":"http://166.78.21.23:8773/services/Cloud"
            }
            ],
            "endpoints_links":[
            ],
            "type":"ec2",
            "name":"ec2"
        },
        {
            "endpoints":[
            {
                "adminURL":"http://166.78.21.23:35357/v2.0",
                "region":"RegionOne",
                "internalURL":"http://166.78.21.23:5000/v2.0",
                "id":"10f3816574c14a5eb3d455b8a72dc9b0",
                "publicURL":"http://166.78.21.23:5000/v2.0"
            }
            ],
            "endpoints_links":[
            ],
            "type":"identity",
            "name":"keystone"
        }
        ],
        "user":{
            "username":"admin",
            "roles_links":[
            ],
            "id":"3273a50d6cfb4a2ebc75e83cb86e1554",
            "roles":[
            {
                "name":"admin"
            }
            ],
            "name":"admin"
        },
        "metadata":{
            "is_admin":0,
            "roles":[
            "b0d525aa42784ee0a3df1730aabdcecd"
            ]
        }
    }
}
EOF

$mock_ua->map('https://ident.os.example.com/v2.0/tokens',
    HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new(Content_Base => 'http://ident.os.example.com/'),
        $identity_response));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method => 'POST',
    uri => '/v2.0/tokens',
    body_params => { auth => { tenantName => 'admin',
            passwordCredentials => { username => 'admin', password => 'password' }}});

ok($res, 'Received resource from JSON body parameter POST request');

is( $client->response_code,
    200,
    'Successful request with response code 200' );

is( $res->{access}{token}{id},
    'a_token',
    'Access token from a successful Identity request' );

is( $client->response_body,
    $identity_response,
    'Successful request with response body' );

is( $client->response_header('Content_Base'),
    'http://ident.os.example.com/',
    'Successful request with response header' );

}

# Successful request with empty response body
{
$mock_ua->map('https://ident.os.example.com/v3',
    HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new(Content_Base => 'http://ident.os.example.com/')
        ));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method => 'GET',
    uri => '/v3'
);

is( $res,
    1,
    'Successful request with empty response body' );

is( $client->response_code,
    200,
    'Successful request with empty response body and response code 200' );
}

# Die on non-https uri when require_https enabled 
{
$mock_ua->map(
    'https://ident.os.example.com/dont_go_here',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

throws_ok(
    sub { Restish::Client->new(
            uri_host      => 'http://ident.os.example.com',
            require_https => 1 ) },
    qr/Invalid value/,
    'Die on non-https uri when require_https enabled' );
}

# Response returns non-json value
{
    $mock_ua->unmap_all();
    $mock_ua->map('https://ident.os.example.com/v2.0/tokens',
        HTTP::Response->new(
            200,
            'OK',
            HTTP::Headers->new(Content_Base => 'http://ident.os.example.com/'),
            'internet'
        )
    );

    my $client = Restish::Client->new(
        uri_host => 'https://ident.os.example.com');

    my $res = $client->request(
        method => 'POST',
        uri => '/v2.0/tokens',
        body_params => { auth => { tenantName => 'admin',
                passwordCredentials => { username => 'admin', password => 'password' }}});

    is(
        $res,
        'internet',
        'Received resource'
    );
}

done_testing();
