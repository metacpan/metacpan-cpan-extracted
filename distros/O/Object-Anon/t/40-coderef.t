#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Test::Exception;

use Object::Anon;
my $o;

$o = anon { foo => sub { "bar" } };
is($o->foo, "bar", "object method returns correct string");
dies_ok { $o->baz } "nonexistent method dies";

done_testing;
