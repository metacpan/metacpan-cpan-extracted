#!/usr/bin/perl -w
use Test::More tests => 8;

use Term::VT102::ZeroBased;
my $term = Term::VT102::ZeroBased->new(rows => 24, cols => 80);
$term->process("\e[5;10H\e[1;31mhello world");

is($term->x, 20, "x-coordinate from ->x");
is($term->y, 4, "y-coordinate from ->y");

my @status = $term->status;
is($status[0], 20, "x-coordinate from ->status");
is($status[1], 4, "y-coordinate from ->status");

like($term->row_plaintext(4), qr/^ {9}hello world +$/, "row_plaintext");
like($term->row_text(4), qr/^\000{9}hello world/, "row_text");
isnt($term->row_attr(4), $term->row_attr(10), "row_attr(printed-on row) doesn't equal row_attr(nonprinted-on row)");
is($term->row_plaintext(4, 9, 12), 'hell', "make sure start/end cols work");

