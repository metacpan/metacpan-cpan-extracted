#!perl

use strict;
use warnings;

use Test::More;

plan tests => 36;

use_ok( 'SQL::ReservedWords::SQLite' );

my @methods = qw[
    is_reserved
    is_reserved_by_sqlite2
    is_reserved_by_sqlite3
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::SQLite', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::SQLite->words,                     'Got words';
cmp_ok @words, '==', 65,                                                'Got 65 words';
ok   SQL::ReservedWords::SQLite->is_reserved('between'),                'BETWEEN is reserved';
ok   SQL::ReservedWords::SQLite->is_reserved_by_sqlite2('between'),     'BETWEEN is reserved by SQLite 2';
ok   SQL::ReservedWords::SQLite->is_reserved_by_sqlite3('between'),     'BETWEEN is reserved by SQLite 3';
ok   SQL::ReservedWords::SQLite->is_reserved('glob'),                   'GLOB is reserved';
ok   SQL::ReservedWords::SQLite->is_reserved_by_sqlite2('glob'),        'GLOB is reserved by SQLite 2';
ok ! SQL::ReservedWords::SQLite->is_reserved_by_sqlite3('glob'),        'GLOB is not reserved by SQLite 3';
ok   SQL::ReservedWords::SQLite->is_reserved('full'),                   'FULL is reserved';
ok ! SQL::ReservedWords::SQLite->is_reserved_by_sqlite2('full'),        'FULL is not reserved by SQLite 2';
ok   SQL::ReservedWords::SQLite->is_reserved_by_sqlite3('full'),        'FULL is reserved by SQLite 3';
ok ! SQL::ReservedWords::SQLite->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords::SQLite->is_reserved_by_sqlite2('bogus'),       'BOGUS is not reserved by SQLite 2';
ok ! SQL::ReservedWords::SQLite->is_reserved_by_sqlite3('bougus'),      'BOGUS is not reserved by SQLite 3';
ok ! SQL::ReservedWords::SQLite->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords::SQLite->reserved_by('between')          ],
          [ 'SQLite 2', 'SQLite 3'                                      ],
          'Got right reserved by for BETWEEN';

is_deeply [ SQL::ReservedWords::SQLite->reserved_by('glob')             ],
          [ 'SQLite 2'                                                  ],
          'Got right reserved by for GLOB';

is_deeply [ SQL::ReservedWords::SQLite->reserved_by('full')             ],
          [ 'SQLite 3'                                                  ],
          'Got right reserved by for FULL';

is_deeply [ SQL::ReservedWords::SQLite->reserved_by('bogus')            ],
          [                                                             ],
          'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords::SQLite', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::SQLite->can($method), "$method was exported";
}

ok   @words = words(),                                                  'Got words';
ok   is_reserved('between'),                                            'BETWEEN is reserved';
ok   is_reserved_by_sqlite2('between'),                                 'BETWEEN is reserved by SQLite 2';
ok   is_reserved_by_sqlite3('between'),                                 'BETWEEN is reserved by SQLite 3';
