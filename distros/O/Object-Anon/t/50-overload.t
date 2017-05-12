#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

use Object::Anon;
my $o;

$o = anon { '""' => sub { "foo" } };
is("$o", "foo", "stringification returns correct string");

done_testing;
