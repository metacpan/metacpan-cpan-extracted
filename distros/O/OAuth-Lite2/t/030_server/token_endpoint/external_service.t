use strict;
use warnings;

use lib 't/lib';
use Test::More;

use Plack::Request;
use Try::Tiny;
use TestDataHandler;
use OAuth::Lite2::Server::GrantHandler::ExternalService;
use OAuth::Lite2::Util qw(build_content);

TestDataHandler->clear;
TestDataHandler->add_client(id => q{foo}, secret => q{bar});
TestDataHandler->add_ext_account(assertion => q{assertion_1}, id => q{user_1}, client_id => q{foo});
TestDataHandler->add_ext_account(assertion => q{assertion_2}, id => q{user_1}, client_id => q{foo_2});
TestDataHandler->add_ext_account(assertion => q{assertion_3}, id => q{user_1}, client_id => q{foo}, type => q{type_3});
TestDataHandler->add_ext_account(assertion => q{assertion_4}, id => q{user_1}, client_id => q{foo}, iss  => q{iss_4});
TestDataHandler->add_ext_account(assertion => q{assertion_5}, id => q{user_1}, client_id => q{foo}, aud  => q{aud_5});

my $dh = TestDataHandler->new;

my $auth_info = $dh->create_or_update_auth_info(
    client_id => q{foo},
    user_id   => q{1},
    scope     => q{email},
);

is($auth_info->refresh_token, "refresh_token_0");

my $action = OAuth::Lite2::Server::GrantHandler::ExternalService->new;

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

# no assertion
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
}, q{invalid_request});

# invalid assertion
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_invalid},
}, q{invalid_grant});

# client_id mismatch
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_2},
}, q{invalid_grant});

# invalid type
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_3},
}, q{invalid_grant});

# invalid iss
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_4},
}, q{invalid_grant});

# invalid aud
&test_error({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_5},
}, q{invalid_grant});

&test_success({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_1},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_0},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_1},
});
&test_success({
    client_id      => q{foo},
    client_secret  => q{bar},
    assertion      => q{assertion_3},
    type => q{type_3},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_1},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_2},
});
&test_success({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_4},
    iss => q{iss_4},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_2},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_3},
});
&test_success({
    client_id     => q{foo},
    client_secret => q{bar},
    assertion     => q{assertion_5},
    aud => q{aud_5},
}, {
    token_type    => q{Bearer},
    token         => q{access_token_3},
    expires_in    => q{3600},
    refresh_token => q{refresh_token_4},
});

done_testing();
