#! perl -w

use strict;
use warnings;

use DBI;
use Test::More;
use Test::DB::Shared::mysqld;

ok( my $testdb = Test::DB::Shared::mysqld->new(
    test_namespace => 'mysqld_t'.int(rand(1000)),
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) );
ok( $testdb->dsn() , "Ok got dsn");

done_testing();
