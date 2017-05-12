use strict;
use warnings;

use Test::More;
use OIDC::Lite::Model::AuthInfo;

TEST_NEW: {

    my $info = OIDC::Lite::Model::AuthInfo->new(
        id          => q{test_id},
        user_id     => q{test_user_id},
        client_id   => q{test_client_id},
    );

    is($info->id,          q{test_id});
    is($info->user_id,     q{test_user_id});
    is($info->client_id,   q{test_client_id});

    undef($info);
    my @claims = (q{foo}, q{bar});
    $info = OIDC::Lite::Model::AuthInfo->new(
        id              => q{test_id},
        user_id         => q{test_user_id},
        client_id       => q{test_client_id},
        scope           => q{test_scope},
        refresh_token   => q{test_refresh_token},
        code            => q{test_code},
        redirect_uri    => q{test_redirect_uri},
        server_state    => q{s_state},
        id_token        => q{test_id_token},
        userinfo_claims => \@claims,
    );

    is($info->id,              q{test_id});
    is($info->user_id,         q{test_user_id});
    is($info->client_id,       q{test_client_id});
    is($info->scope,           q{test_scope});
    is($info->refresh_token,   q{test_refresh_token});
    is($info->code,            q{test_code});
    is($info->redirect_uri,    q{test_redirect_uri});
    is($info->server_state,  q{s_state});
    is($info->id_token,        q{test_id_token});
    is($info->userinfo_claims, \@claims);

};

done_testing;
