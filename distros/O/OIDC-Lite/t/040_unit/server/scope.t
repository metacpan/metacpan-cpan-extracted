use strict;
use warnings;

use Test::More;
use OIDC::Lite::Server::Scope;

TEST_VALIDATE_SCOPES: {
    my @valid_scopes = qw{openid};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid not_openid};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid profile};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid email};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid address};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid phone};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{openid not_openid profile};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    @valid_scopes = qw{not_openid};
    ok(OIDC::Lite::Server::Scope->validate_scopes(\@valid_scopes));

    my @invalid_scopes = qw{profile};
    ok(!OIDC::Lite::Server::Scope->validate_scopes(\@invalid_scopes));

    @invalid_scopes = qw{email};
    ok(!OIDC::Lite::Server::Scope->validate_scopes(\@invalid_scopes));

    @invalid_scopes = qw{address};
    ok(!OIDC::Lite::Server::Scope->validate_scopes(\@invalid_scopes));

    @invalid_scopes = qw{phone};
    ok(!OIDC::Lite::Server::Scope->validate_scopes(\@invalid_scopes));

    @invalid_scopes = qw{not_openid profile};
    ok(!OIDC::Lite::Server::Scope->validate_scopes(\@invalid_scopes));
};

TEST_IS_OPENID_REQUEST: {
    ok(!OIDC::Lite::Server::Scope->is_openid_request(q{scope}));

    my @scopes = qw{scope1};
    ok(!OIDC::Lite::Server::Scope->is_openid_request(\@scopes));

    @scopes = qw{openid};
    ok(OIDC::Lite::Server::Scope->is_openid_request(\@scopes));

    @scopes = qw{scope1 scope2};
    ok(!OIDC::Lite::Server::Scope->is_openid_request(\@scopes));

    @scopes = qw{scope1 openid};
    ok(OIDC::Lite::Server::Scope->is_openid_request(\@scopes));
};

TEST_IS_RQUIRED_OFFLINE_ACCESS: {
    ok(!OIDC::Lite::Server::Scope->is_required_offline_access(q{scope}));

    my @scopes = qw{online_access};
    ok(!OIDC::Lite::Server::Scope->is_required_offline_access(\@scopes));

    @scopes = qw{offline_access};
    ok(OIDC::Lite::Server::Scope->is_required_offline_access(\@scopes));

    @scopes = qw{scope1 scope2};
    ok(!OIDC::Lite::Server::Scope->is_required_offline_access(\@scopes));

    @scopes = qw{scope1 offline_access};
    ok(OIDC::Lite::Server::Scope->is_required_offline_access(\@scopes));
};

TEST_TO_NORMAL_CLAIMS: {
    my @scopes = qw{scope1};
    my $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    ok(!@$claims);

    @scopes = qw{openid};
    $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    my @expected_claims = qw{sub};
    ok(@$claims);
    is(@$claims, @expected_claims);

    @scopes = qw{openid profile};
    $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    @expected_claims = qw{sub name family_name given_name middle_name 
                          nickname preferred_username profile 
                          picture website gender birthdate 
                          zoneinfo locale updated_at};
    ok(@$claims);
    is(@$claims, @expected_claims);

    @scopes = qw{openid email};
    $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    @expected_claims = qw{sub email email_verified};
    ok(@$claims);
    is(@$claims, @expected_claims);

    @scopes = qw{openid address};
    $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    @expected_claims = qw{sub address};
    ok(@$claims);
    is(@$claims, @expected_claims);

    @scopes = qw{openid phone};
    $claims = OIDC::Lite::Server::Scope->to_normal_claims(\@scopes);
    @expected_claims = qw{sub phone_number phone_number_verified};
    ok(@$claims);
    is(@$claims, @expected_claims);
};

done_testing;
