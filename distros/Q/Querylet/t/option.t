use Test::More tests => 2;
use strict;
use warnings;

use Querylet;

set option foo: 1

set option bar: one

no output

no Querylet;

is($q->scratchpad->{foo},     1, "foo option set");
is($q->scratchpad->{bar}, 'one', "bar option set");
