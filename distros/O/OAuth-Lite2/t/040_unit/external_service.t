use strict;
use warnings;

use lib 't/lib';
use Test::More;

use TestDataHandler;
use OAuth::Lite2::Server::Endpoint::Token;
use OAuth::Lite2::Agent::PSGIMock;
use OAuth::Lite2::Client::ExternalService;

TestDataHandler->clear;
TestDataHandler->add_client(id => q{foo}, secret => q{bar});
TestDataHandler->add_ext_account(assertion => q{assertion_1}, id => q{user_1}, client_id => q{foo});
TestDataHandler->add_ext_account(assertion => q{assertion_2}, id => q{user_1}, client_id => q{foo_2});
TestDataHandler->add_ext_account(assertion => q{assertion_3}, id => q{user_1}, client_id => q{foo}, type => q{type_3});
TestDataHandler->add_ext_account(assertion => q{assertion_4}, id => q{user_1}, client_id => q{foo}, iss  => q{iss_4});
TestDataHandler->add_ext_account(assertion => q{assertion_5}, id => q{user_1}, client_id => q{foo}, aud  => q{aud_5});

my $dh = TestDataHandler->new;

my $app = OAuth::Lite2::Server::Endpoint::Token->new(
    data_handler => "TestDataHandler",
);

$app->support_grant_types(qw( external_service refresh_token));

my $agent = OAuth::Lite2::Agent::PSGIMock->new(app => $app);

my $client = OAuth::Lite2::Client::ExternalService->new(
    id                => q{foo},
    secret            => q{bar},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);

my $res;
$res = $client->get_access_token(
    assertion => q{assertion_0},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion => q{assertion_2},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion => q{assertion_3},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion      => q{assertion_3},
    type => q{type_0},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion => q{assertion_4},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion      => q{assertion_4},
    iss => q{iss_0},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion => q{assertion_5},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

$res = $client->get_access_token(
    assertion      => q{assertion_5},
    iss => q{aud_0},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant}, q{assertion should be invalid});

# success
$res = $client->get_access_token(
    assertion => q{assertion_1},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_0});
is($res->refresh_token, q{refresh_token_0});
is($res->expires_in, q{3600});

$res = $client->get_access_token(
    assertion      => q{assertion_3},
    type => q{type_3},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_1});
is($res->refresh_token, q{refresh_token_1});
is($res->expires_in, q{3600});

$res = $client->get_access_token(
    assertion      => q{assertion_4},
    iss => q{iss_4},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_2});
is($res->refresh_token, q{refresh_token_2});
is($res->expires_in, q{3600});

$res = $client->get_access_token(
    assertion      => q{assertion_5},
    aud => q{aud_5},
);
ok($res, q{response should be not undef});
is($res->access_token, q{access_token_3});
is($res->refresh_token, q{refresh_token_3});
is($res->expires_in, q{3600});

done_testing();
