# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 9 };
use SQL::SqlObject::Pg;
ok(1); # If we made it this far, we're ok.

#########################
my $dbh = new SQL::SqlObject::Pg;                            ok(2);
ok($dbh->db_dsn,'dbi:Pg');                                   #  3
my $host = $dbh->db_host; $dbh->db_host = $host;             ok(4);
ok($host eq $dbh->db_host);                                  #  5
my $port = $dbh->db_port; $dbh->db_port = $port;             ok(6);
ok($port eq $dbh->db_port);                                  #  7
my $tty = $dbh->db_tty; $dbh->db_tty = $tty;                 ok(8);
ok($tty eq $dbh->db_tty);                                    #  9

