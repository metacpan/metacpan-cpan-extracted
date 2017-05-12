#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype);

use Object::Anon;
my $o;

$o = anon { foo => { bar => "baz" } };
ok(blessed $o->foo, "method returns an object");
is(reftype $o->foo, "HASH", "... that is a hash");
is(scalar keys %{$o->foo}, 0, "... with no keys");

is($o->foo->bar, "baz", "deep method returns correct string");
dies_ok { $o->foo->quux } "nonexistent deep method dies";

done_testing;
