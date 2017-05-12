#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype);

use Object::Anon;
my $o;

$o = anon {};
ok(blessed $o, "anon returns an object");
is(reftype $o, "HASH", "... that is a hash");
is(scalar keys %$o, 0, "... with no keys");

$o = anon { foo => "bar" };
is($o->foo, "bar", "object method returns correct string");
dies_ok { $o->baz } "nonexistent method dies";

done_testing;
