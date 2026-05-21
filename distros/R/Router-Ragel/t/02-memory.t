#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Devel::Size qw(total_size);
use Test::LeakTrace;

require_ok('Router::Ragel');

subtest 'Check for memory leaks during matching' => sub {
    plan tests => 3;

    my $router = Router::Ragel->new;

    # Add several routes with different patterns and placeholders
    $router->add('/users', 'users_list');
    $router->add('/users/:id', 'user_detail');
    $router->add('/users/:id/edit', 'user_edit');
    $router->add('/users/:id/posts/:post_id', 'user_post');
    $router->add('/blog/:year/:month/:day/:slug', 'blog_post');
    $router->add('/items/:id<int>', 'typed_int');
    $router->add('/v/:major<int>.:minor<int>', 'typed_inline');
    $router->add('/code/:c<[0-9]{4}>', 'typed_raw');

    ok($router->compile, 'Routes compiled successfully');

    # First test: Check memory consumption after multiple matches
    my $initial_size = total_size($router);
    note("Initial router size: $initial_size bytes");

    # Perform a bunch of matches across both untyped and typed routes
    for (1..100000) {
        my @ret = $router->match('/users/123');
        @ret = $router->match('/users/456/edit');
        @ret = $router->match('/users/789/posts/42');
        @ret = $router->match('/blog/2023/05/15/perl-router');
        @ret = $router->match('/items/42');
        @ret = $router->match('/v/1.7');
        @ret = $router->match('/code/1234');
        @ret = $router->match('/nonexistent/path');  # Non-matching path
    }

    my $final_size = total_size($router);
    note("Final router size after 800000 matches: $final_size bytes");

    # All return SVs are mortalized; total_size of the router itself must not change.
    is($final_size, $initial_size, "Router size unchanged after matching");

    # Second test: Use Test::LeakTrace to detect memory leaks
    no_leaks_ok {
        for (1..100000) {
            my @r1 = $router->match('/users/123/posts/42');
            my @r2 = $router->match('/items/99');
            my @r3 = $router->match('/v/2.5');
            my @r4 = $router->match('/code/4242');
            my @r5 = $router->match('/no/such/path');
        }
    } "No memory leaks detected during repeated matching";
};

done_testing;
