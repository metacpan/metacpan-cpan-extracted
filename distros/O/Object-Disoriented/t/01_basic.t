#! /usr/bin/perl

use strict;
use warnings;

use lib qw<lib t/lib ../t/lib>;

use Test::More tests => 9;

require_ok('Object::Disoriented');

# Check basic usage
use_ok('Object::Disoriented', EN => qw<one two>);
is(one(), 1, 'got first function');
is(two(), 2, 'got second function');
ok(!eval { three(); 1 }, 'third function not created');

# Check we can do it again
use_ok('Object::Disoriented', DA => qw<en to>);
is(one(), 1, 'got first DA function');
is(two(), 2, 'got second DA function');
ok(!eval { three(); 1 }, 'third DA function not created');
