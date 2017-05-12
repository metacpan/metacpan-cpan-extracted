use strict;
use warnings;
use Test::More tests => 6;
use_ok('Sort::SQL');

is_deeply(
    Sort::SQL->string2array('foo'),
    [ { foo => 'ASC' } ],
    "foo, ASC default"
);

is_deeply(
    Sort::SQL->string2array('foo desc'),
    [ { foo => 'DESC' } ],
    "direction is UPPERCASED"
);

is_deeply(
    Sort::SQL->string2array('foo ASC bar DESC'),
    [ { foo => 'ASC' }, { bar => 'DESC' } ],
    "comma optional"
);

is_deeply(
    Sort::SQL->string2array('foo ASC foo DESC'),
    [ { foo => 'ASC' }, { foo => 'DESC' } ],
    "column name twice"
);

is_deeply(
    Sort::SQL->string2array('foo ASC,   bar DESC'),
    [ { foo => 'ASC' }, { bar => 'DESC' } ],
    "with commas"
);
