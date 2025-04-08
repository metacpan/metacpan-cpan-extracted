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
    
    ok($router->compile, 'Routes compiled successfully');
    
    # First test: Check memory consumption after multiple matches
    my $initial_size = total_size($router);
    note("Initial router size: $initial_size bytes");
    
    # Perform a bunch of matches
    for (1..100000) {
        my @ret = $router->match('/users/123');
        @ret = $router->match('/users/456/edit');
        @ret = $router->match('/users/789/posts/42');
        @ret = $router->match('/blog/2023/05/15/perl-router');
        @ret = $router->match('/nonexistent/path');  # Non-matching path
    }
    
    my $final_size = total_size($router);
    note("Final router size after 5000 matches: $final_size bytes");
    
    # Allow for small variations in memory size
    my $size_diff = abs($final_size - $initial_size);
    ok($size_diff < 1024, "Router size did not increase significantly ($size_diff bytes difference)");
    
    # Second test: Use Test::LeakTrace to detect memory leaks
    my $leaks = 0;
    no_leaks_ok {
        for (1..100000) {
            my @result = $router->match('/users/123/posts/42');
        }
    } "No memory leaks detected during repeated matching";
};

done_testing;
