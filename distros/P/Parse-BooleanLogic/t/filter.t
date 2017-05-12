
use strict;
use warnings;

use Test::More tests => 27;
use Test::Deep;

use_ok 'Parse::BooleanLogic';

my $p = new Parse::BooleanLogic;

my $cb = sub { return $_[0]->{'v'} };

cmp_deeply $p->filter( [{ v => 1 }], $cb ), [{v => 1}], "'1'";
cmp_deeply $p->filter( [{ v => 0 }], $cb ), [], "'0'";

cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 0}], $cb ), [], "0 AND 0";
cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 2}], $cb ), [{v => 2}], "0 AND 1";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 0}], $cb ), [{v => 1}], "1 AND 0";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 2}], $cb ), [{v => 1}, 'AND', {v => 2}], "1 AND 1";

cmp_deeply $p->filter( [{v => 0}, 'OR', {v => 0}], $cb ), [], "0 OR 0";
cmp_deeply $p->filter( [{v => 0}, 'OR', {v => 2}], $cb ), [{v => 2}], "0 OR 1";
cmp_deeply $p->filter( [{v => 1}, 'OR', {v => 0}], $cb ), [{v => 1}], "1 OR 0";
cmp_deeply $p->filter( [{v => 1}, 'OR', {v => 2}], $cb ), [{v => 1}, 'OR', {v => 2}], "1 OR 1";

cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), [], "0 AND 0 OR 0";
cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 3}], $cb ), [{v => 3}], "0 AND 0 OR 1";
cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 2}, 'OR', {v => 0}], $cb ), [{v => 2}], "0 AND 1 OR 0";
cmp_deeply $p->filter( [{v => 0}, 'AND', {v => 2}, 'OR', {v => 3}], $cb ), [{v => 2}, 'OR', {v => 3}], "0 AND 1 OR 1";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), [{v => 1}], "1 AND 0 OR 0";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 3}], $cb ), [{v => 1}, 'OR', {v => 3}], "1 AND 0 OR 1";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 2}, 'OR', {v => 0}], $cb ), [{v => 1}, 'AND', {v => 2}], "1 AND 1 OR 0";
cmp_deeply $p->filter( [{v => 1}, 'AND', {v => 2}, 'OR', {v => 3}], $cb ), [{v => 1}, 'AND', {v => 2}, 'OR', {v => 3}], "1 AND 1 OR 1";

cmp_deeply $p->filter( [{v => 0}, 'AND', [ {v => 0}, 'OR', {v => 0}]], $cb ), [], "0 AND (0 OR 0)";
cmp_deeply $p->filter( [{v => 0}, 'AND', [ {v => 0}, 'OR', {v => 3}]], $cb ), [{v => 3}], "0 AND (0 OR 1)";
cmp_deeply $p->filter( [{v => 0}, 'AND', [ {v => 2}, 'OR', {v => 0}]], $cb ), [{v => 2}], "0 AND (1 OR 0)";
cmp_deeply $p->filter( [{v => 0}, 'AND', [ {v => 2}, 'OR', {v => 3}]], $cb ), [{v => 2}, 'OR', {v => 3}], "0 AND (1 OR 1)";
cmp_deeply $p->filter( [{v => 1}, 'AND', [ {v => 0}, 'OR', {v => 0}]], $cb ), [{v => 1}], "1 AND (0 OR 0)";
cmp_deeply $p->filter( [{v => 1}, 'AND', [ {v => 0}, 'OR', {v => 3}]], $cb ), [{v => 1}, 'AND', {v => 3}], "1 AND (0 OR 1)";
cmp_deeply $p->filter( [{v => 1}, 'AND', [ {v => 2}, 'OR', {v => 0}]], $cb ), [{v => 1}, 'AND', {v => 2}], "1 AND (1 OR 0)";
cmp_deeply $p->filter( [{v => 1}, 'AND', [ {v => 2}, 'OR', {v => 3}]], $cb ), [{v => 1}, 'AND', [ {v => 2}, 'OR', {v => 3}]], "1 AND (1 OR 1)";
