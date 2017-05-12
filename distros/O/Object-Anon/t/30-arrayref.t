#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype);

use Object::Anon;
my $o;

$o = anon { foo => [ { n => "one" }, { n => "two" }, { n => "three" } ] };
is(ref $o->foo, "ARRAY", "method returns an arryref");
ok(blessed $o->foo->[0], "... with an object in it");
is(reftype $o->foo->[0], "HASH", "... that is a hash");
is(scalar keys %{$o->foo->[0]}, 0, "... with no keys");

is($o->foo->[0]->n, "one", "deep method returns correct string");
is($o->foo->[1]->n, "two", "deep method returns correct string");
dies_ok { $o->foo->[0]->bar } "nonexistent deep method dies";

done_testing;
