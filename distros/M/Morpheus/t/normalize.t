#!/usr/bin/perl
package Morpheus::Test::Normalize;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Symbol;

use lib 'lib';

use Morpheus::Utils qw(normalize);

sub general : Test(4) {

    is_deeply(normalize({"a/b" => 1}), {a=>{b=>1}}, "basic test");
    is_deeply(normalize({"/a/b//" => 1}), {a=>{b=>1}}, "extra slashes");
    is_deeply(normalize({"/a//" => 1}), {a=>1}, "extra slashes in simple key");
    is_deeply(normalize({a => {b => 1}, "a/c" => 2, "/a/" => {d => 3}}), {a=>{b => 1, c => 2, d => 3}}, "normalize merges");
}

__PACKAGE__->new->runtests;
