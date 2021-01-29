#!/usr/bin/env perl
use SQL::Tree;
use Test2::V0;

my $args = {
    driver    => 'SQLite',
    table     => 'test',
    postfix   => '_tree',
    type      => 'integer',
    id        => 'id',
    parent_id => 'parent_id',
};

my $t = SQL::Tree->new($args);
isa_ok $t, 'SQL::Tree';
like( $t->generate(), qr/CREATE TABLE test_tree/, 'basic use' );

done_testing();
