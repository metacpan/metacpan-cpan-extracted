#!perl

use strict;
use warnings;

use Test::More;

plan tests => 43;

use_ok( 'SQL::ReservedWords::SQLServer' );

my @methods = qw[
    is_reserved
    is_reserved_by_sqlserver7
    is_reserved_by_sqlserver2000
    is_reserved_by_sqlserver2005
    reserved_by
    words
];

can_ok( 'SQL::ReservedWords::SQLServer', @methods );

foreach my $method ( @methods ) {
    ok ! __PACKAGE__->can($method), "$method was not exported by default";
}

ok   my @words = SQL::ReservedWords::SQLServer->words,                             'Got words';
cmp_ok @words, '==', 202,                                                          'Got 202 words';
ok   SQL::ReservedWords::SQLServer->is_reserved('authorization'),                  'AUTHORIZATION is reserved';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver7('authorization'),    'AUTHORIZATION is reserved by SQL Server 7';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2000('authorization'), 'AUTHORIZATION is reserved by SQL Server 2000';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2005('authorization'), 'AUTHORIZATION is reserved by SQL Server 2005';
ok   SQL::ReservedWords::SQLServer->is_reserved('temporary'),                      'TEMPORARY is reserved';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver7('temporary'),        'TEMPORARY is reserved by SQL Server 7';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2000('temporary'),     'TEMPORARY is not reserved by SQL Server 2000';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2005('temporary'),     'TEMPORARY is not reserved by SQL Server 2005';
ok   SQL::ReservedWords::SQLServer->is_reserved('collate'),                        'COLLATE is reserved';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver7('collate'),          'COLLATE is not reserved by SQL Server 7';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2000('collate'),       'COLLATE is reserved by SQL Server 2000';
ok   SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2005('collate'),       'COLLATE is reserved by SQL Server 2005';
ok ! SQL::ReservedWords::SQLServer->is_reserved('bogus'),                          'BOGUS is not reserved';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver7('bogus'),            'BOGUS is not reserved';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2000('bogus'),         'BOGUS is not reserved';
ok ! SQL::ReservedWords::SQLServer->is_reserved_by_sqlserver2005('bogus'),         'BOGUS is not reserved';
ok ! SQL::ReservedWords::SQLServer->is_reserved(undef),                            'undef is not reserved';

is_deeply [ SQL::ReservedWords::SQLServer->reserved_by('authorization') ],
          [ 'SQL Server 7', 'SQL Server 2000', 'SQL Server 2005'        ],
          'Got right reserved by for AUTHORIZATION';

is_deeply [ SQL::ReservedWords::SQLServer->reserved_by('temporary')     ],
          [ 'SQL Server 7'                                              ],
          'Got right reserved by for TEMPORARY';

is_deeply [ SQL::ReservedWords::SQLServer->reserved_by('collate')       ],
          [ 'SQL Server 2000', 'SQL Server 2005'                        ],
          'Got right reserved by for COLLATE';


is_deeply [ SQL::ReservedWords::SQLServer->reserved_by('bogus')         ],
          [                                                             ],
          'Got right reserved by for BOGUS';


use_ok 'SQL::ReservedWords::SQLServer', @methods;

foreach my $method ( @methods ) {
    cmp_ok __PACKAGE__->can($method), '==', SQL::ReservedWords::SQLServer->can($method), "$method was exported";
}

ok   @words = words(),                                               'Got words';
ok   is_reserved('authorization'),                                   'AUTHORIZATION is reserved';
ok   is_reserved_by_sqlserver7('authorization'),                     'AUTHORIZATION is reserved by SQL Server 7';
ok   is_reserved_by_sqlserver2000('authorization'),                  'AUTHORIZATION is reserved by SQL Server 2000';
ok   is_reserved_by_sqlserver2005('authorization'),                  'AUTHORIZATION is reserved by SQL Server 2005';
