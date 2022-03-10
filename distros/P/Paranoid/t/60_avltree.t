#!/usr/bin/perl -T

use Test::More tests => 59;
use Paranoid;
use Paranoid::Data::AVLTree;
use Paranoid::Debug;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

my ($obj);
my @data = (
    [ foo => "bar foo" ],
    [ goo => "bar goo" ],
    [ hoo => "bar hoo" ],
    [ joo => "bar joo" ],
    [ koo => "bar koo" ],
    [ loo => "bar loo" ],
    [ boo => "bar boo" ],
    [ coo => "bar coo" ],
    [ doo => "bar doo" ],
    );

# Test basic operation with one node
ok( $obj = new Paranoid::Data::AVLTree, 'avltree object new 1' );
is( $obj->count,             0, 'avltree count 1' );
is( $obj->height,            0, 'avltree height 1' );
is( $obj->nodeExists('foo'), 0, 'avltree exists 1' );
ok( $obj->addPair( 'foo', 'bar' ), 'avltree add 1' );
is( $obj->fetchVal('foo'), 'bar', 'avltree fetch val 1' );
is( $obj->count,           1,     'avltree count 2' );
is( $obj->height,          1,     'avltree height 2' );

# Test with multiple options
ok( $obj = new Paranoid::Data::AVLTree, 'avltree object new 2' );

foreach (@data) {
    $obj->addPair(@$_);

    #warn "\nKEYS: @{[ $obj->nodeKeys ]}\n";
    #$obj->dumpKeys;
}
is( $obj->count,  9, 'avltree count 3' );
is( $obj->height, 4, 'avltree height 3' );
ok( $obj->nodeExists('loo'), 'avltree nodeExists 1' );
ok( $obj->nodeExists('boo'), 'avltree nodeExists 2' );

ok( $obj->delNode('joo'), 'avltree delete 1' );
is( $obj->count,  8, 'avltree count 3' );
is( $obj->height, 4, 'avltree height 3' );
ok( $obj->delNode('loo'), 'avltree delete 2' );
is( $obj->count,  7, 'avltree count 4' );
is( $obj->height, 3, 'avltree height 4' );
ok( $obj->delNode('koo'), 'avltree delete 3' );
is( $obj->count,  6, 'avltree count 5' );
is( $obj->height, 3, 'avltree height 5' );
ok( $obj->delNode('foo'), 'avltree delete 4' );
is( $obj->count,  5, 'avltree count 6' );
is( $obj->height, 3, 'avltree height 6' );

# Test save/load functionality and profiling
ok( $obj->save2File('t/avl.dump'), 'avltree save2File 1' );
my $obj2 = new Paranoid::Data::AVLTree;
ok( $obj2->profile(1),             'avltree profile 1' );
ok( $obj2->loadFromFile('t/avl.dump'), 'avltree loadFile 1' );
is( $obj2->count,  5, 'avltree loadFile count 1' );
is( $obj2->height, 3, 'avltree loadFile height 1' );

#warn "\nKEYS: @{[ $obj2->nodeKeys ]}\n";
#$obj2->dumpKeys;

foreach my $key ( $obj->nodeKeys ) {
    ok( $obj2->nodeExists($key), "avltree loadFile key $key exists" );
    is( $obj->fetchVal($key), $obj2->fetchVal($key),
        "avltree loadFile $key value check" );
}

my %stats = $obj2->stats;
is( scalar keys %stats, 4, 'avltree stats entries check 1' );
foreach ( keys %stats ) {
    warn "Stat $_: $stats{$_}\n";
}

#warn" First object:\n";
#$obj->dumpKeys;
#warn" Second object:\n";
#$obj2->dumpKeys;

# Test purge
ok( $obj->purgeNodes, 'avltree purge 1' );
is( $obj->count,  0, 'avltree count 7' );
is( $obj->height, 0, 'avltree height 7' );

# Test tied interface
my %test;
$obj = undef;
$obj = tie %test, 'Paranoid::Data::AVLTree';
ok( defined $obj, 'avltree tie 1' );
is( scalar keys %test, 0, 'avltree keys 1' );
is( $obj->height,      0, 'avltree height 8' );
ok( !exists $test{'foo'}, 'avltree exists 1' );
$test{'foo'} = 'bar';
is( $test{foo},        'bar', 'avltree fetch val 2' );
is( scalar keys %test, 1,     'avltree keys 2' );
is( $obj->height,      1,     'avltree height 9' );
%test = ();
is( scalar keys %test, 0, 'avltree purge-keys 1' );

foreach (@data) {
    $test{ $$_[0] } = $$_[1];
}
is( scalar keys %test, 9, 'avltree keys 3' );
is( $obj->height,      4, 'avltree height 10' );
ok( exists $test{loo}, 'avltree exists 2' );
ok( exists $test{boo}, 'avltree exists 3' );
ok( delete $test{joo}, 'avltree delete 1' );
is( scalar keys %test, 8, 'avltree keys 5' );
is( $obj->height,      4, 'avltree height 11' );

