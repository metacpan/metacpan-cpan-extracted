use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 8;

use TestDataHandler;
use OAuth::Lite2::Server::Endpoint::Token;
use OAuth::Lite2::Agent::PSGIMock;
use OAuth::Lite2::Client::ClientCredentials;

TestDataHandler->clear;
TestDataHandler->add_client(id => q{foo}, 
                            secret => q{bar}, 
                            user_id => q{100},
                            group_id => 1);
TestDataHandler->add_client(id => q{foo_2}, 
                            secret => q{bar_2}, 
                            group_id => 1);
TestDataHandler->add_user(username => q{buz}, password => q{hoge});
my $dh = TestDataHandler->new;

my $app = OAuth::Lite2::Server::Endpoint::Token->new(
    data_handler => "TestDataHandler",
);

$app->support_grant_types(qw(client_credentials grouping_refresh_token));

my $agent = OAuth::Lite2::Agent::PSGIMock->new(app => $app);

my $client = OAuth::Lite2::Client::ClientCredentials->new(
    id                => q{foo},
    secret            => q{bar},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);

# obtain refresh token
my $res = $client->get_access_token(
    scope => q{grouping_scope}
);
ok($res, q{response should be not undef});
is($res->refresh_token, q{refresh_token_0});
my $refresh_token = $res->refresh_token;

my $client_2 = OAuth::Lite2::Client::ClientCredentials->new(
    id                => q{foo_2},
    secret            => q{bar_2},
    access_token_uri  => q{http://localhost/access_token},
    agent             => $agent,
);

# success
$res = $client_2->get_grouping_refresh_token(
    refresh_token   => $refresh_token,
    scope => q{grouping_scope},
);
ok($res, q{response should be not undef});
is($res->refresh_token, q{refresh_token_1});

$res = $client_2->get_grouping_refresh_token(
    refresh_token   => $refresh_token,
    scope => q{grouping_scope},
    use_basic_schema => 1,
);
ok($res, q{response should be not undef});
is($res->refresh_token, q{refresh_token_2});

# failed
$res = $client->get_grouping_refresh_token(
    refresh_token   => q{invalid},
);
ok(!$res, q{response should be undef});
is($client->errstr, q{invalid_grant});
