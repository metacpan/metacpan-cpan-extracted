#!perl -w

use strict;
use Test::More;

BEGIN { use_ok 'Foo' }

ok eval{ Foo::foo_is_ok() }, 'foo_is_ok()' or diag $@;

is eval{ Foo::bar_is_ok(10, 20, 12) }, 42, 'bar_is_ok()' or diag $@;


done_testing;
