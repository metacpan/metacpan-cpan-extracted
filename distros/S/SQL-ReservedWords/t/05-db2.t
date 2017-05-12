#!perl

use strict;
use warnings;

use Test::More;

plan tests => 58;

use_ok( 'SQL::ReservedWords::DB2' );

my @methods = qw[
    is_reserved
    is_reserved_by_db2v5
    is_reserved_by_db2v6
    is_reserved_by_db2v7
    is_reserved_by_db2v8
    is_reserved_by_db2v9
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::DB2', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::DB2->words,                     'Got words';
cmp_ok @words, '==', 397,                                            'Got 397 words';
ok   SQL::ReservedWords::DB2->is_reserved('user'),                   'USER is reserved';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v5('user'),          'USER is reserved by DB2 5';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v6('user'),          'USER is reserved by DB2 6';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v7('user'),          'USER is reserved by DB2 7';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v8('user'),          'USER is reserved by DB2 8';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v9('user'),          'USER is reserved by DB2 9';
ok   SQL::ReservedWords::DB2->is_reserved('jar'),                    'JAR is reserved';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v5('jar'),           'JAR is not reserved DB2 5';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v6('jar'),           'JAR is not reserved DB2 6';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v7('jar'),           'JAR is reserved by DB2 7';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v8('jar'),           'JAR is reserved by DB2 8';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v9('jar'),           'JAR is reserved by DB2 9';
ok   SQL::ReservedWords::DB2->is_reserved('count'),                  'COUNT is reserved';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v5('count'),         'COUNT is reserved by DB2 5';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v6('count'),         'COUNT is not reserved by DB2 6';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v7('count'),         'COUNT is not reserved by DB2 7';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v8('count'),         'COUNT is not reserved by DB2 8';
ok   SQL::ReservedWords::DB2->is_reserved_by_db2v9('count'),         'COUNT is reserved by DB2 9';
ok ! SQL::ReservedWords::DB2->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v5('bogus'),         'BOGUS is not reserved by DB2 5';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v6('bogus'),         'BOGUS is not reserved by DB2 6';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v7('bogus'),         'BOGUS is not reserved by DB2 7';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v8('bogus'),         'BOGUS is not reserved by DB2 8';
ok ! SQL::ReservedWords::DB2->is_reserved_by_db2v9('bogus'),         'BOGUS is not reserved by DB2 9';
ok ! SQL::ReservedWords::DB2->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords::DB2->reserved_by('user')   ],
          [ 'DB2 5', 'DB2 6', 'DB2 7', 'DB2 8', 'DB2 9'    ],
          'Got right reserved by for USER';

is_deeply [ SQL::ReservedWords::DB2->reserved_by('jar')    ],
          [ 'DB2 7', 'DB2 8', 'DB2 9'                      ],
          'Got right reserved by for ACCESSIBLE';

is_deeply [ SQL::ReservedWords::DB2->reserved_by('count')  ],
          [ 'DB2 5', 'DB2 9'                               ],
          'Got right reserved by for COUNT';

is_deeply [ SQL::ReservedWords::DB2->reserved_by('java')   ],
          [ 'DB2 6', 'DB2 7', 'DB2 9'                      ],
          'Got right reserved by for JAVA';

is_deeply [ SQL::ReservedWords::DB2->reserved_by('bogus')  ],
          [                                                ],
          'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords::DB2', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::DB2->can($method), "$method was exported";
}

ok   @words = words(),                                               'Got words';
ok   is_reserved('user'),                                            'USER is reserved';
ok   is_reserved_by_db2v5('user'),                                   'USER is reserved by DB2 5';
ok   is_reserved_by_db2v6('user'),                                   'USER is reserved by DB2 6';
ok   is_reserved_by_db2v7('user'),                                   'USER is reserved by DB2 7';
ok   is_reserved_by_db2v8('user'),                                   'USER is reserved by DB2 8';
ok   is_reserved_by_db2v9('user'),                                   'USER is reserved by DB2 9';
