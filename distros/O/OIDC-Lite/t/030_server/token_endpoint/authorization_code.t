use strict;
use warnings;

use lib 't/lib';
use Test::More;

use Plack::Request;
use Try::Tiny;
use TestDataHandler;
use OIDC::Lite::Server::GrantHandler::AuthorizationCode;
use OAuth::Lite2::Util qw(build_content);

TestDataHandler->clear;
TestDataHandler->add_client(id => q{foo}, secret => q{secret_value});
my $dh = TestDataHandler->new;

my $auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_bar},
    redirect_uri => q{http://example.org/callback},
);
is($auth_info->refresh_token, "refresh_token_0");
is($auth_info->id_token, "id_token_0");

my $action = OIDC::Lite::Server::GrantHandler::AuthorizationCode->new;

sub test_success {
    my $params = shift;
    my $expected = shift;
    my $request = Plack::Request->new({
        REQUEST_URI    => q{http://example.org/resource},
        REQUEST_METHOD => q{GET},
        QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my $res; try {
        $res = $action->handle_request($dh);
    } catch {
        my $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };

    if(exists $expected->{token}) {
        is($res->{token_type}, $expected->{token_type});
        is($res->{access_token}, $expected->{token});
    } else {
        ok(!$res->{access_token});
    }

    if(exists $expected->{secret}) {
        is($res->{access_token_secret}, $expected->{secret});
    } else {
        ok(!$res->{access_token_secret});
    }

    if(exists $expected->{expires_in}) {
        is($res->{expires_in}, $expected->{expires_in});
    } else {
        ok(!$res->{expires_in});
    }

    if(exists $expected->{refresh_token}) {
        is($res->{refresh_token}, $expected->{refresh_token});
    } else {
        ok(!$res->{refresh_token});
    }

    if(exists $expected->{id_token}) {
        is($res->{id_token}, $expected->{id_token});
    } else {
        ok(!$res->{id_token});
    }
}

sub test_error {
    my $params = shift;
    my $message = shift;
    my $request = Plack::Request->new({
        REQUEST_URI    => q{http://example.org/resource},
        REQUEST_METHOD => q{GET},
        QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my $error_message; try {
        my $res = $action->handle_request($dh);
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };

    like($error_message, qr/$message/);
}

# no code
&test_error({
    client_id     => q{foo},
    redirect_uri  => q{http://example.org/callback},
    client_secret => q{secret_value},
}, q{invalid_request});

# no redirect_uri
&test_error({
    client_id     => q{foo},
    code          => q{bar},
    client_secret => q{secret_value},
}, q{invalid_request});

# invalid client_id
&test_error({
    client_id     => q{unknown},
    code          => q{code_bar},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{invalid_client});

# invalid code
&test_error({
    client_id     => q{foo},
    code          => q{code_invalid},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{invalid_grant});

# DataHandler doesn't return AuthInfo
&test_error({
    client_id     => q{foo},
    code          => q{code_invalid_croak},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{OAuth::Lite2::Server::DataHandler::get_auth_info_by_code doesn't return OAuth::Lite2::Model::AuthInfo});

# url mismatch
&test_error({
    client_id     => q{foo},
    code          => q{code_bar},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/unknown},
}, q{redirect_uri_mismatch});

# success
&test_success({
    client_id     => q{foo},
    code          => q{code_bar},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_0},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_0},
    id_token      => q{id_token_0},
});

$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    code         => q{code_without_optional_attr},
    redirect_uri => q{http://example.org/callback},
);
&test_success({
    client_id     => q{foo},
    code          => q{code_without_optional_attr},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_1},
    expires_in    => undef,
    refresh_token => undef,
    id_token      => undef,
});

# authinfo doesn't have ridirect_uri
$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_bar2},
);
&test_error({
    client_id     => q{foo},
    code          => q{code_bar2},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{redirect_uri_mismatch});

# DataHandler doesn't return AccessToken
$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_for_croak_at},
    redirect_uri => q{http://example.org/callback},
);
&test_error({
    client_id     => q{foo},
    code          => q{code_for_croak_at},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{OAuth::Lite2::Server::DataHandler::create_or_update_access_token doesn't return OAuth::Lite2::Model::AccessToken});

# use server_state
$auth_info = $dh->create_or_update_auth_info(
    client_id    => q{foo},
    user_id      => q{1},
    scope        => q{email},
    code         => q{code_bar_2},
    redirect_uri => q{http://example.org/callback},
    server_state => q{server_state_bar},
);
# missing server_state
&test_error({
    client_id     => q{foo},
    code          => q{code_bar_2},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
}, q{invalid_server_state});
# invalid server_state
&test_error({
    client_id     => q{foo},
    code          => q{code_bar_2},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
    server_state  => q{server_state_foo},
}, q{invalid_server_state});

&test_success({
    client_id     => q{foo},
    code          => q{code_bar_2},
    client_secret => q{secret_value},
    redirect_uri  => q{http://example.org/callback},
    server_state  => q{server_state_bar},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_2},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_4},
    id_token      => q{id_token_4},
});

done_testing;
