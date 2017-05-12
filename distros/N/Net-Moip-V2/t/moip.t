use strict;
use Test2::Bundle::Extended;
use Test::Mock::Furl;
use Net::Moip::V2;
use Data::Dumper;


my $moip = Net::Moip::V2->new(
    sandbox => 1,
    token   => $ENV{MOIP_TOKEN} || 'test_token',
    key     => $ENV{MOIP_KEY}   || 'test_key',
    client_id     => $ENV{MOIP_CLIENT_ID}     || $ENV{MOIP_APP_ID} || 'test_client_id',
    client_secret => $ENV{MOIP_CLIENT_SECRET} || $ENV{MOIP_APP_SECRET} || 'test_client_secret',
);


my $ep = $moip->endpoint('orders');
isa_ok $ep, 'Net::Moip::V2::Endpoint';

is $moip->build_authorization_url('http://mysite.com', ['FOO', 'BAR', 'BAZ']),
    'https://connect-sandbox.moip.com.br/oauth/authorize?response_type=code&client_id=test_client_id&redirect_uri=http%3A%2F%2Fmysite.com&scope=FOO%2CBAR%2CBAZ';



subtest 'request_access_token' => sub {

    $Mock_furl->mock(post => sub {
        is $_[1], 'https://connect-sandbox.moip.com.br/oauth/token', 'url';
        is $_[2], [
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => $moip->_basic_auth_token,
            'Cache-Control', 'no-cache'
        ], 'headers';
        is $_[3], 'client_id=test_client_id&client_secret=test_client_secret&grant_type=authorization_code&redirect_uri=http%3A%2F%2Fmysite.com&code=THE-CODE', 'content';

        $Mock_furl_res->mock(content => sub { '{}' });
        $Mock_furl_res
    });

    $moip->request_access_token('http://mysite.com', 'THE-CODE');


    # error
    $Mock_furl->mock(post => sub {

        $Mock_furl_res->mock(code => sub { 500 });
        $Mock_furl_res->mock(is_success => sub { 0 });
        $Mock_furl_res->mock(status_line => sub { 'mock error' });
        $Mock_furl_res->mock(content => sub { '{}' });
        $Mock_furl_res
    });

    my $res = $moip->request_access_token('http://mysite.com', 'THE-CODE');
    is $res->{error}, 'mock error', 'request error';

};





done_testing;
