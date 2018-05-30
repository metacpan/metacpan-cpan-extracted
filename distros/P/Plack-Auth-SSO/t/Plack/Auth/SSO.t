use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;
use lib "t/lib";
use Plack::Test::MockHTTP;
use Plack::Session;
use Plack::Builder;
use Dancer::Middleware::Rebase;
use Data::Util qw(:check);
use HTTP::Cookies;
use HTTP::Request::Common;

my $pkg;

BEGIN {
    $pkg = "Plack::Auth::SSO";
    use_ok $pkg;
}
require_ok $pkg;

$pkg = "${pkg}::Mock";

require_ok $pkg;

my $auth_app;

my $uri_base = "http://localhost:5001";
my $session_key = "my_auth_sso";
my $id = "my_id";
my $authorization_path = "/authorize";
my $error_path = "/error";

lives_ok(
    sub{
        $auth_app = $pkg->new(
            uri_base => $uri_base,
            session_key => $session_key,
            id => $id,
            authorization_path => $authorization_path
        );
    }
);

is $auth_app->error_path, $authorization_path, "error_path equals authorizaton_path if not set";

lives_ok(
    sub{
        $auth_app = $pkg->new(
            uri_base => $uri_base,
            session_key => $session_key,
            id => $id,
            authorization_path => $authorization_path,
            error_path => $error_path
        );
    }
);

is $auth_app->uri_base, $uri_base, "uri_base set";
is $auth_app->session_key, $session_key, "session_key set";
is $auth_app->id, $id, "id set";
is $auth_app->authorization_path, $authorization_path, "authorization_path set";
is $auth_app->error_path, $error_path, "error_path set";

my $plack_test;
my $plack_app;

lives_ok(
    sub {

        $plack_app = builder {

            enable "Session";
            enable "+Dancer::Middleware::Rebase", base => $uri_base, strip => 0;
            mount "/auth/mock" => $auth_app->to_app;
            mount "/authorize" => sub {
                my $env = shift;

                my $session = Plack::Session->new( $env );
                my $auth_sso = $session->get( $session_key );

                if ( is_hash_ref( $auth_sso ) ) {

                    return [ 200, [ "Content-Type" => "text/plain" ], [ "ok" ] ];

                }
                else {

                    return [ 401, [ "Content-Type" => "text/plain" ], [ "not_authenticated" ] ];

                }

            };
            mount $error_path => sub {

                my $env = shift;

                my $session = Plack::Session->new( $env );
                my $auth_sso_error = $session->get( $session_key . "_error" );

                unless( is_hash_ref( $auth_sso_error ) ){

                    return [ 200, [ "Content-Type" => "text/plain" ], [ "no errors" ] ];

                }

                [ 400, [ "Content-Type" => "text/plain" ], [ $auth_sso_error->{content} ] ];

            };

        };

    },
    "plack application created"
);
lives_ok(
    sub {

        $plack_test = Plack::Test::MockHTTP->new( $plack_app );

    },
    "plack test created"
);

my $cookies = HTTP::Cookies->new();

my $res = $plack_test->request( GET "$uri_base/authorize" );

is $res->code, 401, "authorization_path return 401 without authentication";

$res = $plack_test->request( GET "$uri_base/auth/mock" );

is $res->header("location"), "https://mock.sso.com", "authenticator redirects to external application";

$res = $plack_test->request( GET "$uri_base/auth/mock?code=invalid-code" );

is $res->header("location"), $uri_base.$error_path, "authenticator redirects errors to error_path";

$res = $plack_test->request( GET "$uri_base/auth/mock?code=authenticated" );

is $res->header("location"), $uri_base.$authorization_path, "authenticator redirects to authorization_path";

$cookies->extract_cookies( $res );

my $req = GET "$uri_base/authorize";

$cookies->add_cookie_header( $req );

$res = $plack_test->request( $req );

is $res->code, "200", "authorization_path return 200 with authentication";

done_testing;
