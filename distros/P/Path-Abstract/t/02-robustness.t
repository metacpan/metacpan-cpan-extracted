#!perl -T

use strict;
use warnings;

use Test::More;
use Path::Abstract qw/path/;
use Scalar::Util qw/blessed/;

plan qw/no_plan/;

package SomeRandomPackage;

sub new {
    return bless {}, shift;
}

package main;

my $object = SomeRandomPackage->new;

ok($object);
ok(blessed $object);

my $path;
$path = path qw/apple cherry grape/;
is($path, qq(apple/cherry/grape));

$path = $path->child($object);
like($path, qr{^apple/cherry/grape/SomeRandomPackage=HASH\(0x});

$path = $path->child([]);
like($path, qr{^apple/cherry/grape/SomeRandomPackage=HASH\(0x});
