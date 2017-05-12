#!perl

use strict;
use warnings;

use Test::More;

plan tests => 50;

use_ok( 'SQL::ReservedWords::Oracle' );

my @methods = qw[
    is_reserved
    is_reserved_by_oracle7
    is_reserved_by_oracle8
    is_reserved_by_oracle9
    is_reserved_by_oracle10
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::Oracle', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::Oracle->words,                     'Got words';
cmp_ok @words, '==', 110,                                               'Got 110 words';
ok   SQL::ReservedWords::Oracle->is_reserved('access'),                 'ACCESS is reserved';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle7('access'),      'ACCESS is reserved by Oracle 7';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle8('access'),      'ACCESS is reserved by Oracle 8i';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle9('access'),      'ACCESS is reserved by Oracle 9i';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle10('access'),     'ACCESS is reserved by Oracle 10g';
ok   SQL::ReservedWords::Oracle->is_reserved('mlslabel'),               'MLSLABEL is reserved';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle7('mlslabel'),    'MLSLABEL is not reserved Oracle 7';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle8('mlslabel'),    'MLSLABEL is reserved Oracle 8i';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle9('mlslabel'),    'MLSLABEL is reserved Oracle 9i';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle10('mlslabel'),   'MLSLABEL is reserved Oracle 10g';
ok   SQL::ReservedWords::Oracle->is_reserved('rowlabel'),               'ROWLABEL is reserved';
ok   SQL::ReservedWords::Oracle->is_reserved_by_oracle7('rowlabel'),    'ROWLABEL is reserved by Oracle 7';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle8('rowlabel'),    'ROWLABEL is not reserved by Oracle 8i';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle9('rowlabel'),    'ROWLABEL is not reserved by Oracle 9i';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle10('rowlabel'),   'ROWLABEL is not reserved by Oracle 10g';
ok ! SQL::ReservedWords::Oracle->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle7('bogus'),       'BOGUS is not reserved by Oracle 7';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle8('bougus'),      'BOGUS is not reserved by Oracle 8i';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle9('bogus'),       'BOGUS is not reserved by Oracle 9i';
ok ! SQL::ReservedWords::Oracle->is_reserved_by_oracle10('bogus'),      'BOGUS is not reserved by Oracle 10g';
ok ! SQL::ReservedWords::Oracle->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords::Oracle->reserved_by('access')               ],
          [ 'Oracle 7', 'Oracle 8i', 'Oracle 9i', 'Oracle 10g'              ],
          'Got right reserved by for ACCESS';

is_deeply [ SQL::ReservedWords::Oracle->reserved_by('mlslabel')             ],
          [ 'Oracle 8i', 'Oracle 9i', 'Oracle 10g'                          ],
          'Got right reserved by for MLSLABEL';

is_deeply [ SQL::ReservedWords::Oracle->reserved_by('rowlabel')             ],
          [ 'Oracle 7'                                                      ],
          'Got right reserved by for ROWLABEL';

is_deeply [ SQL::ReservedWords::Oracle->reserved_by('bogus')                ],
          [                                                                 ],
          'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords::Oracle', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::Oracle->can($method), "$method was exported";
}

ok   @words = words(),                                                  'Got words';
ok   is_reserved('access'),                                             'ACCESS is reserved';
ok   is_reserved_by_oracle7('access'),                                  'ACCESS is reserved by Oracle 7';
ok   is_reserved_by_oracle8('access'),                                  'ACCESS is reserved by Oracle 8i';
ok   is_reserved_by_oracle9('access'),                                  'ACCESS is reserved by Oracle 9i';
ok   is_reserved_by_oracle10('access'),                                 'ACCESS is reserved by Oracle 10g';
