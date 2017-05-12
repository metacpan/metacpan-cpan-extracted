# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 16 };
use SQL::SqlObject;
ok(1); # If we made it this far, we're ok.

#########################
my $dbh = new SQL::SqlObject;                                ok(2);
my $name = $dbh->db_name; $dbh->db_name = $name;             ok(3);
my $dsn = $dbh->db_dsn; $dbh->db_dsn = $dsn;                 ok(4);
my $usr = $dbh->db_user; $dbh->db_user = $usr;               ok(5);
my $passwd = $dbh->db_password; $dbh->db_password = $passwd; ok(6);
$dbh = new SQL::SqlObject($name, $usr, $passwd);             ok(7);
ok($name, $dbh->db_name);                                    #  8
ok($usr, $dbh->db_user);                                     #  9
ok($passwd, $dbh->db_password);                              #  10
ok(not $dbh->is_connected);                                  #  11
$dbh = $dbh->new();                                          ok(12);
ok($name, $dbh->db_name);                                    #  13
ok($usr, $dbh->db_user);                                     #  14
ok($passwd, $dbh->db_password);                              #  15
ok(not $dbh->is_connected);                                  #  16
