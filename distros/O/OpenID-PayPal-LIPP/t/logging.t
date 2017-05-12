use strict;
use Test::More;
use OpenID::PayPal::LIPP;

my $logged = '';

my $lipp = OpenID::PayPal::LIPP->new(
    client_id       => 'CLIENT_ID',
    client_secret   => 'CLIENT_SECRET',
    account         => 'MERCHANT_ACCOUNT',
    redirect_uri    => 'http://localhost/callback',
    logger          => sub { $logged = shift },
);

my $url = $lipp->login_url();

my $expected = 'Login url is : https://www.sandbox.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize?client_id=CLIENT_ID&response_type=code&scope=openid+email&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback';

is $logged, $expected, "Logger is behaving correctly";

done_testing();
