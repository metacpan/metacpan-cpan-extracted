use strict;
use warnings;
use Test::More;
use Test::Exception;

use Net::Async::Zitadel::OIDC;
use Net::Async::Zitadel::Management;
use Net::Async::Zitadel::Error;

# OIDC requires issuer
throws_ok { Net::Async::Zitadel::OIDC->new(http => bless {}, 'Local::FakeHTTP') }
    qr/required/, 'OIDC needs issuer';
throws_ok {
    Net::Async::Zitadel::OIDC->new(issuer => '', http => bless {}, 'Local::FakeHTTP')
} qr/issuer must not be empty/, 'OIDC rejects empty issuer';
{
    eval { Net::Async::Zitadel::OIDC->new(issuer => '', http => bless {}, 'Local::FakeHTTP') };
    ok ref $@ && $@->isa('Net::Async::Zitadel::Error::Validation'),
        'empty issuer throws Validation exception';
}

# Management requires base_url and token
throws_ok { Net::Async::Zitadel::Management->new(http => bless {}, 'Local::FakeHTTP') }
    qr/required/, 'Management needs base_url + token';
throws_ok {
    Net::Async::Zitadel::Management->new(
        base_url => '',
        token    => 'x',
        http     => bless {}, 'Local::FakeHTTP',
    )
} qr/base_url must not be empty/, 'Management rejects empty base_url';
{
    eval {
        Net::Async::Zitadel::Management->new(
            base_url => '',
            token    => 'x',
            http     => bless {}, 'Local::FakeHTTP',
        );
    };
    ok ref $@ && $@->isa('Net::Async::Zitadel::Error::Validation'),
        'empty base_url throws Validation exception';
}

# Error class hierarchy and stringification
{
    my $api = Net::Async::Zitadel::Error::API->new(
        message     => 'API error: 404 Not Found - user not found',
        http_status => '404 Not Found',
        api_message => 'user not found',
    );
    is "$api", 'API error: 404 Not Found - user not found', 'API error stringifies';
    is $api->http_status, '404 Not Found', 'API error http_status';
    is $api->api_message, 'user not found', 'API error api_message';
    ok $api->isa('Net::Async::Zitadel::Error'), 'API error isa base Error';

    my $net = Net::Async::Zitadel::Error::Network->new(
        message => 'Discovery failed: 503 Service Unavailable',
    );
    is "$net", 'Discovery failed: 503 Service Unavailable', 'Network error stringifies';
    ok $net->isa('Net::Async::Zitadel::Error'), 'Network error isa base Error';

    my $val = Net::Async::Zitadel::Error::Validation->new(message => 'user_id required');
    is "$val", 'user_id required', 'Validation error stringifies';
}

# verify_token_f validation fails immediately without HTTP
{
    my $oidc = Net::Async::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        http   => bless {}, 'Local::FakeHTTP',
    );

    my $f = $oidc->verify_token_f(undef);
    ok $f->is_failed, 'verify_token_f(undef) returns failed Future';
    eval { $f->get };
    like "$@", qr/No token provided/, 'failed Future propagates Validation message';
}

# Management validation errors are immediate
{
    my $mgmt = Net::Async::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat',
        http     => bless {}, 'Local::FakeHTTP',
    );

    throws_ok { $mgmt->get_user_f(undef) }    qr/user_id required/,    'get_user_f validates user_id';
    throws_ok { $mgmt->get_project_f(undef) } qr/project_id required/, 'get_project_f validates project_id';
    throws_ok { $mgmt->get_app_f(undef, 'a') } qr/project_id required/, 'get_app_f validates project_id';
    throws_ok { $mgmt->get_app_f('p', undef) } qr/app_id required/,    'get_app_f validates app_id';
}

done_testing;
