#!perl

use strict;
use warnings;

use Test::More;

plan tests => 43;

use_ok( 'SQL::ReservedWords' );

my @methods = qw[
    is_reserved
    is_reserved_by_sql1992
    is_reserved_by_sql1999
    is_reserved_by_sql2003
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords->words,                     'Got words';
cmp_ok @words, '==', 337,                                       'Got 337 words';
ok   SQL::ReservedWords->is_reserved('user'),                   'USER is reserved';
ok   SQL::ReservedWords->is_reserved_by_sql1992('user'),        'USER is reserved by SQL:1992';
ok   SQL::ReservedWords->is_reserved_by_sql1999('user'),        'USER is reserved by SQL:1999';
ok   SQL::ReservedWords->is_reserved_by_sql2003('user'),        'USER is reserved by SQL:2003';
ok   SQL::ReservedWords->is_reserved('tablesample'),            'TABLESAMPLE is reserved';
ok ! SQL::ReservedWords->is_reserved_by_sql1992('tablesample'), 'TABLESAMPLE is not reserved by SQL:1992';
ok ! SQL::ReservedWords->is_reserved_by_sql1999('tablesample'), 'TABLESAMPLE is not reserved by SQL:1999';
ok   SQL::ReservedWords->is_reserved_by_sql2003('tablesample'), 'TABLESAMPLE is reserved by SQL:2003';
ok   SQL::ReservedWords->is_reserved('binary'),                 'BINARY is reserved';
ok ! SQL::ReservedWords->is_reserved_by_sql1992('binary'),      'BINARY is not reserved by SQL:1992';
ok   SQL::ReservedWords->is_reserved_by_sql1999('binary'),      'BINARY is reserved by SQL:1999';
ok   SQL::ReservedWords->is_reserved_by_sql2003('binary'),      'BINARY is reserved by SQL:2003';
ok ! SQL::ReservedWords->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords->is_reserved_by_sql1992('bogus'),       'BOGUS is not reserved by SQL:1992';
ok ! SQL::ReservedWords->is_reserved_by_sql1999('bougus'),      'BOGUS is not reserved by SQL:1999';
ok ! SQL::ReservedWords->is_reserved_by_sql2003('bogus'),       'BOGUS is not reserved by SQL:2003';
ok ! SQL::ReservedWords->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords->reserved_by('user')        ],
          [ 'SQL:1992', 'SQL:1999', 'SQL:2003'               ],   'Got right reserved by for USER';

is_deeply [ SQL::ReservedWords->reserved_by('tablesample') ],
          [ 'SQL:2003'                                     ],   'Got right reserved by for TABLESAMPLE';

is_deeply [ SQL::ReservedWords->reserved_by('binary')      ],
          [ 'SQL:1999', 'SQL:2003'                         ],   'Got right reserved by for BINARY';

is_deeply [ SQL::ReservedWords->reserved_by('bogus')       ],
          [                                                ],   'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords->can($method), "$method was exported";
}

ok   @words = words(),                                          'Got words';
ok   is_reserved('user'),                                       'USER is reserved';
ok   is_reserved_by_sql1992('user'),                            'USER is reserved by SQL:1992';
ok   is_reserved_by_sql1999('user'),                            'USER is reserved by SQL:1999';
ok   is_reserved_by_sql2003('user'),                            'USER is reserved by SQL:2003';
