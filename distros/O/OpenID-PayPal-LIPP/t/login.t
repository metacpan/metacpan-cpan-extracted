use strict;
use Test::More;
use Test::MockModule;
use OpenID::PayPal::LIPP;

my $lipp = OpenID::PayPal::LIPP->new(
    client_id       => 'CLIENT_ID',
    client_secret   => 'CLIENT_SECRET',
    account         => 'MERCHANT_ACCOUNT',
    redirect_uri    => 'http://localhost/callback',
);

is $lipp->login_url(), 'https://www.sandbox.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize?client_id=CLIENT_ID&response_type=code&scope=openid+email&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback', 'Login url without state sandbox OK';
is $lipp->login_url('myState'), 'https://www.sandbox.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize?client_id=CLIENT_ID&response_type=code&scope=openid+email&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback&state=myState', 'Login url with state sandbox OK';

{
    my $mock = Test::MockModule->new('LWP::UserAgent');
    $mock->mock('request', sub {
        my $response = HTTP::Response->parse(
'HTTP/1.1 200 OK
Date: Sat, 30 Apr 2016 14:00:20 GMT
Content-Type: application/json

{"token_type":"Bearer","expires_in":"28800","refresh_token":"REFRESH_TOKEN","id_token":"ID_TOKEN","access_token":"ACCESS_TOKEN"}'
 );
        return $response;
    });
    my $token = $lipp->exchange_code( 'FAKE CODE' );
    is $token->{access_token}, "ACCESS_TOKEN", "Access token correct";
    is $token->{refresh_token}, "REFRESH_TOKEN", "Refresh token correct";

    $mock->mock('request', sub {
        my $response = HTTP::Response->parse(
'HTTP/1.1 200 OK
Date: Sat, 30 Apr 2016 14:06:44 GMT
Content-Length: 165
Content-Type: application/json;charset=UTF-8

{"verified":"true","email":"user@domain.com","user_id":"https://www.paypal.com/webapps/auth/identity/user/xxxxxxxxxxxx"}');
    });

    my $user_detail = $lipp->get_user_details( access_token => 'FAKE TOKEN' );

    is $user_detail->{email}, 'user@domain.com', "Get user detail working";
}

done_testing;
