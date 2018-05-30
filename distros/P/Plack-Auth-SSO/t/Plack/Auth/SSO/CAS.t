use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Exception;
use Plack::Test;
use Plack::Test::Server;
use Plack::Builder;
use Plack::Session;
use HTTP::Request::Common;
use HTTP::Cookies;
use URI::Escape qw(uri_escape);
use Dancer::Middleware::Rebase;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use Data::Util qw(:check);

my $pkg;

BEGIN {
    $pkg = "Plack::Auth::SSO::CAS";
    use_ok $pkg;
}
require_ok $pkg;

dies_ok(
    sub {
        $pkg->new();
    },
    "cas_url required"
);
lives_ok(
    sub {
        $pkg->new( cas_url => "https://localhost:8443/cas" );
    },
    "lives ok"
);

my $uri_base = "http://localhost.localhost";

my $cas_app;

lives_ok(sub {

    my $cas_xml = <<EOF;
<?xml version="1.0"?>
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
    <cas:authenticationSuccess>
        <cas:user>username</cas:user>
        <cas:attributes>
            <cas:firstname>John</cas:firstname>
            <cas:lastname>Doe</cas:lastname>
            <cas:title>Mr.</cas:title>
            <cas:email>jdoe\@example.org</cas:email>
            <cas:affiliation>staff</cas:affiliation>
            <cas:affiliation>faculty</cas:affiliation>
        </cas:attributes>
        <cas:proxyGrantingTicket>PGTIOU-84678-8a9d...</cas:proxyGrantingTicket>
    </cas:authenticationSuccess>
</cas:serviceResponse>
EOF

    $cas_app = builder {

        mount "/login" => sub{
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $params = $req->query_parameters();
            my $service = URI->new( $params->get("service") );
            $service->query_param( ticket => "ticket" );
            [ 302, [
                Location => $service->as_string()
            ], []];
        };
        mount "/serviceValidate" => sub {
            [200, [ "Content-Type" => "text/xml" ], [ $cas_xml ]];
        };

    };

}, "created cas app" );

my $ua = LWP::UserAgent->new( max_redirect => 0 );
my $cas_test;

lives_ok(sub {

    $cas_test = Plack::Test::Server->new( $cas_app );

}, "created test for cas app" );

my $cas_host = $cas_test->{server}->{host} || "127.0.0.1";
my $cas_port = $cas_test->port;
my $cas_uri_base = "http://${cas_host}:${cas_port}";

$Plack::Test::Impl = "MockHTTP";

my $auth;

lives_ok(sub {
    $auth = $pkg->new(
        uri_base => $uri_base,
        cas_url => $cas_uri_base,
        authorization_path => "/login",
        error_path => "/auth/error"
    );
});

my $app;

lives_ok(sub {

    $app = builder {

        enable "Session";
        enable "+Dancer::Middleware::Rebase", base => $uri_base, strip => 0;
        mount "/auth/cas" => $auth->to_app;
        mount "/login" => sub {
            my $env = shift;
            my $session = Plack::Session->new($env);

            my $auth = $session->get("auth_sso");
            if ( ref($auth) ne "HASH" ) {
                return [
                    401, [ "Content-Type" => "text/plain" ],
                    [ "not_authenticated" ]
                ];
            }
            my $uid = $auth->{uid};
            if ( $uid ne "username" ) {
                return [
                    403,
                    [ "Content-Type" => "text/plain" ],
                    [ "unauthorized" ]
                ];
            }
            $session->set( "user_id", $uid );
            [
                302,
                [ "Location" => "$uri_base/" ],
                []
            ];
        };
        mount "/" => sub {
            my $env = shift;

            my $session = Plack::Session->new( $env );

            my $user_id = $session->get("user_id");

            if ( defined($user_id) && $user_id eq "username" ) {

                return [
                    200, [ "Content-Type" => "text/plain" ], []
                ];

            }
            else {
                return [
                    403,
                    [ "Content-Type" => "text/plain" ],
                    [ "forbidden" ]
                ];
            }
        };
    };

}, "created test app" );

my $test;
my $cookies = HTTP::Cookies->new();

lives_ok(sub {$test = Plack::Test->create($app);}, "created Plack::Test");

my $res = $test->request( GET "$uri_base/" );

is $res->code, 403, "/ should return status 403 when no session";

$res = $test->request( GET "$uri_base/login" );

is $res->code, 401, "/login should return status 401 when no auth_sso";

$res = $test->request( GET "$uri_base/auth/cas" );

$cookies->extract_cookies($res);

my $state_redirect_uri = URI->new( $res->header("location") );

is $state_redirect_uri->host_port().$state_redirect_uri->path(), "$cas_host:$cas_port/login", "/auth/cas should redirect to $cas_uri_base/login";

my $service_uri = URI->new( $state_redirect_uri->query_param( "service" ) );

is $service_uri->host_port() . $service_uri->path(), "localhost.localhost:80/auth/cas", "service param should contain /auth/cas";

my $service_state = $service_uri->query_param( "state" );

ok is_string($service_state), "state is set in service uri";

$res = $ua->request( GET( "$cas_uri_base/login?service=".uri_escape("$uri_base/auth/cas") ) );

is $res->header("location"), "$uri_base/auth/cas?ticket=ticket", "$cas_uri_base/login should redirect to /auth/cas?ticket=ticket";

$res = $test->request( GET "$uri_base/auth/cas?ticket=ticket" );

is $res->header("location"), "$uri_base/auth/error", "access callback phase without state variable should redirect to /auth/error";

$res = $ua->request( GET( $state_redirect_uri->as_string() ) );

my $req = GET($res->header("location"));
$cookies->add_cookie_header( $req );
$res = $test->request( $req );

$cookies->extract_cookies($res);

is $res->header("location"), "$uri_base/login", "/auth/cas with state should now redirect to /login";

$req = GET "$uri_base/login";
$cookies->add_cookie_header( $req );

$res = $test->request( $req );

is $res->header("location"), "$uri_base/", "$uri_base/login should now redirect to /";

$cookies->extract_cookies($res);

$req = GET "$uri_base/";
$cookies->add_cookie_header( $req );

$res = $test->request( $req );

is $res->code, 200, "/ ok";

done_testing;
