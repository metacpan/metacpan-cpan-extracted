#!perl

use strict;
use warnings;

use Test::More;

plan tests => 36;

use_ok( 'SQL::ReservedWords::Sybase' );

my @methods = qw[
    is_reserved
    is_reserved_by_ase12
    is_reserved_by_ase15
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::Sybase', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::Sybase->words,                     'Got words';
cmp_ok @words, '==', 220,                                               'Got 220 words';
ok   SQL::ReservedWords::Sybase->is_reserved('between'),                'BETWEEN is reserved';
ok   SQL::ReservedWords::Sybase->is_reserved_by_ase12('between'),       'BETWEEN is reserved by Sybase ASE 12';
ok   SQL::ReservedWords::Sybase->is_reserved_by_ase15('between'),       'BETWEEN is reserved by Sybase ASE 15';
ok   SQL::ReservedWords::Sybase->is_reserved('func'),                   'FUNC is reserved';
ok   SQL::ReservedWords::Sybase->is_reserved_by_ase12('func'),          'FUNC is reserved by Sybase ASE 12';
ok ! SQL::ReservedWords::Sybase->is_reserved_by_ase15('func'),          'FUNC is not reserved by Sybase ASE 15';
ok   SQL::ReservedWords::Sybase->is_reserved('scroll'),                 'SCROLL is reserved';
ok ! SQL::ReservedWords::Sybase->is_reserved_by_ase12('scroll'),        'SCROLL is not reserved by Sybase ASE 12';
ok   SQL::ReservedWords::Sybase->is_reserved_by_ase15('scroll'),        'SCROLL is reserved by Sybase ASE 15';
ok ! SQL::ReservedWords::Sybase->is_reserved('bogus'),                  'BOGUS is not reserved';
ok ! SQL::ReservedWords::Sybase->is_reserved_by_ase12('bogus'),         'BOGUS is not reserved by Sybase ASE 12';
ok ! SQL::ReservedWords::Sybase->is_reserved_by_ase15('bougus'),        'BOGUS is not reserved by Sybase ASE 15';
ok ! SQL::ReservedWords::Sybase->is_reserved(undef),                    'undef is not reserved';

is_deeply [ SQL::ReservedWords::Sybase->reserved_by('between')          ],
          [ 'Sybase ASE 12', 'Sybase ASE 15'                            ],
          'Got right reserved by for BETWEEN';

is_deeply [ SQL::ReservedWords::Sybase->reserved_by('func')             ],
          [ 'Sybase ASE 12'                                             ],
          'Got right reserved by for FUNC';

is_deeply [ SQL::ReservedWords::Sybase->reserved_by('scroll')           ],
          [ 'Sybase ASE 15'                                             ],
          'Got right reserved by for SCROLL';

is_deeply [ SQL::ReservedWords::Sybase->reserved_by('bogus')            ],
          [                                                             ],
          'Got right reserved by for BOGUS';

use_ok 'SQL::ReservedWords::Sybase', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::Sybase->can($method), "$method was exported";
}

ok   @words = words(),                                                  'Got words';
ok   is_reserved('between'),                                            'BETWEEN is reserved';
ok   is_reserved_by_ase12('between'),                                   'BETWEEN is reserved by Sybase ASE 12';
ok   is_reserved_by_ase15('between'),                                   'BETWEEN is reserved by Sybase ASE 15';
