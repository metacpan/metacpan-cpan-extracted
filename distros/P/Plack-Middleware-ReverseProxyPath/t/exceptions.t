use strict;
use warnings;

use Test::More;
use Scalar::Util qw( blessed );
use Plack::Test;
use Plack::Request;
use Plack::Middleware::ReverseProxyPath;
use Plack::App::URLMap;
use HTTP::Request::Common;

my $XFSN  = 'X-Forwarded-Script-Name';
my $XTP   = 'X-Traversal-Path';
my $HXFSN = 'HTTP_X_FORWARDED_SCRIPT_NAME';
my $HXTP  = 'HTTP_X_TRAVERSAL_PATH';

my $expecting_failure;

sub echo_env {
    my ($env) = @_;
    [200, [ qw(Content-type text/plain) ],
        [ map { "$_: $env->{$_}\n" } keys %$env ] ]
}

my $env_inner  = \&echo_env;

my $env_wrapped  = Plack::Middleware::ReverseProxyPath->wrap($env_inner);

my $url_map = Plack::App::URLMap->new;
$url_map->map( "/env_wrapped"    => $env_wrapped );

# catch and test exceptions for PMW::HTTPExceptions compat
$url_map->map( "/env_catch"      => sub {
            my $env = shift;
            my $res = eval {
                $env_wrapped->($env);
            };
            if ( $@ ) {
                my $e = $@;
                ok( blessed($e) );
                ok( $e->can('code') );
                is( $e->code, 500 );
                ok( $e->can('message') );
                ok( $e->message, qr{is not a prefix} );

                return [ $e->code, [ qw(Content-type text/plain) ],
                                   [ $e->message ] ];
            } else {
                fail ( "Didn't get an exception" );
                return $res;
            }

        }
    );

# request => sub { response checks }

my @tests = (
    # extra headers are used (THIS_MARKER)

    # XTP too short
    (GET "/env_catch", $XFSN => '/this', $XTP => '/bad_tp' ) => sub {
        is $_->code, 500;
        like $_->content, qr{ TRAVERSAL_PATH .*?
                              (?-x:is not a prefix of)  .*?
                              SCRIPT_NAME }six;
    },
    (GET "/env_catch", $XFSN => '/this', $XTP => '/bad_tp' ) => sub {
        is $_->code, 500;
        like $_->content, qr{ TRAVERSAL_PATH .*?
                              (?-x:is not a prefix of)  .*?
                              SCRIPT_NAME }six;
    },

    # XTP longer, no prefix match
    (GET "/env_catch", $XFSN => '/this', $XTP => '/env_WRAPPED_X' ) => sub {
        is $_->code, 500;
        like $_->content, qr{ SCRIPT_NAME .*?
                              (?-x:is not a prefix of)  .*?
                              TRAVERSAL_PATH }six;
    },

    # XTP longer, '_X' left-over doesn't match empty PATH_INFO
    (GET "/env_catch", $XFSN => '/this', $XTP => '/env_catch_X' ) => sub {
        is $_->code, 500;
        like $_->content, qr{ Fragment .*?
                              (?-x:is not a prefix of)  .*?
                              PATH_INFO }six;
    },

    # XTP longer, '_X' left-over doesn't match PATH_INFO _Y
    (GET "/env_catch/_Y", $XFSN => '/this', $XTP => '/env_catch_X' )
    => sub {
        is $_->code, 500;
        like $_->content, qr{ Fragment .*?
                              (?-x:is not a prefix of)  .*?
                              PATH_INFO }six;
    },

);

while ( my ($req, $test) = splice( @tests, 0, 2 ) ) {
    test_psgi
        app => $url_map,
        client => sub {
            my $cb  = shift;
            note $req->as_string;
            my $res = $cb->($req);
            ok( !$res->is_success(), "NOT is_success")
                or diag $req->as_string, $res->as_string;
            local $_ = $res;
            $test->($res, $req);
        };
}

done_testing();

