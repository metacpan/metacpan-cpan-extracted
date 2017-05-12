use strict;
use warnings;

use lib 't/lib';
use Test::More;

use TestDataHandler;
use OAuth::Lite2::Server::Endpoint::Token;
use OAuth::Lite2::Agent::PSGIMock;
use OAuth::Lite2::Client::WebServer;

TestDataHandler->clear();
TestDataHandler->add_client(id => q{foo}, secret => q{bar});
TestDataHandler->add_user(username => q{buz}, password => q{hoge});
my $dh = TestDataHandler->new;

# set authorization-fixture-data instead of user interaction
my $auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{buz},
    scope        => q{email},
    redirect_uri => q{http://example.org/callback},
    code         => q{valid_code},
);

my $app = OAuth::Lite2::Server::Endpoint::Token->new(
    data_handler => "TestDataHandler",
);

$app->support_grant_types(qw(authorization_code refresh_token server_state));

my $agent = OAuth::Lite2::Agent::PSGIMock->new(app => $app);

my $client = OAuth::Lite2::Client::WebServer->new(
    id                => q{foo},
    secret            => q{bar},
    authorize_uri     => q{http://localhost/authorize},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);
my $res;
$res = $client->get_access_token(
    code         => q{invalid_code},
    redirect_uri => q{http://example.org/callback},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{verification code should be invalid});
$res = $client->get_access_token(
    code         => q{invalid_code},
    redirect_uri => q{http://example.org/callback},
    use_basic_schema => 1,
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{verification code should be invalid});

$res = $client->get_access_token(
    code         => q{valid_code},
    redirect_uri => q{http://invalid.example.org/callback},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{redirect_uri_mismatch}, q{redirect_uri should be invalid});
$res = $client->get_access_token(
    code         => q{valid_code},
    redirect_uri => q{http://invalid.example.org/callback},
    use_basic_schema => 1,
);
ok(!$res, q{response should be undef});
is($client->errstr, q{redirect_uri_mismatch}, q{redirect_uri should be invalid});

$res = $client->get_access_token(
    code         => q{valid_code},
    redirect_uri => q{http://example.org/callback},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_0});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
ok(!$res->access_token_secret);
is($res->scope, q{email});
$res = $client->get_access_token(
    code         => q{valid_code},
    redirect_uri => q{http://example.org/callback},
    use_basic_schema => 1,
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_1});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
ok(!$res->access_token_secret);
is($res->scope, q{email});

# use Authorization Header flag for Basic Client Authentication
#$res = $client->get_access_token(
#    code         => q{valid_code},
#    redirect_uri => q{http://example.org/callback},
#    use_basic_schema    => 1
#);
#ok($res, q{response should be not undef});
#is($res->access_token, q{access_token_0});
#is($res->refresh_token, q{refresh_token_0});
#is($res->expires_in, q{3600});
#is($res->scope, q{email});

$res = $client->refresh_access_token(
    refresh_token => q{invalid_refresh_token},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{refresh_token should be invalid-grant});
$res = $client->refresh_access_token(
    refresh_token => q{invalid_refresh_token},
    use_basic_schema => 1,
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{refresh_token should be invalid-grant});

$res = $client->refresh_access_token(
    refresh_token => q{refresh_token_0},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_2});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
ok(!$res->access_token_secret);
is($res->scope, q{email});
$res = $client->refresh_access_token(
    refresh_token => q{refresh_token_0},
    use_basic_schema => 1,
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_3});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
ok(!$res->access_token_secret);
is($res->scope, q{email});

# use server_state
my $state = $client->get_server_state;
$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{buz},
    scope        => q{email},
    redirect_uri => q{http://example.org/callback},
    code         => q{valid_code_2},
    server_state => $state->server_state,
);
## no server_state
$res = $client->get_access_token(
    code         => q{valid_code_2},
    redirect_uri => q{http://example.org/callback},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_server_state}, q{server_state should be invalid});

$res = $client->get_access_token(
    code         => q{valid_code_2},
    redirect_uri => q{http://example.org/callback},
    server_state => q{invalid},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_server_state}, q{server_state should be invalid});

$res = $client->get_access_token(
    code         => q{valid_code_2},
    redirect_uri => q{http://example.org/callback},
    server_state => $state->server_state,
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_4});
is($res->refresh_token, q{refresh_token_1});
is($res->expires_in, q{3600});
is($res->scope, q{email});

done_testing;
