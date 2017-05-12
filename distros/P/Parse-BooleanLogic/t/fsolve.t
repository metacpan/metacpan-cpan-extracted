
use strict;
use warnings;

use Test::More tests => 41;

use_ok 'Parse::BooleanLogic';

my $p = new Parse::BooleanLogic;

my $cb = sub { return $_[0]->{'v'} };

is $p->fsolve( [{ v => 1 }], $cb ),     1,     "true";
is $p->fsolve( [{ v => 0 }], $cb ),     0,     "false";
is $p->fsolve( [{ v => undef }], $cb ), undef, "undef";

is $p->fsolve( [{v => 0}, 'AND', {v => 0}], $cb ), 0, "0 AND 0";
is $p->fsolve( [{v => 0}, 'AND', {v => 1}], $cb ), 0, "0 AND 1";
is $p->fsolve( [{v => 1}, 'AND', {v => 0}], $cb ), 0, "1 AND 0";
is $p->fsolve( [{v => 1}, 'AND', {v => 1}], $cb ), 1, "1 AND 1";

is $p->fsolve( [{v => 0}, 'AND', {v => undef}], $cb ), 0, "0 AND X";
is $p->fsolve( [{v => 1}, 'AND', {v => undef}], $cb ), 1, "1 AND X";
is $p->fsolve( [{v => undef}, 'AND', {v => 0}], $cb ), 0, "X AND 0";
is $p->fsolve( [{v => undef}, 'AND', {v => 1}], $cb ), 1, "X AND 1";
is $p->fsolve( [{v => undef}, 'AND', {v => undef}], $cb ), undef, "X AND X";

is $p->fsolve( [{v => 0}, 'OR', {v => 0}], $cb ), 0, "0 OR 0";
is $p->fsolve( [{v => 0}, 'OR', {v => 1}], $cb ), 1, "0 OR 1";
is $p->fsolve( [{v => 1}, 'OR', {v => 0}], $cb ), 1, "1 OR 0";
is $p->fsolve( [{v => 1}, 'OR', {v => 1}], $cb ), 1, "1 OR 1";

is $p->fsolve( [{v => 0}, 'OR', {v => undef}], $cb ), 0, "0 OR X";
is $p->fsolve( [{v => 1}, 'OR', {v => undef}], $cb ), 1, "1 OR X";
is $p->fsolve( [{v => undef}, 'OR', {v => 0}], $cb ), 0, "X OR 0";
is $p->fsolve( [{v => undef}, 'OR', {v => 1}], $cb ), 1, "X OR 1";

is $p->fsolve( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), 0, "0 AND 0 OR 0";
is $p->fsolve( [{v => 0}, 'AND', {v => 0}, 'OR', {v => 1}], $cb ), 1, "0 AND 0 OR 1";
is $p->fsolve( [{v => 0}, 'AND', {v => 1}, 'OR', {v => 0}], $cb ), 0, "0 AND 1 OR 0";
is $p->fsolve( [{v => 0}, 'AND', {v => 1}, 'OR', {v => 1}], $cb ), 1, "0 AND 1 OR 1";
is $p->fsolve( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), 0, "1 AND 0 OR 0";
is $p->fsolve( [{v => 1}, 'AND', {v => 0}, 'OR', {v => 1}], $cb ), 1, "1 AND 0 OR 1";
is $p->fsolve( [{v => 1}, 'AND', {v => 1}, 'OR', {v => 0}], $cb ), 1, "1 AND 1 OR 0";
is $p->fsolve( [{v => 1}, 'AND', {v => 1}, 'OR', {v => 1}], $cb ), 1, "1 AND 1 OR 1";

is $p->fsolve( [{v => 0}, 'AND', {v => 0}, 'OR', {v => undef}], $cb ), 0, "0 AND 0 OR X";
is $p->fsolve( [{v => 0}, 'AND', {v => 1}, 'OR', {v => undef}], $cb ), 0, "0 AND 1 OR X";
is $p->fsolve( [{v => 1}, 'AND', {v => 0}, 'OR', {v => undef}], $cb ), 0, "1 AND 0 OR X";
is $p->fsolve( [{v => 1}, 'AND', {v => 1}, 'OR', {v => undef}], $cb ), 1, "1 AND 1 OR X";

is $p->fsolve( [{v => 0}, 'AND', {v => undef}, 'OR', {v => 0}], $cb ), 0, "0 AND X OR 0";
is $p->fsolve( [{v => 0}, 'AND', {v => undef}, 'OR', {v => 1}], $cb ), 1, "0 AND X OR 1";
is $p->fsolve( [{v => 1}, 'AND', {v => undef}, 'OR', {v => 0}], $cb ), 1, "1 AND X OR 0";
is $p->fsolve( [{v => 1}, 'AND', {v => undef}, 'OR', {v => 1}], $cb ), 1, "1 AND X OR 1";

is $p->fsolve( [{v => undef}, 'AND', {v => 0}, 'OR', {v => 0}], $cb ), 0, "X AND 0 OR 0";
is $p->fsolve( [{v => undef}, 'AND', {v => 0}, 'OR', {v => 1}], $cb ), 1, "X AND 0 OR 1";
is $p->fsolve( [{v => undef}, 'AND', {v => 1}, 'OR', {v => 0}], $cb ), 1, "X AND 1 OR 0";
is $p->fsolve( [{v => undef}, 'AND', {v => 1}, 'OR', {v => 1}], $cb ), 1, "X AND 1 OR 1";
