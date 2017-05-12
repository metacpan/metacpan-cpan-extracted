#!/usr/bin/perl

use lib 't/lib';

use Class1 ();
use strict;
use Test::More tests => 18;
use warnings;

my $t = Class1->new;

is_deeply(
    [ map {$_->name; } @{ $t->meta->startup_methods } ],
    [ 'class1_startup_1', ],
    'startup',
);

is_deeply(
    [ map {$_->name; } @{ $t->meta->setup_methods } ],
    [ 'role1_setup_1', ],
    'setup',
);

is_deeply(
    [ map {$_->name; } @{ $t->meta->test_methods } ],
    [ 'class1_test_1', 'role1_test_1', 'role2_test_1', ],
    'test',
);

is_deeply(
    [ map {$_->name; } @{ $t->meta->teardown_methods } ],
    [ 'role2_teardown_1', ],
    'teardown',
);

is_deeply(
    [ map {$_->name; } @{ $t->meta->shutdown_methods } ],
    [ 'class1_shutdown_1', ],
    'shutdown',
);

is( $t->meta->plan, 12, 'planning with Test::Able::Role' );

$t->run_tests;
