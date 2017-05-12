#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use lib 'lib';

use Morpheus::Key;
sub key {
    return Morpheus::Key->new(@_);
}

my $key = key('/a//b/c/');
is("$key", "/a/b/c", '""');

ok(key('/a//b/c/') eq key('/a/b/c'), "eq");
ok(key('/a/b/c/d/') gt key('/a/b/c/'), "gt");
ok(key('/a/b/c/') lt key('/a/b/c/d/'), "lt");
ok(key('/a/b/c/') le key('/a/b/c/d/'), "lt => le");
ok(key('/a/b/c/') le key('/a/b/c/'), "eq => le");
ok(key('/a/b/c/d/') ge key('/a/b/c/'), "gt => ge");
ok(key('/a/b/c/') ge key('/a/b/c/'), "eq => ge");
ok((not key('/a/b1/c/') le key('/a/b2/c/')) && (not key('/a/b1/c/') ge key('/a/b2/c/')), "uncomparable");
ok((not key('/a/b/c') lt key('/a/b/cd')), "lt tricky check");

is_deeply([@{key("/a//b/c/")}], ["a","b","c"], '@{}');

ok(key('/a/b/c') lt '/a//b/c/d', 'le upgrades');
ok(key('/a/b/c') eq '/a//b/c/', 'eq upgrades');

