#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 6 + 1;
use Test::Warnings;

my $module = 'Tail::Tool::PostProcess';
use_ok( $module );

my $post = $module->new( post => 1 );
ok $post, 'Can create a new object';
ok $post->post, ' Post object is true';
eval { $post->post(0) };
ok $@, 'Can\'t change the value of post';

$post = $module->new( post => 0 );
ok $post, 'Can create a new object';
ok !$post->post, ' Post object is false';
