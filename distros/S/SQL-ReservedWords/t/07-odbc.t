#!perl

use strict;
use warnings;

use Test::More;

plan tests => 22;

use_ok( 'SQL::ReservedWords::ODBC' );

my @methods = qw[
    is_reserved
    is_reserved_by_odbc3
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::ODBC', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::ODBC->words,               'Got words';
cmp_ok @words, '==', 235,                                       'Got 235 words';
ok   SQL::ReservedWords::ODBC->is_reserved('user'),             'USER is reserved';
ok   SQL::ReservedWords::ODBC->is_reserved_by_odbc3('user'),    'USER is reserved by ODBC 3.0';
ok ! SQL::ReservedWords::ODBC->is_reserved('bogus'),            'BOGUS is not reserved';
ok ! SQL::ReservedWords::ODBC->is_reserved(undef),              'undef is not reserved';

is_deeply [ SQL::ReservedWords::ODBC->reserved_by('user')               ],
          [ 'ODBC 3.0'                                                  ],
          'Got right reserved by for USER';

is_deeply [ SQL::ReservedWords::ODBC->reserved_by('bogus')              ],
          [                                                             ],
          'Got right reserved by for BOGUS';


use_ok 'SQL::ReservedWords::ODBC', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::ODBC->can($method), "$method was exported";
}

ok   @words = words(),                                          'Got words';
ok   is_reserved('user'),                                       'USER is reserved';
ok   is_reserved_by_odbc3('user'),                              'USER is reserved by ODBC 3.0';
