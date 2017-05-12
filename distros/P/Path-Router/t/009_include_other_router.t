#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Fatal 0.012;
use Test::Path::Router;

use Path::Router;

my $poll_router = Path::Router->new();
isa_ok($poll_router, 'Path::Router');

# create some routes

$poll_router->add_route('' => (
    defaults       => {
        controller => 'polls',
        action     => 'index',
    }
));

$poll_router->add_route(':id/vote' => (
    defaults       => {
        controller => 'polls',
        action     => 'vote',
    },
    validations => {
        id      => qr/\d+/
    }
));

$poll_router->add_route(':id/results' => (
    defaults       => {
        controller => 'polls',
        action     => 'results',
    },
    validations => {
        id      => qr/\d+/
    }
));

path_ok($poll_router, $_, '... matched path (' . $_ . ')')
foreach qw[
    /
    /15/vote
    /15/results
];

routes_ok($poll_router, {
    '' => {
        controller => 'polls',
        action     => 'index',
    },
    '15/vote' => {
        controller => 'polls',
        action     => 'vote',
        id         => 15,
    },
    '15/results' => {
        controller => 'polls',
        action     => 'results',
        id         => 15,
    },
},
"... our routes are solid");

# root router

my $router = Path::Router->new();
isa_ok($poll_router, 'Path::Router');

# create some routes

$router->add_route('' => (
    defaults       => {
        controller => 'mysite',
        action     => 'index',
    }
));

$router->add_route('admin' => (
    defaults       => {
        controller => 'admin',
        action     => 'index',
    }
));

$router->include_router('polls/' => $poll_router);

path_ok($router, $_, '... matched path (' . $_ . ')')
foreach qw[
    /
    /admin
    /polls/
    /polls/15/vote
    /polls/15/results
];

routes_ok($router, {
    '' => {
        controller => 'mysite',
        action     => 'index',
    },
    'admin' => {
        controller => 'admin',
        action     => 'index',
    },
    'polls' => {
        controller => 'polls',
        action     => 'index',
    },
    'polls/15/vote' => {
        controller => 'polls',
        action     => 'vote',
        id         => 15,
    },
    'polls/15/results' => {
        controller => 'polls',
        action     => 'results',
        id         => 15,
    },
},
"... our routes are solid");

# hmm, will this work

my $test_router = Path::Router->new();
isa_ok($test_router, 'Path::Router');

# create some routes

$test_router->add_route('testing' => (
    defaults       => {
        controller => 'testing',
        action     => 'index',
    }
));

$test_router->add_route('testing/:id' => (
    defaults       => {
        controller => 'testing',
        action     => 'get_id',
    },
    validations => {
        id      => qr/\d+/
    }
));

$router->include_router('' => $test_router);

path_ok($router, $_, '... matched path (' . $_ . ')')
foreach qw[
    /
    /admin
    /polls/
    /polls/15/vote
    /polls/15/results
    /testing
    /testing/100
];

routes_ok($router, {
    '' => {
        controller => 'mysite',
        action     => 'index',
    },
    'admin' => {
        controller => 'admin',
        action     => 'index',
    },
    'polls' => {
        controller => 'polls',
        action     => 'index',
    },
    'polls/15/vote' => {
        controller => 'polls',
        action     => 'vote',
        id         => 15,
    },
    'polls/15/results' => {
        controller => 'polls',
        action     => 'results',
        id         => 15,
    },
    'testing' => {
        controller => 'testing',
        action     => 'index',
    },
    'testing/1000' => {
        controller => 'testing',
        action     => 'get_id',
        id         => 1000,
    },
},
"... our routes are solid");

# test a few errors

isnt(
    exception { $router->include_router('foo' => $test_router) },
    undef,
    "... this dies correctly"
);

isnt(
    exception { $router->include_router('/foo' => $test_router) },
    undef,
    "... this dies correctly"
);

isnt(
    exception { $router->include_router('/foo/1' => $test_router) },
    undef,
    "... this dies correctly"
);

done_testing;
