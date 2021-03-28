#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib ".";
require "examples/parse-bencode.pl";

my $parser = BencodeParser->new;

sub test
{
   my ( $str, $expect, $name ) = @_;

   is_deeply( $parser->from_string( $str ), $expect, $name );
}

test q[i10e],
     10,
     "Integer";

test q[5:hello],
     "hello",
     "String";

test q[li1ei2ei3ee],
     [ 1, 2, 3 ],
     "List";

test q[d3:onei1e3:twoi2ee],
     { one => 1, two => 2 },
     "Dict";

done_testing;
