#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests=>6;
use Test::Exception;

use Sub::Curried;

curry add_n_to ($n, $val) {
    return $n + $val;
}
# look ma, no semicolon!

isa_ok (\&add_n_to, 'Sub::Curried');
my $add_10_to = add_n_to(10);
isa_ok ($add_10_to, 'Sub::Curried');
is( $add_10_to->(4), 14, "curried");
is( add_n_to(9,4),   13, "non-curried");
is( add_n_to(8)->(3),11, "chained curried call");

throws_ok {
    add_n_to(1,2,3);
    } qr/add_n_to, expected 2 args but got 3/;
