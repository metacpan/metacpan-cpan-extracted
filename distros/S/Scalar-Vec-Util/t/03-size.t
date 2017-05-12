#!perl -T

use strict;
use warnings;

use Test::More;

use Scalar::Vec::Util qw<SVU_SIZE SVU_PP>;

if (SVU_PP) {
 plan tests => 1;

 diag 'Using pure perl fallbacks';

 is SVU_SIZE, 1, 'SVU_SIZE is 1';
} else {
 plan tests => 2;

 diag 'Using an unit of ' . SVU_SIZE . ' bits';

 cmp_ok SVU_SIZE, '>=', 8, 'SVU_SIZE is greater than 8';
 is     SVU_SIZE % 8,   0, 'SVU_SIZE is a multiple of 8';
}
