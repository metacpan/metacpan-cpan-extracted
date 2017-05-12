
use strict;
use warnings;

use Test::More tests => 20;

use_ok 'Parse::BooleanLogic';

my $p = new Parse::BooleanLogic;

my $cb = sub { return exists $_[0]->{'x'}? $_[0]->{'x'} : undef };

is_deeply $p->partial_solve( [{ x => 1 }], $cb ),        1,     "true";
is_deeply $p->partial_solve( [{ x => 0 }], $cb ),        0,     "false";
is_deeply $p->partial_solve( [{ v => 1 }], $cb ), [{v => 1}],   "partial";

is_deeply $p->partial_solve( [{x => 0}, 'AND', {v => 0}], $cb ),        0,   "0 AND x";
is_deeply $p->partial_solve( [{x => 0}, 'AND', {v => 1}], $cb ),        0,   "0 AND x";
is_deeply $p->partial_solve( [{x => 1}, 'AND', {v => 0}], $cb ), [{v => 0}], "1 AND x";
is_deeply $p->partial_solve( [{x => 1}, 'AND', {v => 1}], $cb ), [{v => 1}], "1 AND x";

is_deeply $p->partial_solve( [{v => 0}, 'AND', {x => 0}], $cb ),        0,   "x AND 0";
is_deeply $p->partial_solve( [{v => 0}, 'AND', {x => 1}], $cb ), [{v => 0}], "x AND 1";
is_deeply $p->partial_solve( [{v => 1}, 'AND', {x => 0}], $cb ),        0,   "x AND 0";
is_deeply $p->partial_solve( [{v => 1}, 'AND', {x => 1}], $cb ), [{v => 1}], "x AND 1";

is_deeply $p->partial_solve( [{x => 1}, 'OR', {v => 0}], $cb ),        1,   "1 OR x";
is_deeply $p->partial_solve( [{x => 1}, 'OR', {v => 1}], $cb ),        1,   "1 OR x";
is_deeply $p->partial_solve( [{x => 0}, 'OR', {v => 0}], $cb ), [{v => 0}], "0 OR x";
is_deeply $p->partial_solve( [{x => 0}, 'OR', {v => 1}], $cb ), [{v => 1}], "0 OR x";

is_deeply $p->partial_solve( [{v => 0}, 'OR', {x => 1}], $cb ),        1,   "x OR 1";
is_deeply $p->partial_solve( [{v => 0}, 'OR', {x => 0}], $cb ), [{v => 0}], "x OR 0";
is_deeply $p->partial_solve( [{v => 1}, 'OR', {x => 1}], $cb ),        1,   "x OR 1";
is_deeply $p->partial_solve( [{v => 1}, 'OR', {x => 0}], $cb ), [{v => 1}], "x OR 0";

