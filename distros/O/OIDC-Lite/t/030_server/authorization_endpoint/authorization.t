use strict;
use warnings;

use lib 't/lib';
use Test::More;

use Plack::Request;
use Try::Tiny;
use TestDataHandler;
use OIDC::Lite::Server::AuthorizationHandler;
use OIDC::Lite::Util::JWT;
use OAuth::Lite2::Util qw(build_content);
use OAuth::Lite2::Server::Error;

TestDataHandler->clear;
TestDataHandler->add_client(    id => q{client_id_1}, 
                                response_type => q{code}, 
                                redirect_uri => q{http://rp.example.org/redirect}, 
                                scope => q{openid}, 
);

TestDataHandler->add_client(    id => q{client_id_2}, 
                                response_type => q{id_token token}, 
                                redirect_uri => q{http://rp.example.org/redirect}, 
                                scope => q{openid}, 
);

TestDataHandler->add_client(    id => q{client_id_3}, 
                                response_type => q{token}, 
                                redirect_uri => q{http://rp.example.org/redirect}, 
                                scope => q{openid}, 
);

TestDataHandler->add_client(    id => q{client_id_4}, 
                                response_type => q{code token}, 
                                redirect_uri => q{http://rp.example.org/redirect}, 
                                scope => q{openid}, 
);

TestDataHandler->add_client(    id => q{client_id_5}, 
                                response_type => q{code}, 
                                redirect_uri => q{http://rp.example.org/redirect}, 
                                server_state => q{valid},
                                scope => q{require_ss}, 
);

TEST_RESPONSE_TYPE: {
    # not found
    my $params = {
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my @allowed_response_type = qw(code token);
    my $dh = TestDataHandler->new(request => $request);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    ok($authz_handler);

    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'response_type' not found});

    # not allowed
    $params = {
                response_type => q{id_token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    undef($error_message);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'response_type' not allowed});
};

TEST_CLIENT_ID: {
    # no client_id
    my $params = {
                response_type => q{token},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = qw(code token);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_client: 'client_id' not found});

    # invalid
    $params = {
                response_type => q{token},
                client_id     => q{malformed},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = qw(code token);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    undef($error_message);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_client: });

    # not allowed(client_id, response_type)
    $params = {
                response_type => q{token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = qw(code token);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    undef($error_message);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'response_type' not allowed for this 'client_id'});
};

TEST_REDIRECT_URI: {
    # not found
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                scope         => q{openid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = qw(code token);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'redirect_uri' not found});

    # invalid
    $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/invalid},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = qw(code token);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    undef($error_message);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'redirect_uri' is invalid});
};

TEST_SERVER_STATE: {
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_5},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{require_ss},
                server_state  => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = qw(code token);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_server_state: 'server_state' is invalid});
};

TEST_SCOPE: {
    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = qw(code token);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_scope: });
};

TEST_REQUIRE_SERVER_STATE: {
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_5},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{require_ss},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = qw(code token);
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: This scope requires 'server_state'});
};

TEST_NONCE: {
    my $params = {
                response_type => q{id_token token},
                client_id     => q{client_id_2},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };
    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "code token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: nonce_required});

    $params = {
                response_type => q{id_token token},
                client_id     => q{client_id_2},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                nonce         => q{nonce},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $error_message = undef;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    ok(!$error_message);

    $params = {
                response_type => q{token},
                client_id     => q{client_id_3},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $error_message = undef;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    ok(!$error_message);

    $params = {
                response_type => q{code token},
                client_id     => q{client_id_4},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $error_message = undef;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    ok(!$error_message);
};

TEST_DISPLAY: {
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                display       => q{invalid},
    };
    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'display' is invalid});

    $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                display       => q{wap},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'display' is invalid});
};

TEST_PROMPT: {
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                prompt        => q{invalid},
    };
    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'prompt' is invalid});

    $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                prompt        => q{none},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });
    $dh = TestDataHandler->new(request => $request);
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'prompt' is invalid});
};

TEST_MAX_AGE: {

    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                max_age       => -1,
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'max_age' is invalid});

};

TEST_UI_LOCALES: {

    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                ui_locales    => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'ui_locales' is invalid});

};

TEST_CLAIMS_LOCALES: {

    # invalid
    my $params = {
                response_type   => q{code},
                client_id       => q{client_id_1},
                redirect_uri    => q{http://rp.example.org/redirect},
                scope           => q{openid},
                claims_locales  => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'claims_locales' is invalid});

};

TEST_REQUEST_ID_TOKEN_HINT: {

    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                id_token_hint => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'id_token_hint' is invalid});

};

TEST_REQUEST_LOGIN_HINT: {

    # invalid
    my $params = {
                response_type   => q{code},
                client_id       => q{client_id_1},
                redirect_uri    => q{http://rp.example.org/redirect},
                scope           => q{openid},
                login_hint      => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'login_hint' is invalid});

};

TEST_REQUEST_ACR_VALUES: {

    # invalid
    my $params = {
                response_type   => q{code},
                client_id       => q{client_id_1},
                redirect_uri    => q{http://rp.example.org/redirect},
                scope           => q{openid},
                acr_values      => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'acr_values' is invalid});

};

TEST_REQUEST: {

    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                request       => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'request' is invalid});

};

TEST_REQUEST_URI: {

    # invalid
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                request_uri   => q{invalid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($error_message, q{invalid_request: 'request_uri' is invalid});

};

TEST_REQUEST_SUCCESS: {
    # no error
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                display       => q{page},
                prompt        => q{login},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $error_message;
    try {
        $authz_handler->handle_request();
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    ok(!$error_message);
};

TEST_REQUEST_DENY: {
    # code, no state
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code", "token", "id_token token");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $res = $authz_handler->deny();
    is($res->{redirect_uri}, $params->{redirect_uri});
    is($res->{query}->{error}, q{access_denied});
    ok(!$res->{query}->{state});

    # code, state
    $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                state         => q{state_str},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code", "token", "id_token token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->deny();
    is($res->{redirect_uri}, $params->{redirect_uri});
    is($res->{query}->{error}, q{access_denied});
    is($res->{query}->{state}, $params->{state});

    # token, no state
    $params = {
                response_type => q{token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code", "token", "id_token token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->deny();
    is($res->{redirect_uri}, $params->{redirect_uri});
    is($res->{fragment}->{error}, q{access_denied});
    ok(!$res->{fragment}->{state});

    # token, state
    $params = {
                response_type => q{token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                state         => q{state_str},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code", "token", "id_token token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->deny();
    is($res->{redirect_uri}, $params->{redirect_uri});
    is($res->{fragment}->{error}, q{access_denied});
    is($res->{fragment}->{state}, $params->{state});
};


TEST_REQUEST_ALLOW: {
    # code
    my $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    my $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    my $dh = TestDataHandler->new(request => $request);
    my @allowed_response_type = ("code");
    my $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    my $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{query}->{error});
    is($res->{query}->{code}, q{code_0});
    ok(!$res->{fragment});

    # code with state
    $params = {
                response_type => q{code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
                state         => q{state},
    };
    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{query}->{error});
    is($res->{query}->{code}, q{code_1});
    is($res->{query}->{state}, q{state});
    ok(!$res->{fragment});

    # token
    $params = {
                response_type => q{token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    ok(!$res->{fragment}->{code});
    ok(!$res->{fragment}->{id_token});
    is($res->{fragment}->{access_token}, q{access_token_0});
    is($res->{fragment}->{token_type}, q{Bearer});
    ok($res->{fragment}->{expires_in});
    ok(!$res->{query});

    # token without expires_in
    $params = {
                response_type => q{token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{no_exp openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    ok(!$res->{fragment}->{code});
    ok(!$res->{fragment}->{id_token});
    is($res->{fragment}->{access_token}, q{access_token_1});
    is($res->{fragment}->{token_type}, q{Bearer});
    ok(!$res->{fragment}->{expires_in});
    ok(!$res->{query});

    # id_token
    $params = {
                response_type => q{id_token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("id_token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    ok(!$res->{fragment}->{code});
    ok($res->{fragment}->{id_token});
    my $id_token_payload = OIDC::Lite::Util::JWT::payload($res->{fragment}->{id_token});
    is($id_token_payload->{user_id}, 1, q{ID Token user_id});
    is($id_token_payload->{aud}, q{audstr}, q{ID Token aud});
    is($id_token_payload->{iss}, q{issstr}, q{ID Token iss});
    is($id_token_payload->{exp}, 1349257797, q{ID Token exp});
    is($id_token_payload->{iat}, 1349257197, q{ID Token iat});
    ok(!$res->{fragment}->{access_token});
    ok(!$res->{fragment}->{token_type});
    ok(!$res->{fragment}->{expires_in});
    ok(!$res->{query});

    # code id_token
    $params = {
                response_type => q{id_token code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code id_token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    is($res->{fragment}->{code}, q{code_5});
    ok($res->{fragment}->{id_token});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($res->{fragment}->{id_token});
    is($id_token_payload->{user_id}, 1, q{ID Token user_id});
    is($id_token_payload->{aud}, q{audstr}, q{ID Token aud});
    is($id_token_payload->{iss}, q{issstr}, q{ID Token iss});
    is($id_token_payload->{exp}, 1349257797, q{ID Token exp});
    is($id_token_payload->{iat}, 1349257197, q{ID Token iat});
    ok(!$res->{fragment}->{access_token});
    ok(!$res->{fragment}->{token_type});
    ok(!$res->{fragment}->{expires_in});
    ok(!$res->{query});

    # code token
    $params = {
                response_type => q{token code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    is($res->{fragment}->{code}, q{code_6});
    ok(!$res->{fragment}->{id_token});
    is($res->{fragment}->{access_token}, q{access_token_2});
    is($res->{fragment}->{token_type}, q{Bearer});
    ok($res->{fragment}->{expires_in});
    ok(!$res->{query});

    # id_token token
    $params = {
                response_type => q{token id_token},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("id_token token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    ok(!$res->{fragment}->{code});
    ok($res->{fragment}->{id_token});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($res->{fragment}->{id_token});
    is($id_token_payload->{user_id}, 1, q{ID Token user_id});
    is($id_token_payload->{aud}, q{audstr}, q{ID Token aud});
    is($id_token_payload->{iss}, q{issstr}, q{ID Token iss});
    is($id_token_payload->{exp}, 1349257797, q{ID Token exp});
    is($id_token_payload->{iat}, 1349257197, q{ID Token iat});
    is($res->{fragment}->{access_token}, q{access_token_3});
    is($res->{fragment}->{token_type}, q{Bearer});
    ok($res->{fragment}->{expires_in});
    ok(!$res->{query});

    # code id_token token
    $params = {
                response_type => q{token id_token code},
                client_id     => q{client_id_1},
                redirect_uri  => q{http://rp.example.org/redirect},
                scope         => q{openid},
    };

    $request = Plack::Request->new({
                REQUEST_URI    => q{http://example.org/authorize},
                REQUEST_METHOD => q{GET},
                QUERY_STRING   => build_content($params),
    });

    $dh = TestDataHandler->new(request => $request);
    @allowed_response_type = ("code id_token token");
    $authz_handler = OIDC::Lite::Server::AuthorizationHandler->new(data_handler => $dh, response_types => \@allowed_response_type);
    $res = $authz_handler->allow();
    is($res->{redirect_uri}, $params->{redirect_uri});
    ok(!$res->{fragment}->{error});
    is($res->{fragment}->{code}, q{code_8});
    ok($res->{fragment}->{id_token});
    is($res->{fragment}->{access_token}, q{access_token_4});
    is($res->{fragment}->{token_type}, q{Bearer});
    ok($res->{fragment}->{expires_in});
    ok(!$res->{query});
}

done_testing;
