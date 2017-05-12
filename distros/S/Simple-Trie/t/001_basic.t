#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok 'Simple::Trie';
my $test;

$test = Simple::Trie->new(words => 'blah');
is_deeply $test->_trie, {'b' => { 'l' => { 'a' => { 'h' => { '' => undef } } } } };
$test = Simple::Trie->new(words => 'blah foo ');
is_deeply $test->_trie,{ 'b' => { 'l' => { 'a' => { 'h' => { '' => undef } } } }, 'f' => { 'o' => { 'o' => { '' => undef } } } };
$test = Simple::Trie->new(words => ['blah', 'foo']);
is_deeply $test->_trie, { 'b' => { 'l' => { 'a' => { 'h' => { '' => undef } } } }, 'f' => { 'o' => { 'o' => { '' => undef } } } };

$test = Simple::Trie->new(words => [ qw(foo bar food) ] );

is_deeply $test->_trie, {'b' => { 'a' => { 'r' => { '' => undef }}}, 'f' => { 'o' => { 'o' => { '' => undef, 'd' => { '' => undef }}}}};
ok $test->find('foo');
ok !$test->find ('unknown');

ok ! $test->find('baz');
$test->add('baz');
ok $test->find('baz');

$test->add('foe');
my @results = $test->smart_find('f');
is_deeply [sort @results], ['foe', 'foo', 'food' ];

done_testing;
