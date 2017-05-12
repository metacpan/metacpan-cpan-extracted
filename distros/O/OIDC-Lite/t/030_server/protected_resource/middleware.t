use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestPR;
use TestPR2;
use TestDataHandler;
use Try::Tiny;
use HTTP::Response;
use HTTP::Request;
use HTTP::Message::PSGI;

my $dh = TestDataHandler->new;

my $auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_bar},
);

my $access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);

my $app = TestPR->new;

sub request {
    my $req = shift;
    my $res = try {
        HTTP::Response->from_psgi($app->($req->to_psgi));
    } catch {
        HTTP::Response->from_psgi([500, ["Content-Type" => "text/plain"], [ $_ ]]);
    };
    return $res;
}

my ($req, $res);
# LEGACY
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{OAuth %s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '1'}}, 'successful response');

$req = HTTP::Request->new("POST" => q{http://example.org/});
$req->content_type('application/x-www-form-urlencoded');
$req->content(sprintf(q{oauth_token=%s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '1'}}, 'successful response');

$req = HTTP::Request->new("GET" => sprintf(q{http://example.org/?oauth_token=%s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '1'}}, 'successful response');

# RFC
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '0'}}, 'successful response');

$req = HTTP::Request->new("POST" => q{http://example.org/});
$req->content_type('application/x-www-form-urlencoded');
$req->content(sprintf(q{access_token=%s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '0'}}, 'successful response');

$req = HTTP::Request->new("GET" => sprintf(q{http://example.org/?access_token=%s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: 'email', claims: ["user_id","email"], is_legacy: '0'}}, 'successful response');

# no parammethod
$req = HTTP::Request->new("GET" => q{http://example.org/});
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 400, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_request"}, 'invalid request');

# no token
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => q{Bearer  ,});
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 400, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_request"}, 'invalid request');

# invalid token
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => q{Bearer invalid});
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_token"}, 'invalid token');

# invalid token (croak)
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => q{Bearer token_for_croak});
$res = &request($req);
ok(!$res->is_success, 'request should fail');
like($res->content, qr/OIDC::Lite::Server::DataHandler::get_access_token doesn't return OAuth::Lite2::Model::AccessToken/, 'croak');
is($res->code, 500, 'error code');
ok(!$res->header("WWW-Authenticate"), 'no WWW-Authenticate Header');

# expired token
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
    expires_in => -60,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_token", error_description="The access token expired"}, 'invalid token');
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{OAuth %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{OAuth realm="resource.example.org", error="expired_token"}, 'invalid token');

$auth_info->id($auth_info->id + 1);
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_token"}, 'invalid token');

$auth_info->id(99);
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
like($res->content, qr/OIDC::Lite::Server::DataHandler::get_auth_info_by_id doesn't return OIDC::Lite::Model::AuthInfo/, 'croak');
is($res->code, 500, 'error code');
ok(!$res->header("WWW-Authenticate"), 'no WWW-Authenticate Header');

$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{malformed},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_bar},
);
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_token"}, 'invalid token');

$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{666},
    scope        => q{email},
    code         => q{code_bar},
);
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer realm="resource.example.org", error="invalid_token"}, 'invalid token');

# no scope
$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    code         => q{code_bar},
);
$access_token = $dh->create_or_update_access_token(
    auth_info => $auth_info,
);
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => sprintf(q{Bearer %s}, $access_token->token));
$res = &request($req);
ok($res->is_success, 'request should not fail');
is($res->content, q{{user: '1', scope: '', claims: [], is_legacy: '0'}}, 'successful response');

# no realm and 
$app = TestPR2->new;
$req = HTTP::Request->new("GET" => q{http://example.org/});
$req->header("Authorization" => q{Bearer invalid});
$res = &request($req);
ok(!$res->is_success, 'request should fail');
ok(!$res->content, 'no response content');
is($res->code, 401, 'error code');
is($res->header("WWW-Authenticate"), q{Bearer error="invalid_token", error_uri="http://resource.example.org/error"}, 'invalid token');

done_testing;
