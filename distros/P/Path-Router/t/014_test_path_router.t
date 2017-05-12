#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;
use Test::Path::Router ();
use Path::Router;

$Test::Path::Router::Test = Test::Builder->create;

my $capture = $Test::Path::Router::Test;
my $test    = Test::More->builder;
my $router  = Path::Router->new;

{
    my $output;
    $capture->output(\$output);
    $capture->failure_output(\$output);
    $capture->todo_output(\$output);
}

$router->add_route('blog' => (
    defaults => { controller => 'Blog' }
));

$router->add_route('feed' => (
    defaults => { controller => 'Feed' }
));

my %tests = (
    mapping_not_ok => {
        pass => {
            desc => 'mapping_not_ok passes when mapping not found',
            args => [{controller => 'Wiki'}, 'fail'],
        },
        fail => {
            desc => 'mapping_not_ok fails when mapping found',
            args => [{controller => 'Blog'}, 'pass'],
        },
        coderef => \&Test::Path::Router::mapping_not_ok,
    },
    mapping_ok => {
        pass => {
            desc => 'mapping_ok passes when mapping found',
            args => [{controller => 'Blog'}, 'pass'],
        },
        fail => {
            desc => 'mapping_ok fails when mapping not found',
            args => [{controller => 'Wiki'}, 'fail'],
        },
        coderef => \&Test::Path::Router::mapping_ok,
    },
   mapping_is => {
        pass => {
            desc => 'mapping_is passes when mapping matches path',
            args => [{controller => 'Blog'}, 'blog'],
        },
        fail => {
            desc => 'mapping_is fails when mapping does not match path',
            args => [{controller => 'Wiki'}, 'blog'],
        },
        coderef => \&Test::Path::Router::mapping_is,
    },
    path_not_ok => {
        pass => {
            desc => 'path_not_ok passes when path not found',
            args => ['wiki'],
        },
        fail => {
            desc => 'path_not_ok fails when path found',
            args => ['blog'],
        },
        coderef => \&Test::Path::Router::path_not_ok,
    },
    path_ok => {
        pass => {
            desc => 'path_ok passes when path found',
            args => ['blog'],
        },
        fail => {
            desc => 'path_ok fails when path not found',
            args => ['wiki'],
        },
        coderef => \&Test::Path::Router::path_ok,
    },
    path_is => {
        pass => {
            desc => 'path_is passes when path matches mapping',
            args => [blog => {controller => 'Blog'}],
        },
        fail => {
            desc => 'path_is fails when path does not match mapping',
            args => [blog => {controller => 'Wiki'}],
        },
        coderef => \&Test::Path::Router::path_is,
    },
    routes_ok => {
        pass => {
            desc => 'routes_ok passes when all paths and mappings match',
            args => [{
                blog => {controller => 'Blog'},
                feed => {controller => 'Feed'},
            }],
        },
        fail => {
            desc => 'routes_ok fails when all paths and mappings do not match',
            args => [{
                blog => {controller => 'Blog'},
                feed => {controller => 'Wiki'},
            }],
        },
        coderef => \&Test::Path::Router::routes_ok,
    },
);

for my $function (sort keys %tests) {

    my $coderef = $tests{$function}->{coderef};

    for my $state (qw(pass fail)) {

        my $arguments   = $tests{$function}->{$state}->{args};
        my $description = $tests{$function}->{$state}->{desc};

        $coderef->($router, @$arguments, $description);

        my $result = ($capture->details)[-1]->{ok};

        $result = !$result if $state eq 'fail';

        $test->ok($result, $description);
    }
}

$capture->done_testing;
$test->done_testing;
