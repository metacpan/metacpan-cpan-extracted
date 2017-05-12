# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 3 };
use SQL::SqlObject::ODBC;
ok(1); # If we made it this far, we're ok.

#########################
my $dbh = new SQL::SqlObject::ODBC;                         
ok(2);
ok($dbh->db_dsn, 'dbi:ODBC');


