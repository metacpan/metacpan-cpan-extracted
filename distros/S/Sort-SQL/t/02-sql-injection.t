use strict;
use warnings;
use Test::More tests => 5;

#use Data::Dump qw( dump );

use_ok('Sort::SQL');

#use Data::Dump qw( dump );

my $nefarious_sql = "name, id; drop\rtable\rtest;\rselect\r1\r";

ok( my $parsed = Sort::SQL->string2array($nefarious_sql),
    "parse order string" );

#diag( dump($parsed) );

is_deeply( $parsed, [ { name => 'ASC' } ], "bad sql is stripped" );

my $more_bad_sql = "t1.name DESC, t2.id asc;drop\rtable\rtest;select\r1";

ok( my $parsed2 = Sort::SQL->string2array($more_bad_sql),
    "parse order string 2" );

#diag( dump($parsed2) );

is_deeply(
    $parsed2,
    [ { 't1.name' => 'DESC' }, { 't2.id' => 'ASC' } ],
    "more bad sql is stripped"
);
