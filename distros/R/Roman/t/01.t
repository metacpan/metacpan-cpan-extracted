#!perl -T

use 5.006;
use strict;
use warnings;
our %test;
BEGIN{
%test=(
 'I'=>1,
 'II'=>2,
 'III'=>3,
 qw/V 5 X 10 L 50 C 100 D 500 M 1000 MCDXLIV 1444 MMVII 2007/
);
}
use Test::More tests => (scalar(keys %test)*3);
use Roman;

while (my ($rom,$arab)=each %test) {
 ok(isroman($rom),"$rom is roman");
 is(arabic($rom),$arab,"$rom is $arab");
 is(Roman($arab),$rom,"$arab is $rom");
}
