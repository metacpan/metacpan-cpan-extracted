use strict;
use warnings;
use Test::More 0.88;

use Plack::Middleware::CrossOrigin;
use Plack::Test;
use Plack::Builder;

test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => '*',
            headers => '*',
            methods => '*',
            credentials => 0,
            max_age => 60*60*24*30,
            expose_headers => 'X-Exposed-Header',
        ;
        sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ] };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $req = HTTP::Request->new(GET => 'http://localhost/');
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'No CORS headers added with no Origin header';
        is $res->header('Vary'), 'Origin', '... but Vary header added';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), '*', 'Access-Control-Allow-Origin header added';
        is $res->header('Access-Control-Expose-Headers'), 'X-Exposed-Header', 'Access-Control-Expose-Headers header added';
        is $res->header('Access-Control-Max-Age'), undef, 'No Max-Age header for simple request';
        is $res->header('Vary'), 'Origin', 'Vary header added';
        is $res->content, 'Hello World', "CORS handling doesn't interfere with request content";

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), '*', 'Access-Control-Allow-Origin header added for preflight';
        is $res->header('Access-Control-Allow-Methods'), 'POST', 'Access-Control-Allow-Methods header added for preflight';
        is $res->header('Vary'), 'Origin', 'Vary header added for preflight';
        is $res->header('Access-Control-Max-Age'), 60*60*24*30, 'Max-Age header added for preflight';

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'X-Extra-Header',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        ok $res->header('Access-Control-Allow-Origin'), 'Request with extra headers allowed';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Referer' => 'http://www.example.com/page',
            'User-Agent' => 'AppleWebKit/534.16',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), '*', 'Buggy GET request from WebKit includes Allow-Origin header';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Referer' => 'http://www.example.com/page',
            'User-Agent' => 'AppleWebKit/534.19',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'New versions of WebKit don\'t trigger referer workaround';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, join '', @_ };
        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'User-Agent' => 'AppleWebKit/534.16',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'Buggy GET request from WebKit without Referer does not include Allow-Origin header';
        is $res->header('Vary'), 'Origin', 'Vary header added';
        is_deeply \@warnings, [], 'No warnings from buggy WebKit request';
    };

test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => [ 'http://www.example.com' ],
            methods => ['GET', 'POST'],
            headers => ['X-Extra-Header', 'X-Extra-Header-2'],
            max_age => 60*60*24*30,
            expose_headers => '*',
        ;
        sub { [ 200, [
            'Content-Type' => 'text/plain',
            'X-Some-Other-Header' => 'true',
        ], [ 'Hello World' ] ] };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'X-Extra-Header',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        ok $res->header('Access-Control-Allow-Origin'), 'Request with explicitly listed extra header allowed';
        is $res->header('Access-Control-Allow-Origin'), 'http://www.example.com', 'Explicitly listed origin returned';
        is $res->header('Access-Control-Allow-Headers'), 'X-Extra-Header, X-Extra-Header-2', 'Allowed headers returned';
        is $res->header('Access-Control-Allow-Methods'), 'GET, POST', 'Allowed methods returned';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'X-Extra-Header-Other',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'Request with unmatched extra header rejected';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Origin' => 'http://www.example2.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'Request with unmatched origin rejected';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'DELETE',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'Request with unmatched method rejected';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->content, 'Hello World', 'OPTIONS request without Allow-Origin processes as normal';
        is $res->header('Access-Control-Expose-Headers'), 'Vary, X-Some-Other-Header', 'Wildcard expose headers returned';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Referer' => 'http://www.example.com/page',
            'User-Agent' => 'AppleWebKit/534.16',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), 'http://www.example.com', 'Buggy GET request from WebKit includes Allow-Origin header based on referer';
        is $res->header('Vary'), 'Origin', 'Vary header added';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Referer' => 'http://www.example.com/page',
            'User-Agent' => 'AppleWebKit/534.19',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Origin'), undef, 'New versions of WebKit don\'t trigger referer workaround';
        is $res->header('Vary'), 'Origin', 'Vary header added';
    };

test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => '*',
            methods => '*',
            credentials => 1,
        ;
        sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ] };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->header('Access-Control-Allow-Credentials'), 'true', 'Resource with credentials adds correct header';
        is $res->header('Access-Control-Allow-Origin'), 'http://www.example.com', '... and an explicit origin';
        is $res->header('Vary'), 'Origin', '... and the Vary header';
    };

my $has_run;
test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => 'http://localhost',
        ;
        sub {
            $has_run = 1;
            [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
        };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $req = HTTP::Request->new(POST => 'http://localhost/', [
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        is $res->code, 403, 'Disallowed simple request returns 403 error';
        ok ! $has_run, ' ... and aborts before running main app';
        is $res->header('Vary'), 'Origin', ' ... but still adds the Vary header';

        $has_run = 0;
        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Referer' => 'http://www.example.com/page',
            'User-Agent' => 'AppleWebKit/534.16',
        ]);
        $res = $cb->($req);
        ok $has_run, 'WebKit workaround always allows app to run';
        is $res->header('Vary'), 'Origin', 'Vary header added';
    };

test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => 'http://localhost',
            continue_on_failure => 1,
        ;
        sub {
            $has_run = 1;
            [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
        };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $has_run = 0;
        $req = HTTP::Request->new(POST => 'http://localhost/', [
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        ok $has_run, 'continue_on_failure allows main app to run for simple requests';
        is $res->code, 200, ' ... and passes through results';
        is $res->header('Access-Control-Allow-Origin'), undef, ' ... and doesn\'t add headers to allow CORS';
        is $res->header('Vary'), 'Origin', ' ... but adds the Vary header';

        $has_run = 0;
        $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
            'Access-Control-Request-Method' => 'POST',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);
        ok ! $has_run, 'continue_on_failure doesn\'t run main app for preflighted request';
        is $res->header('Vary'), 'Origin', ' ... but adds the Vary header';
    };

{
    my @headers = ('Content-Type' => 'text/plain', 'Vary' => 'Accept-Language');
    test_psgi
        app => builder {
            enable 'CrossOrigin',
                origins => 'http://localhost',
            ;
            sub {
                [ 200, [ @headers ], [ 'Hello World' ] ];
            };
        },
        client => sub {
            my $cb = shift;
            my $req;
            my $res;

            $req = HTTP::Request->new(GET => 'http://localhost/', [
                'Origin' => 'http://localhost',
            ]);
            $res = $cb->($req);
            is $res->header('Vary'), 'Accept-Language, Origin', 'Vary header extended';

            unshift @headers, 'Vary' => 'Origin';
            $req = HTTP::Request->new(GET => 'http://localhost/', [
                'Origin' => 'http://localhost',
            ]);
            $res = $cb->($req);
            is $res->header('Vary'), 'Origin, Accept-Language', 'Vary header not duplicated';
        };
}

{
   # Test that the access control headers are returned as single headers
   # with comma-separated values. IE 11 (at least) appears to only evaluate
   # the first 'Access-Control-Allow-Headers' header.
   #
   # We can't use test_psgi for this test because after the PSGI response
   # is parsed by HTTP::Response we can no longer tell how the headers were
   # actually formatted.
   my $app = builder {
        enable 'CrossOrigin',
            origins => [ 'http://www.example.com' ],
            methods => ['GET', 'POST'],
            headers => ['X-Extra-Header', 'X-Extra-Header-2'],
            expose_headers => ['X-Exposed-Header', 'X-Exposed-Header2'],
        ;
        sub { [ 200, [
            'Content-Type' => 'text/plain',
        ], [ 'Hello World' ] ] };
    };

   my $req = HTTP::Request->new(OPTIONS => 'http://localhost/', [
      'Access-Control-Request-Method' => 'POST',
      'Origin' => 'http://www.example.com',
   ]);

   my $res = $app->($req->to_psgi);
   is_deeply($res, [
      200,
      [
         'Content-Type'                  => 'text/plain',
         'Vary'                          => 'Origin',
         'Access-Control-Allow-Origin'   => 'http://www.example.com',
         'Access-Control-Allow-Methods'  => 'GET, POST',
         'Access-Control-Allow-Headers'  => 'X-Extra-Header, X-Extra-Header-2',
         'Access-Control-Expose-Headers' => 'X-Exposed-Header, X-Exposed-Header2'
      ],
      []
   ], 'headers returned as comma separated values for the benenfit of IE');
}

test_psgi
    app => builder {
        enable 'CrossOrigin',
            origins => [ 'http://*.example.com' ],
        ;
        sub { [ 200, [
            'Content-Type' => 'text/plain',
        ], [ 'Hello World' ] ] };
    },
    client => sub {
        my $cb = shift;
        my $req;
        my $res;

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Access-Control-Request-Method' => 'GET',
            'Origin' => 'http://www.example.com',
        ]);
        $res = $cb->($req);

        is $res->header('Access-Control-Allow-Origin'), 'http://www.example.com',
          'wildcard as partial domain allowed';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Access-Control-Request-Method' => 'GET',
            'Origin' => 'http://www2.example.com',
        ]);
        $res = $cb->($req);

        is $res->header('Access-Control-Allow-Origin'), 'http://www2.example.com',
          'wildcard as partial domain matches numbers';

        $req = HTTP::Request->new(GET => 'http://localhost/', [
            'Access-Control-Request-Method' => 'GET',
            'Origin' => 'http://www.example2.com',
        ]);
        $res = $cb->($req);

        ok !$res->header('Access-Control-Allow-Origin'),
          'non-matching origin not allowed with wildcard';

    },
;

done_testing;
