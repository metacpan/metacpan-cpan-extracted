use strict;
use warnings;
use Test::More;
use SQL::Abstract::Classic;

my $obj = bless {}, "Foo::Bar";

is(SQL::Abstract::Classic->_refkind(undef), 'UNDEF', 'UNDEF');

is(SQL::Abstract::Classic->_refkind({}), 'HASHREF', 'HASHREF');
is(SQL::Abstract::Classic->_refkind([]), 'ARRAYREF', 'ARRAYREF');

is(SQL::Abstract::Classic->_refkind(\{}), 'HASHREFREF', 'HASHREFREF');
is(SQL::Abstract::Classic->_refkind(\[]), 'ARRAYREFREF', 'ARRAYREFREF');

is(SQL::Abstract::Classic->_refkind(\\{}), 'HASHREFREFREF', 'HASHREFREFREF');
is(SQL::Abstract::Classic->_refkind(\\[]), 'ARRAYREFREFREF', 'ARRAYREFREFREF');

is(SQL::Abstract::Classic->_refkind("foo"), 'SCALAR', 'SCALAR');
is(SQL::Abstract::Classic->_refkind(\"foo"), 'SCALARREF', 'SCALARREF');
is(SQL::Abstract::Classic->_refkind(\\"foo"), 'SCALARREFREF', 'SCALARREFREF');

# objects are treated like scalars
is(SQL::Abstract::Classic->_refkind($obj), 'SCALAR', 'SCALAR');
is(SQL::Abstract::Classic->_refkind(\$obj), 'SCALARREF', 'SCALARREF');
is(SQL::Abstract::Classic->_refkind(\\$obj), 'SCALARREFREF', 'SCALARREFREF');

done_testing;
