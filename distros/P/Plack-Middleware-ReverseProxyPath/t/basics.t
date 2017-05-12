use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Request;
# use Plack::Builder;
use Plack::Middleware::ReverseProxyPath;
use Plack::App::URLMap;
use HTTP::Request::Common;

my $XFSN  = 'X-Forwarded-Script-Name';
my $XTP   = 'X-Traversal-Path';
my $HXFSN = 'HTTP_X_FORWARDED_SCRIPT_NAME';
my $HXTP  = 'HTTP_X_TRAVERSAL_PATH';

my $expecting_failure;

sub echo_base {
    [200, [ qw(Content-type text/plain) ],
        [ Plack::Request->new(shift)->base . "\n" ] ]
}

sub echo_env {
    my ($env) = @_;
    [200, [ qw(Content-type text/plain) ],
        [ map { "$_: $env->{$_}\n" } keys %$env ] ]
}

my $base_inner = \&echo_base;
my $env_inner  = \&echo_env;

my $base_wrapped = Plack::Middleware::ReverseProxyPath->wrap($base_inner);
my $env_wrapped  = Plack::Middleware::ReverseProxyPath->wrap($env_inner);

my $url_map = Plack::App::URLMap->new;
$url_map->map( "/base_inner"     => $base_inner );
$url_map->map( "/env_inner"      => $env_inner );
$url_map->map( "/base_wrapped"   => $base_wrapped );
$url_map->map( "/env_wrapped"    => $env_wrapped );
# $url_map->map( "/deep"           => $url_map ); # miyagawa: probably not ok
$url_map->map( "/deep/base_inner"     => $base_inner );
$url_map->map( "/deep/env_inner"      => $env_inner );
$url_map->map( "/deep/base_wrapped"   => $base_wrapped );
$url_map->map( "/deep/env_wrapped"    => $env_wrapped );
$url_map->map( "/deep/deep/base_inner"     => $base_inner );
$url_map->map( "/deep/deep/env_inner"      => $env_inner );
$url_map->map( "/deep/deep/base_wrapped"   => $base_wrapped );
$url_map->map( "/deep/deep/env_wrapped"    => $env_wrapped );

# request => sub { response checks }

my $empty = q();
$empty = qr/\s{0}/ if $] <= 5.008008; # Workaround for a 5.8.8 bug.

my @tests = (
    # sanity check tests, not using rpp
    (GET "/base_inner") => sub {
        like $_->content, qr{ /base_inner $empty $ }x;
    },

    (GET "/env_inner") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /env_inner $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_inner $empty $ }xm;
    },

    (GET "/base_inner/path") => sub {
        like $_->content, qr{ /base_inner $empty $ }x;
    },

    (GET "/env_inner/path") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /env_inner $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s /path $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_inner/path $empty $ }xm;
    },

    (GET "/deep/base_inner") => sub {
        like $_->content, qr{ /deep/base_inner $empty $ }x;
    },

    (GET "/deep/env_inner") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /deep/env_inner $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/env_inner $empty $ }xm;
    },

    (GET "/deep/deep/base_inner") => sub {
        like $_->content, qr{ /deep/deep/base_inner $empty $ }x;
    },

    (GET "/deep/deep/env_inner") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /deep/deep/env_inner $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/deep/env_inner $empty $ }xm;
    },

    # extra headers ignored
    (GET "/base_inner", $XFSN => '/this', $XTP => '/that' ) => sub {
        like $_->content, qr{ /base_inner $empty $ }x;
    },

    (GET "/env_inner", $XFSN => '/this', $XTP => '/that' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /env_inner $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_inner $empty $ }xm;
        like $_->content, qr{ ^ $HXFSN : \s /this $empty $ }xm;
        like $_->content, qr{ ^ $HXTP : \s /that $empty $ }xm;
    },

    # now we go via ReverseProxyPath to test it
    #  (all these are the same as above to THIS_MARKER)
    (GET "/base_wrapped") => sub {
        like $_->content, qr{ /base_wrapped $empty $ }x;
    },

    (GET "/env_wrapped") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /env_wrapped $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped $empty $ }xm;
    },

    (GET "/base_wrapped/path") => sub {
        like $_->content, qr{ /base_wrapped $empty $ }x;
    },

    (GET "/env_wrapped/path") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /env_wrapped $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s /path $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/path $empty $ }xm;
    },

    (GET "/deep/base_wrapped") => sub {
        like $_->content, qr{ /deep/base_wrapped $empty $ }x;
    },

    (GET "/deep/env_wrapped") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /deep/env_wrapped $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/env_wrapped $empty $ }xm;
    },

    (GET "/deep/deep/base_wrapped") => sub {
        like $_->content, qr{ /deep/deep/base_wrapped $empty $ }x;
    },

    (GET "/deep/deep/env_wrapped") => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /deep/deep/env_wrapped $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/deep/env_wrapped $empty $ }xm;
    },

    # extra headers are used (THIS_MARKER)

    (GET "/base_wrapped", $XFSN => '/this', $XTP => '/base_wrapped' ) => sub {
        like $_->content, qr{ /this $empty $ }x, "replace prefix $XFSN";
    },

    (GET "/env_wrapped", $XFSN => '/this', $XTP => '/env_wrapped' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped $empty $ }xm;
    },

    # non-segment prefix
    (GET "/base_wrapped", $XFSN => '/this', $XTP => '/base' ) => sub {
        like $_->content, qr{ /this_wrapped $empty $ }x, "non-segment prefix $XFSN";
    },

    (GET "/env_wrapped", $XFSN => '/this', $XTP => '/env' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this_wrapped $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped $empty $ }xm;
    },

    # check extra headers are there too.
    (GET "/env_wrapped", $XFSN => '/this', $XTP => '/env_wrapped' ) => sub {
        like $_->content, qr{ ^ $HXFSN : \s /this $empty $ }xm;
        like $_->content, qr{ ^ $HXTP : \s /env_wrapped $empty $ }xm;
    },

    (GET "/base_wrapped/path", $XFSN => '/this', $XTP => '/base_wrapped' )
    => sub {
        like $_->content, qr{ /this $empty $ }x, "replace prefix $XFSN";
    },

    (GET "/env_wrapped/path", $XFSN => '/this', $XTP => '/env_wrapped' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s /path $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/path $empty $ }xm;
        like $_->content, qr{ ^ $HXFSN : \s /this $empty $ }xm;
        like $_->content, qr{ ^ $HXTP : \s /env_wrapped $empty $ }xm;
    },

    (GET "/deep/base_wrapped", $XFSN => '/this', $XTP => '/deep/base_wrapped' )
    => sub {
        like $_->content, qr{ /this $empty $ }x, "replace prefix $XFSN";
    },

    (GET "/deep/env_wrapped", $XFSN => '/this', $XTP => '/deep/env_wrapped' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/env_wrapped $empty $ }xm;
        like $_->content, qr{ ^ $HXFSN : \s /this $empty $ }xm;
        like $_->content, qr{ ^ $HXTP : \s /deep/env_wrapped $empty $ }xm;
    },

    # borrow from PATH_INFO
    (GET "/base_wrapped/path/more",
        $XFSN => '/this', $XTP => '/base_wrapped/path' )
    => sub {
        like $_->content, qr{ /this $empty $ }x, "borrow from PATH_INFO";
    },

    (GET "/env_wrapped/path/more",
        $XFSN => '/this', $XTP => '/env_wrapped/path' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s /more $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/path/more $empty $ }xm;
    },

    # trailing / on request
    (GET "/base_wrapped/", $XFSN => '/this', $XTP => '/base_wrapped' )
    => sub {
        like $_->content, qr{ /this $empty $ }x, "trailing / on request";
    },

    (GET "/env_wrapped/", $XFSN => '/this', $XTP => '/env_wrapped' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s /this $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s / $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/ $empty $ }xm;
    },

    # empty replacement
    (GET "/base_wrapped", $XFSN => '', $XTP => '/base_wrapped' ) => sub {
        like $_->content, qr{ / $empty $ }x, "empty replacement";
    },

    (GET "/env_wrapped", $XFSN => '', $XTP => '/env_wrapped' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped $empty $ }xm;
    },

    (GET "/deep/base_wrapped", $XFSN => '', $XTP => '/deep/base_wrapped' )
    => sub {
        like $_->content, qr{ / $empty $ }x, "replace prefix $XFSN";
    },

    (GET "/deep/env_wrapped", $XFSN => '', $XTP => '/deep/env_wrapped' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /deep/env_wrapped $empty $ }xm;
    },

    (GET "/base_wrapped/path/more",
        $XFSN => '', $XTP => '/base_wrapped/path' )
    => sub {
        like $_->content, qr{ / $empty $ }x, "borrow from PATH_INFO";
    },

    (GET "/env_wrapped/path/more",
        $XFSN => '', $XTP => '/env_wrapped/path' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s /more $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/path/more $empty $ }xm;
    },

# From PSGI spec
# One of SCRIPT_NAME or PATH_INFO MUST be set. When REQUEST_URI is /,
# PATH_INFO should be / and SCRIPT_NAME should be empty. SCRIPT_NAME
# MUST NOT be /, but MAY be empty.

    # borrowed path_info and trailing / on request
    (GET "/base_wrapped/path/",
        $XFSN => '', $XTP => '/base_wrapped/path' )
    => sub {
        like $_->content, qr{ / $empty $ }x, "borrow from PATH_INFO, trailing req /";
    },

    (GET "/env_wrapped/path/",
        $XFSN => '', $XTP => '/env_wrapped/path' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ PATH_INFO:   \s / $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/path/ $empty $ }xm;
    },

    # doubled // (see Plack::Middleware::NoMultipleSlashes)
    (GET "/base_wrapped//path///",
        $XFSN => '/', $XTP => '/base_wrapped//path//' ) # 
    => sub {
        like $_->content, qr{ [^/]/ $empty $ }x, "multiple //";
    },
    (GET "/env_wrapped//path///",
        $XFSN => '/', $XTP => '/env_wrapped//path//' )
    => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm; # should never be just /
        like $_->content, qr{ ^ PATH_INFO:   \s / $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped//path/// $empty $ }xm;
    },

    # trailing / on headers

    # '/' replacement (this is a misconfiguration, use '')
    (GET "/base_wrapped", $XFSN => '/', $XTP => '/base_wrapped' ) => sub {
        like $_->content, qr{ / $empty $ }x, "/ replacement";
    },

    (GET "/env_wrapped", $XFSN => '/', $XTP => '/env_wrapped' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped $empty $ }xm;
    },

    # '/' replaced (this is a misconfiguration, use '')
    (GET "/base_wrapped/", $XFSN => '', $XTP => '/base_wrapped/' ) => sub {
        like $_->content, qr{ [^/]/ $empty $ }x, "trailing / trav path";
    },

    (GET "/env_wrapped/", $XFSN => '', $XTP => '/env_wrapped/' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/ $empty $ }xm;
    },


    (GET "/base_wrapped/more", $XFSN => '/', $XTP => '/base_wrapped/' )
    => sub {
        like $_->content, qr{ [^/]/ $empty $ }x, "/ replacement";
    },

    (GET "/env_wrapped/more", $XFSN => '/', $XTP => '/env_wrapped/' ) => sub {
        like $_->content, qr{ ^ SCRIPT_NAME: \s $empty $ }xm;
        # PSGI requires PATH_INFO to start with a /
        like $_->content, qr{ ^ PATH_INFO: \s /more $empty $ }xm;
        like $_->content, qr{ ^ REQUEST_URI: \s /env_wrapped/more $empty $ }xm;
    },

);

while ( my ($req, $test) = splice( @tests, 0, 2 ) ) {
    test_psgi
        app => $url_map,
        client => sub {
            my $cb  = shift;
            note $req->as_string;
            my $res = $cb->($req);
            ok($res->is_success(), "is_success")
                or diag $req->as_string, $res->as_string;
            local $_ = $res;
            $test->($res, $req);
        };
}

# these tests don't return is_success
my @error_tests = (
    # bad url (not ours)
    (GET "/" ) => sub {
        is $_->code, 404;
        like $_->content, qr/Not Found/;
    },

    # bad headers => server error
    (GET "/base_wrapped", $XFSN => '/this', $XTP => '/that' ) => sub {
        is $_->code, 500; # bogus headers cause an error
        like $_->content, qr{is not a prefix of};
    },

    # bad headers => server error
    (GET "/base_wrapped", $XFSN => '/this', $XTP => '/base_wrapped/X' ) => sub {
        is $_->code, 500; # bogus headers cause an error
        like $_->content, qr{is not a prefix of};
    },
);

# test error conditions
while ( my ($req, $test) = splice( @error_tests, 0, 2 ) ) {
    test_psgi
        app => $url_map,
        client => sub {
            my $cb  = shift;
            note $req->as_string;
            my $res = $cb->($req);
            ok(!$res->is_success(), "NOT is_success")
                or diag $req->as_string, $res->as_string;
            local $_ = $res;
            $test->($res, $req);
        };
}

done_testing();

