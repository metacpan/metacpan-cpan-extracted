#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib ".";
require "examples/parse-pod.pl";

my $parser = PodParser->new;

sub test
{
   my ( $str, $expect, $name ) = @_;

   is_deeply( $parser->from_string( $str ), $expect, $name );
}

test "Plain text",
     [ "Plain text" ],
     "plain";

test "B<bold>",
     [ { B => [ "bold" ] } ],
     "B<>";

test "Text with I<italic> text",
     [ "Text with ", { I => [ "italic" ] }, " text" ],
     "I<> surrounded";

test "Nested B<I<tags>>",
     [ "Nested ", { B => [ { I => [ "tags" ] } ] } ],
     "Nested";

test "Double C<< Class->method >> tags",
     [ "Double ", { C => [ " Class->method " ] }, " tags" ],
     "Double tags";

done_testing;
