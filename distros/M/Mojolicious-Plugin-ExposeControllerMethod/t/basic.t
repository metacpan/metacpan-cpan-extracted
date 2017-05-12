#!/usr/bin/perl

use strict;
use warnings;

# we want to load our test app from the test directoryu
use File::Basename qw(dirname);
use File::Spec::Functions;
use lib catdir( dirname(__FILE__), 'my_app', 'lib' );

use Test::More tests => 8;
use Test::Mojo;
my $t = Test::Mojo->new('MyApp');

# get the page
my $page = $t->get_ok('/');
$t->status_is(200);

# check the functions
$page->text_is( '#name'   => 'Mark Fowler' );
$page->text_is( '#rose'   => 'Still smells sweet' );
$page->text_is( '#repeat' => 'foofoofoo' );

# check the number of times something was called was only once
my $json_page = $t->get_ok('/counter');
$json_page->status_is(200);
$json_page->json_is(
    {
        name   => 1,
        rose   => 1,
        repeat => 1,
    }
);

