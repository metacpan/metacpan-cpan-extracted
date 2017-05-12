#!/usr/bin/env perl -w

use 5.10.0;
use utf8;
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
use Test::More;
#use Test::More 'no_plan';
eval "use PGXN::API::Searcher";
plan skip_all => "PGXN::API::Searcher required for router testing" if $@;
plan tests => 369;

use Plack::Test;
use HTTP::Request::Common;
use Test::File::Contents;
use Test::MockModule;
use Encode;

use_ok 'PGXN::Site::Router' or die;

local $@;
eval { PGXN::Site::Router->app };
is $@, "Missing required parameters api_url, errors_to, errors_from, and feedback_to\n",
    'Should get proper error for missing parameters';

ok my $app = PGXN::Site::Router->app(
    api_url         => 'http://api.pgxn.org/',
    private_api_url => 'file:t/api',
    errors_to       => 'alerts@pgxn.org',
    errors_from     => 'api@pgxn.org',
    feedback_to     => 'feedback@pgxn.org',
), 'Instantiate the app';

# Test home page.
test_psgi $app => sub {
    my $cb = shift;
    ok my $res = $cb->(GET '/'), 'Fetch /';
    is $res->code, 200, 'Should get 200 response';
    like $res->content, qr/PGXN:/, 'The body should look correct';
};

# Test static file.
test_psgi $app => sub {
    my $cb = shift;
    ok my $res = $cb->(GET '/ui/css/html.css'), 'Fetch /pub/ui/css/html.css';
    is $res->code, 200, 'Should get 200 response';
    file_contents_is 'lib/PGXN/Site/ui/css/html.css', $res->content,
        'The file should have been served';
};

# Test bogus URL.
test_psgi $app => sub {
    my $cb = shift;
    ok my $res = $cb->(GET '/nonexistentpage'), 'Fetch /nonexistentpage';
    is $res->code, 404, 'Should get 404 response';
    like decode_utf8($res->content), qr/Resource not found\./,
        'The body should have the error';
};

# Test /search.
test_psgi $app => sub {
    my $cb = shift;

    # Mock the WWW::PGXN interface to search.
    my $mocker = Test::MockModule->new('WWW::PGXN');
    my %params;
    $mocker->mock(search => sub {
        my ($self, %p) = @_;
        %params = %p;
        return {
            query  => "ordered pair",
            limit  => 50,
            offset => 0,
            count  => 0,
            in     => $p{in} || 'doc',
            hits   => [],
        };
    });

    # Search for stuff.
    for my $in (qw(docs dists extensions users tags)) {
        for my $spec (
            [ 'q=föö'         => {                         } ],
            [ 'q=föö&o=2'     => { offset => 2             } ],
            [ 'q=föö&o=2&l=3' => { offset => 2, limit => 3 } ],
            [ 'q=föö&l=3'     => { limit  => 3             } ],
        ) {
            my $uri = "/search?$spec->[0]&in=$in";
            ok my $res = $cb->(GET $uri), "Fetch $uri";
            ok $res->is_success, 'Request should be successful';
            is_deeply \%params, {
                query => 'föö',
                in    => $in,
                limit => undef,
                offset => undef,
                %{ $spec->[1] },
            }, 'Proper params shold be passed to WWW::PGXN';
            like $res->content, qr{<h3>Search matched no documents\.</h3>},
                'Should look like search results';
        }
    }

    # Make sure no q returns 400.
    for my $q ('', '?q=') {
        my $uri = "/search$q";
        my $req = GET $uri;
        ok my $res = $cb->($req), "Fetch $uri";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 303, 'Should get 303 response';
        is $res->headers->header('location'), '/',
            "Should redirect to /";

        # Set the referrer.
        $req->referrer('http://localhost/search?q=hi');
        ok $res = $cb->($req), "Fetch $uri with localhost referrer";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 303, 'Should get 303 response';
        is $res->headers->header('location'), 'http://localhost/search?q=hi',
            "Should redirect to localhost referrer";

        # Set the referrer to another site.
        $req->referrer('http://example.com/search?q=hi');
        ok $res = $cb->($req), "Fetch $uri with external referrer";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 303, 'Should get 303 response';
        is $res->headers->header('location'), '/',
            "Should redirect to /";
    }

    for my $q ('*', '?') {
        my $uri = "/search?q=$q";
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok $res->is_error, "$uri should return an error";
        is $res->code, 400, "$uri should get 400 response";
        like decode_utf8($res->content),
            qr{<p>Bad request: Missing or invalid “q” query parameter\.</p>},
                "$uri body should have the invalid q param error";
    }

    # Make sure an invalid "in" value returns 400.
    for my $in ('foo', '') {
        ok my $res = $cb->(GET "/search?q=whu&in=$in"), "Fetch /search with in=$in";
        ok $res->is_error, 'Should return an error';
        is $res->code, 400, 'Should get 400 response';
        like decode_utf8($res->content),
            qr{<p>Bad request: Missing or invalid “in” query parameter\.</p>},
                'The body should have the invalid in param error';
    }

    # Make sure an invalid "o" and "l" values resturn 400.
    ok $res = $cb->(GET '/search?q=whu&o=foo&in=docs'), 'Fetch /search with bad o=';
    ok $res->is_error, 'Should return an error';
    is $res->code, 400, 'Should get 400 response';
    like decode_utf8($res->content),
        qr{<p>Bad request: Missing or invalid “o” query parameter\.</p>},
        'The body should have the invalid in param error';

    ok $res = $cb->(GET '/search?q=whu&l=foo&in=docs'), 'Fetch /search with bad l=';
    ok $res->is_error, 'Should return an error';
    is $res->code, 400, 'Should get 400 response';
    like decode_utf8($res->content),
        qr{<p>Bad request: Missing or invalid “l” query parameter\.</p>},
        'The body should have the invalid in param error';
};

# Test /dist/{dist} and /dist/{dist}/{version}
test_psgi $app => sub {
    my $cb = shift;

    for my $uri (qw(
        /dist/pair
        /dist/pair/
        /dist/pair/0.1.1
        /dist/pair/0.1.1/
    )) {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok $res->is_success, 'Should be a success';
        my $title = $uri =~ /0/ ? 'pair 0.1.1' : 'pair';
        like $res->content, qr{<h1>\Q$title</h1>},
            "The body should have the h1 $title";
    }
};

# Test /dist/{dist}/{+path} and /dist/{dist}/{version}/{+path}/
test_psgi $app => sub {
    my $cb = shift;

    my $uri = '/dist/pair/doc/pair.html';
    ok my $res = $cb->(GET $uri), "Fetch $uri";
    ok $res->is_success, 'Should be a success';
    like $res->content, qr{<a href="/dist/pair/" title="pair">pair</a>},
        "The body should have the distribution link";
    like $res->content, qr{<a href="/dist/pair/doc/pair\.html" title="pair">pair</a>},
        "The body should have the doc link";

    $uri = '/dist/pair/0.1.1/doc/pair.html';
    ok $res = $cb->(GET $uri), "Fetch $uri";
    ok $res->is_success, 'Should be a success';
    like $res->content, qr{\Q<a href="/dist/pair/0.1.1/" title="pair 0.1.1">pair 0.1.1</a>},
        "The body should have the distribution link";
    like $res->content, qr{\Q<a href="/dist/pair/0.1.1/doc/pair.html" title="pair">pair</a>},
        "The body should have the doc link";

    # Make sure we get 404 for nonexistent doc.
    for my $version ('', '/0.1.1') {
        my $uri = "/dist/pair$version/doc/nonexistent.html";
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 404, 'Should get 404 response';
        like $res->content, qr/Resource not found\./,
            'The body should have the error';
    }

    # Make sure we get 404 for nonexistent dist.
    $uri = '/dist/nonesuch/doc/nonesuch.html';
    ok $res = $cb->(GET $uri), "Fetch $uri";
    ok !$res->is_success, 'Should not be a success';
    is $res->code, 404, 'Should get 404 response';
    like $res->content, qr/Resource not found\./,
        'The body should have the error';
};

# Test /user/{user}/
test_psgi $app => sub {
    my $cb = shift;

    for my $uri (qw(
        /user/theory
        /user/theory/
    )) {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok $res->is_success, 'Should be a success';
        like $res->content, qr{\Q<h1 class="fn">David E. Wheeler</h1>},
            "The body should have the h1 with user's name";

        # Make sure we get 404 for nonexistent user.
        (my $bad = $uri) =~ s/theory/nonesuch/;
        ok $res = $cb->(GET $bad), "Fetch $bad";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 404, 'Should get 404 response';
        like $res->content, qr/Resource not found\./,
            'The body should have the error';
    }
};

# Test /tag/{tag}/
test_psgi $app => sub {
    my $cb = shift;

    for my $tag ('pair', 'key value') {
        for my $uri (
            "/tag/$tag",
            "/tag/$tag/",
        ) {
            ok my $res = $cb->(GET $uri), "Fetch $uri";
            ok $res->is_success, 'Should be a success';
            like decode_utf8($res->content), qr{\Q<h1>Tag: “$tag”</h1>},
                "The body should have the h1 with $tag";
        }
    }

    # We should get 404s for non-existent tags.
    for my $uri (qw(
        /tag
        /tag/
        /tag/nonesuch
        /tag/nonesuch/
    )) {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 404, 'Should get 404 response';
        like $res->content, qr/Resource not found\./,
            'The body should have the error';
    }
};

# Test /extension/{extension}/
test_psgi $app => sub {
    my $cb = shift;

    for my $ext ( 'pair', 'pgtap') {
        for my $uri (
            "/extension/$ext",
            "/extension/$ext/",
        ) {
            ok my $res = $cb->(GET $uri), "Fetch $uri";
            ok !$res->is_success, 'Should not be a success';
            is $res->code, 303, 'Should get 303 response';
            my $loc = $ext eq 'pgtap' ? '/dist/pgtap/'
                : '/dist/pair/doc/pair.html';
            is $res->headers->header('location'), $loc,
                "Should redirect to $loc";
        }
    }

    # We should get 404s for non-existent extensions.
    for my $uri (qw(
        /extension
        /extension/
        /extension/nonesuch
        /extension/nonesuch/
    )) {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 404, 'Should get 404 response';
        like $res->content, qr/Resource not found\./,
            'The body should have the error';
    }
};

# Test /users.
test_psgi $app => sub {
    my $cb = shift;

    # Try with no param.
    my $uri = '/users';
    ok my $res = $cb->(GET $uri), "Fetch $uri";
    is $res->code, 200, 'Should get 200 response';
    like $res->content, qr{\Q<h1>Users</h1>}, 'The body should look correct';

    # Try char params with both /users and /users/.
    for my $char ('', qw(a b t)) {
        for my $path ('/users', '/users/') {
            my $uri = "/users?c=$char";
            ok my $res = $cb->(GET $uri), "Fetch $uri";
            is $res->code, 200, 'Should get 200 response';
            like $res->content, qr{\Q<h1>Users</h1>}, 'The body should look correct';
            no utf8;
            like $res->content,
                  $char eq 't' ? qr{\Q<a href="/user/theory">theory</a>}
                : $char eq ''  ? qr{\Q<h3>⬅ Select a letter</h3>}
                               : qr{<p>\QNo user nicknames found starting with “$char”</p>},
                'And the content should look correct';
        }
    }

    # Make sure invalid c returns 400.
    ok $res = $cb->(GET '/users?c=foo'), 'Fetch /users with bad c=';
    ok $res->is_error, 'Should return an error';
    is $res->code, 400, 'Should get 400 response';
    like decode_utf8($res->content),
        qr{<p>Bad request: Missing or invalid “c” query parameter\.</p>},
        'The body should have the invalid in param error';

    # Make sure an invalid "o" and "l" values resturn 400.
    ok $res = $cb->(GET '/users?c=a&o=foo'), 'Fetch /users with bad o=';
    ok $res->is_error, 'Should return an error';
    is $res->code, 400, 'Should get 400 response';
    like decode_utf8($res->content),
        qr{<p>Bad request: Missing or invalid “o” query parameter\.</p>},
        'The body should have the invalid in param error';

    ok $res = $cb->(GET '/users?c=a&l=foo'), 'Fetch /users with bad l=';
    ok $res->is_error, 'Should return an error';
    is $res->code, 400, 'Should get 400 response';
    like decode_utf8($res->content),
        qr{<p>Bad request: Missing or invalid “l” query parameter\.</p>},
        'The body should have the invalid in param error';
};

# Test /recent.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/recent', '/recent/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>Recent Releases</h1>}, 'The body should look correct';
    }
};

# Test /feedback.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/feedback', '/feedback/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>Feedback</h1>}, 'The body should look correct';
    }
};

# Test /about.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/about', '/about/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>About PGXN</h1>}, 'The body should look correct';
    }
};

# Test /donors.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/donors', '/donors/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>Donors</h1>}, 'The body should look correct';
    }
};

# Test /faq.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/faq', '/faq/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>Frequently Asked Questions</h1>},
            'The body should look correct';
    }
};

# Test /mirroring.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/mirroring', '/mirroring/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        like $res->content, qr{\Q<h1>Mirroring PGXN</h1>},
            'The body should look correct';
    }
};

# Test /meta/spec.txt.
test_psgi $app => sub {
    my $cb = shift;
    my $uri = '/meta/spec.txt';
    ok my $res = $cb->(GET $uri), "Fetch $uri";
    is $res->code, 200, 'Should get 200 response';
    no utf8;
    like $res->content,
        qr{PGXN Meta Spec - The PGXN distribution metadatå specification$}m,
        'The body should look correct';
};

# Test /spec.
test_psgi $app => sub {
    my $cb = shift;
    for my $uri ('/spec', '/spec/') {
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        is $res->code, 200, 'Should get 200 response';
        no utf8;
        like $res->content,
            qr{<p>PGXN Meta Spec - The PGXN distribution metadatå specification</p>$}m,
                'The body should look correct';
    }
};

# Test legacy URLs.
test_psgi $app => sub {
    my $cb = shift;
    for my $spec (
        [ contact      => '/feedback/'  ],
        [ contributors => '/donors/'    ],
        [ mirroring    => '/mirroring/' ],
        [ faq          => '/faq/'       ],
        [ 'meta/spec'  => '/spec/'      ],
    ) {
        my $uri = "/$spec->[0].html";
        ok my $res = $cb->(GET $uri), "Fetch $uri";
        ok !$res->is_success, 'Should not be a success';
        is $res->code, 301, 'Should get 301 response';
        is $res->headers->header('location'), $spec->[1],
            "Should redirect to $spec->[1]";
    }
};

# Test /error.
my $err_output;
my $err_app = sub {
    my $env = shift;
    open my $errfh, '>', \$err_output;
    $env->{'psgix.errordocument.PATH_INFO'} = '/what';
    $env->{'psgix.errordocument.SCRIPT_NAME'} = '';
    $env->{'psgix.errordocument.SCRIPT_NAME'} = '';
    $env->{'psgix.errordocument.HTTP_HOST'} = 'localhost';
    $env->{'plack.stacktrace.text'} = 'This is the trace';
    $env->{'psgi.errors'} = $errfh;
    $app->($env);
};


test_psgi $err_app => sub {
    my $cb = shift;
    ok my $res = $cb->(GET '/error'), "GET /error";
    ok $res->is_success, q{Should be success (because it's only served as a subrequest)};
    like $res->content, qr{\Q<p>Internal server error.</p>},
        'body should contain error message';
    is $err_output, 'An error occurred during a request to http://localhost/what:

This is the trace
', 'The trace should have been send to the PSGI error handle';


    # Check the alert email.
    ok my @deliveries = Email::Sender::Simple->default_transport->deliveries,
        'Should have email deliveries.';
    is @deliveries, 1, 'Should have one message';
    is @{ $deliveries[0]{successes} }, 1, 'Should have been successfully delivered';

    my $email = $deliveries[0]{email};
    is $email->get_header('Subject'), 'PGXN Internal Server Error',
        'The subject should be set';
    is $email->get_header('From'), 'api@pgxn.org',
        'From header should be set';
    is $email->get_header('To'), 'alerts@pgxn.org',
        'To header should be set';
    is $email->get_body, 'An error occurred during a request to http://localhost/what.

Environment:

{ HTTP_HOST => "localhost", PATH_INFO => "/what", SCRIPT_NAME => "" }

Trace:

This is the trace
',
    'The body should be correct';
    Email::Sender::Simple->default_transport->clear_deliveries;
};
