#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

my $m;
use ok $m = 'Term::VT102::Boundless';

can_ok($m, "new");
isa_ok(my $o = $m->new, $m);
isa_ok($o, "Term::VT102");

is( $o->cols, 1, "1 col");
is( $o->rows, 1, "1 row");

$o->process("foo");

is( $o->cols, 3, "3 cols");
is( $o->rows, 1, "1 row");

$o->process("\r\nmoose");

is( $o->cols, 5, "5 cols");
is( $o->rows, 2, "2 rows");


for (1 .. 2) {
	is( length( $o->row_text($_) ), 5, "row_text($_) length is 5");
	is( length( $o->row_attr($_) ), 10, "row_attr($_) length is 10");
}
