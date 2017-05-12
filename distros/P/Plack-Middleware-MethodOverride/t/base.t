#!/usr/bin/env perl -w

use strict;
use Test::More tests => 35;
#use Test::More 'no_plan';
use Plack::Test;
use URI;

BEGIN { use_ok 'Plack::Middleware::MethodOverride' or die; }

my $base_app = sub {
    my $env = shift;
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [ "$env->{REQUEST_METHOD} ($env->{'plack.original_request_method'})" ]
    ];
};
ok my $app = Plack::Middleware::MethodOverride->wrap($base_app),
    'Create MethodOverride app with no args';

my $uri = URI->new('/');

test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(GET => $uri));
    is $res->content, 'GET (GET)', 'GET should be GET';
};

test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(PUT => $uri));
    is $res->content, 'PUT (PUT)', 'PUT should be PUT';
};

test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => $uri));
    is $res->content, 'POST (POST)', 'POST should be POST';
};

# Override over POST.
$uri->query_form('x-tunneled-method' => 'PUT');
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => $uri));
    is $res->content, 'PUT (POST)', 'Should send PUT over POST';
};

test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(GET => $uri));
    is $res->content, 'GET (GET)', 'Should not send PUT over GET';
};

# Try to confuse the parser.
$uri->query_form('foo' => 'x-tunneled-method', name => 'Scott');
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => $uri));
    is $res->content, 'POST (POST)', 'POST should be POST with no tunnel';
};

# Override with a DELETE
$uri->query_form('x-tunneled-method' => 'DELETE', PUT => 'x-tunneled-method');
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => $uri));
    is $res->content, 'DELETE (POST)', 'Should send DELETE over POST';
};

##############################################################################
# Now try with a header.
my $head =  ['x-http-method-override' => 'PUT'];
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => '/', $head));
    is $res->content, 'PUT (POST)', 'Should send PUT over POST via header';
};

test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(GET => '/', $head));
    is $res->content, 'GET (GET)', 'Should not send PUT over GET via header';
};

# Try a different method.
$head->[1] = 'OPTIONS';
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => '/', $head));
    is $res->content, 'OPTIONS (POST)', 'Should send OPTIONS over POST via header';
};

# Make sure all supported methods work.
for my $meth (qw(GET HEAD PUT PATCH DELETE OPTIONS TRACE CONNECT)) {
    $head->[1] = $meth;
    test_psgi $app, sub {
        my $res = shift->(HTTP::Request->new(POST => '/', $head));
        is $res->content, "$meth (POST)", "Should support $meth";
    };

    # Lowercase too.
    $head->[1] = lc $meth;
    test_psgi $app, sub {
        my $res = shift->(HTTP::Request->new(POST => '/', $head));
        is $res->content, "$meth (POST)", "Should support $meth";
    };
}

# Make sure no other methods are allowed.
for my $meth (qw(FOO SUCK CALL EXEC)) {
    $head->[1] = $meth;
    test_psgi $app, sub {
        my $res = shift->(HTTP::Request->new(POST => '/', $head));
        is $res->content, "POST (POST)", "Should not support $meth";
    };
}
##############################################################################
# Now modify the param and the header.
ok $app = Plack::Middleware::MethodOverride->wrap(
    $base_app,
    param => 'x-do-this',
    header => 'X-Do-It-Man',
), 'Create MethodOverride app with no param and header params';

$uri->query_form('x-do-this' => 'PUT');
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => $uri));
    is $res->content, 'PUT (POST)', 'Should get PUT for custom param'
};

$head = ['X-Do-It-man' => 'DELETE'];
test_psgi $app, sub {
    my $res = shift->(HTTP::Request->new(POST => '/', $head));
    is $res->content, 'DELETE (POST)', 'Should send DELETE over POST via custom header';
};
