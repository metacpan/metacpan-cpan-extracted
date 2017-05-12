#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib ".";
require "examples/parse-dict.pl";

my $parser = DictParser->new;

sub test
{
   my ( $str, $expect, $name ) = @_;

   is_deeply( $parser->from_string( $str ), $expect, $name );
}

test q[123],
     123,
     "Number";

test q["Hello"],
     "Hello",
     "String";

test q[{one: 1, two: 2}],
     { one => 1, two => 2 },
     "Flat dict";

test q[{numbers: {three: 3, four: 4}}],
     { numbers => { three => 3, four => 4 } },
     "Nested dict";

done_testing;
