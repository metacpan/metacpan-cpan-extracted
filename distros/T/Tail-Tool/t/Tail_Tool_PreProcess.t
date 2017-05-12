#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 6 + 1;
use Test::Warnings;

my $module = 'Tail::Tool::PreProcess';
use_ok( $module );

my $pre = $module->new( post => 1 );
ok $pre, 'Can create a new object';
ok !$pre->post, ' Post object is false';
eval { $pre->post(0) };
ok $@, 'Can\'t change the value of post';

$pre = $module->new( post => 0 );
ok $pre, 'Can create a new object';
ok !$pre->post, ' Post object is false';
