use strict;
use warnings;

use lib 't/lib';
use Test::More;

use TestDataHandler;
use OIDC::Lite::Server::Endpoint::Token;
use OAuth::Lite2::Agent::PSGIMock;
use OIDC::Lite::Client::WebServer;
use OAuth::Lite2::Server::Error;

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

my $app = OIDC::Lite::Server::Endpoint::Token->new(
    data_handler => "TestDataHandler",
);

eval{
    $app->support_grant_types(qw(invalid_grant));
};
ok($@);
my $error = $@;
isa_ok($error, "OAuth::Lite2::Server::Error::UnsupportedGrantType", q{UnsupportedGrantType});

$app->support_grant_types(qw(refresh_token));
my $agent = OAuth::Lite2::Agent::PSGIMock->new(app => $app);

my $client = OIDC::Lite::Client::WebServer->new(
    id                => q{foo},
    secret            => q{bar},
    authorize_uri     => q{http://localhost/authorize},
    access_token_uri  => q{http://localhost/access_token},
);
ok($client);

$client = OIDC::Lite::Client::WebServer->new(
    id                => q{foo},
    secret            => q{bar},
    authorize_uri     => q{http://localhost/authorize},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);

# url_to_redirect
my $uri_to_redirect = $client->uri_to_redirect(
    redirect_uri => q{http://example.org/callback},
);
like($uri_to_redirect, qr/http:\/\/localhost\/authorize?/);
like($uri_to_redirect, qr/response_type=code/);
like($uri_to_redirect, qr/client_id=foo/);
like($uri_to_redirect, qr/redirect_uri=http%3A%2F%2Fexample.org%2Fcallback/);
$uri_to_redirect = $client->uri_to_redirect(
    uri          => q{http://localhost/authorize2},
    redirect_uri => q{http://example.org/callback},
    scope        => q{scope_str},
    state        => q{state_str},
    extra        => {
        display      => q{page},
    },
);
like($uri_to_redirect, qr/http:\/\/localhost\/authorize2?/);
like($uri_to_redirect, qr/response_type=code/);
like($uri_to_redirect, qr/client_id=foo/);
like($uri_to_redirect, qr/redirect_uri=http%3A%2F%2Fexample.org%2Fcallback/);
like($uri_to_redirect, qr/state=state_str/);
like($uri_to_redirect, qr/scope=scope_str/);
like($uri_to_redirect, qr/display=page/);

my $client2 = OIDC::Lite::Client::WebServer->new(
    id                => q{foo},
    secret            => q{bar},
);
eval {
    $uri_to_redirect = $client2->uri_to_redirect(
        redirect_uri => q{http://example.org/callback},
    );
};
like($@, qr/uri not found/);

my $res;
eval {
    $res = $client2->get_access_token(
        code         => q{invalid_code},
        redirect_uri => q{http://example.org/callback},
    );
};
like($@, qr/uri not found/);

$res = $client->get_access_token(
    code         => q{invalid_code},
    redirect_uri => q{http://example.org/callback},
);
ok($client->last_request);
ok($client->last_response);
ok(!$res, q{response should be undef});
is($client->errstr, q{unsupported_grant_type}, q{grant_type is not supported});

$app->support_grant_types(qw(authorization_code refresh_token server_state));
$agent = OAuth::Lite2::Agent::PSGIMock->new(app => $app);
$client = OIDC::Lite::Client::WebServer->new(
    id                => q{foo},
    secret            => q{bar},
    authorize_uri     => q{http://localhost/authorize},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);

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
is($res->scope, q{email});
is($res->id_token, q{id_token_0});

$res = $client->get_access_token(
    uri          => q{http://localhost/access_token},
    code         => q{valid_code},
    redirect_uri => q{http://example.org/callback},
    use_basic_schema => 1,
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_1});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
is($res->scope, q{email});
is($res->id_token, q{id_token_0});

eval {
    $res = $client2->refresh_access_token(
        refresh_token => q{invalid_refresh_token},
    );
};
like($@, qr/uri not found/);

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
is($res->scope, q{email});
ok(!$res->id_token);

$res = $client->refresh_access_token(
    uri => q{http://localhost/access_token},
    refresh_token => q{refresh_token_0},
    use_basic_schema => 1,
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_3});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});
is($res->scope, q{email});
ok(!$res->id_token);

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
# no server_state
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
is($res->id_token, q{id_token_1});
is($res->expires_in, q{3600});
is($res->scope, q{email});

# redirect_uri is optional for get_access_token
eval {
    $res = $client->get_access_token(
        code         => q{invalid},
    );
};
ok(!$@, qr/redirect_uri is optional/);

done_testing;
