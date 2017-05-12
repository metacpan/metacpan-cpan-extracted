#!perl

use strict;
use warnings;

use Test::More;

plan tests => 44;

use_ok( 'SQL::ReservedWords::MySQL' );

my @methods = qw[
    is_reserved
    is_reserved_by_mysql3
    is_reserved_by_mysql4
    is_reserved_by_mysql5
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::MySQL', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::MySQL->words,                     'Got words';
cmp_ok @words, '==', 234,                                              'Got 234 words';
ok   SQL::ReservedWords::MySQL->is_reserved('zerofill'),               'ZEROFILL is reserved';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql3('zerofill'),     'ZEROFILL is reserved by MySQL 3';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql4('zerofill'),     'ZEROFILL is reserved by MySQL 4';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql5('zerofill'),     'ZEROFILL is reserved by MySQL 5';
ok   SQL::ReservedWords::MySQL->is_reserved('accessible'),             'ACCESSIBLE is reserved';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql3('accessible'),   'ACCESSIBLE is not reserved MySQL 3';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql4('accessible'),   'ACCESSIBLE is not reserved MySQL 4';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql5('accessible'),   'ACCESSIBLE is reserved by MySQL 5';
ok   SQL::ReservedWords::MySQL->is_reserved('true'),                   'TRUE is reserved';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql3('true'),         'TRUE is not reserved by MySQL 3';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql4('true'),         'TRUE is reserved by MySQL 4';
ok   SQL::ReservedWords::MySQL->is_reserved_by_mysql5('true'),         'TRUE is reserved by MySQL 5';
ok ! SQL::ReservedWords::MySQL->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql3('bogus'),        'BOGUS is not reserved by MySQL 3';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql4('bougus'),       'BOGUS is not reserved by MySQL 4';
ok ! SQL::ReservedWords::MySQL->is_reserved_by_mysql5('bogus'),        'BOGUS is not reserved by MySQL 5';
ok ! SQL::ReservedWords::MySQL->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords::MySQL->reserved_by('zerofill')              ],
          [ 'MySQL 3.2', 'MySQL 4.0', 'MySQL 4.1', 'MySQL 5.0', 'MySQL 5.1' ],
          'Got right reserved by for ZEROFILL';

is_deeply [ SQL::ReservedWords::MySQL->reserved_by('accessible')            ],
          [ 'MySQL 5.1'                                                     ],
          'Got right reserved by for ACCESSIBLE';

is_deeply [ SQL::ReservedWords::MySQL->reserved_by('reads')                 ],
          [ 'MySQL 5.0', 'MySQL 5.1'                                        ],
          'Got right reserved by for READS';

is_deeply [ SQL::ReservedWords::MySQL->reserved_by('true')                  ],
          [ 'MySQL 4.1', 'MySQL 5.0', 'MySQL 5.1'                           ],
          'Got right reserved by for TRUE';

is_deeply [ SQL::ReservedWords::MySQL->reserved_by('bogus')                 ],
          [                                                                 ],
          'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords::MySQL', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::MySQL->can($method), "$method was exported";
}

ok   @words = words(),                                                 'Got words';
ok   is_reserved('zerofill'),                                          'ZEROFILL is reserved';
ok   is_reserved_by_mysql3('zerofill'),                                'ZEROFILL is reserved by MySQL 3';
ok   is_reserved_by_mysql4('zerofill'),                                'ZEROFILL is reserved by MySQL 4';
ok   is_reserved_by_mysql5('zerofill'),                                'ZEROFILL is reserved by MySQL 5';
