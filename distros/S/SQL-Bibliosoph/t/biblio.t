# test of Exporter with DBIx::Interpolate and FILTER.
use strict;
use lib qw(t/lib lib ../lib);
use DBD::Mock;
use Test::More;

my $str = <<"END";
--[ USERS1 ]
SELECT * FROM users

--[ USERS2 ]
SELECT * FROM users WHERE id = ?

--[ USERS3 ]
SELECT * FROM users WHERE id = #1? AND name = 2?

--[ USERS3 ]
SELECT * FROM users WHERE id = #1? AND name = 2?

--[ BROKEN ]
SELECT * BROKEN users WHERE id = #1? AND name = 2?




END

my $dbh = DBI->connect('DBI:Mock:', '', '')
    or die "Cannot create handle: $DBI::errstr\n";


require_ok('SQL::Bibliosoph');

my $bb = new SQL::Bibliosoph( {dbh => $dbh, catalog_str => $str, 
        } );

isa_ok($bb,'SQL::Bibliosoph');


my $q = $bb->USERS1();
is(ref($q),'ARRAY','Simple query 1');

$q = $bb->USERS2();
is(ref($q),'ARRAY','Simple query 2');


$q = $bb->USERS3();
is(ref($q),'ARRAY','Simple query 3');

$q = $bb->rowh_USERS3();
is(ref($q),'HASH','Simple query 3');

$q = $bb->USERS3_sth();
is(ref($q), 'DBI::st', 'Simple query 3 STH');



done_testing();
