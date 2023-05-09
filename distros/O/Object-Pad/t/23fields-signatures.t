#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use Object::Pad;

# See also
#   https://rt.cpan.org/Ticket/Display.html?id=134456
class C {
   field $x = "initial";

   method m ( $x = $x ) { $x; }
}

package main;

my $obj = C->new;

is( $obj->m,          "initial", 'initial');
is( $obj->m( "new" ), "new",     'new value');

done_testing;
