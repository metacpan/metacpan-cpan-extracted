#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use File::Temp;
use Data::Dumper;
use RMI::Node;
use RMI;

if (eval "use DBI; return 1" == 1) {
    if (eval "use DBD::SQLite; return 1" == 1) {
        plan tests => 12;
    }
    else {
        plan skip_all => "no DBD::SQLite installed, skipping special DBI tests...";
    }
}
else {
    plan skip_all => "no DBI installed, skipping special DBI tests...";
}


my $dir = "/tmp/rmi-test-$$";

mkdir $dir unless -d $dir;
ok(($dir and -d $dir), "temp directory created: $dir");

my $dbfile = $dir . '/test.db';
unlink $dbfile if -e $dbfile;

use_ok("DBI") or die "cannot use DBI?";
my $dbh = DBI->connect("dbi:SQLite:$dbfile", { AutoCommit => 1, RaiseError => 1 });
ok($dbh, "connected in the main process to the db file $dbfile");
#print Dumper($dbh);

my $r;
$r = $dbh->do("create table foo (c1 int, c2 text)");
ok($r, "created a table") or diag($dbh->errstr);

$r = $dbh->do("insert into foo (c1,c2) values (100, 'one')");
ok($r, "inserted a row into the database table") or diag($dbh->errstr);
$r = $dbh->do("insert into foo (c1,c2) values (200, 'two')");
ok($r, "inserted a row into the database table") or diag($dbh->errstr);
$r = $dbh->do("insert into foo (c1,c2) values (300, 'three')");
ok($r, "inserted a row into the database table") or diag($dbh->errstr);

$dbh->disconnect;

sub check_data {
    my $dbh = shift;
    my $sth = $dbh->prepare("select * from foo order by c1");
    ok($sth, "got a sth") or diag($dbh->errstr);
    ok($sth->execute, "executed");
    my $a = $sth->fetchall_arrayref();
    ok($a, "got results arrayref back") or diag($sth->errstr);
    is_deeply($a,[[100,'one'],[200,'two'],[300,'three']], "data matches");
}

use_ok("RMI::Client::ForkedPipes");
my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client");
$c->call_use("DBI");

$dbh = $c->call_class_method("DBI","connect","dbi:SQLite:$dbfile", { AutoCommit => 1, RaiseError => 1});
ok($dbh, "got remote dbh");

# The presence of a hashref with a "Slice" key does some magic in DBI.  First the selectall_arrayref 
# goes to a C implementation, then reads the hash, and when it finds a Slice key falls back to Perl.
# Problems occur on the C end when the hashref is remoted, and its not totally clear how/why.

# This was a perfect candidate for testing "forced copying".  The RMI::Proxy::DBI::db implementation
# indicates that selectall_arrayref should have its parameters copied instead of proxied.  This gets
# around the DBI issue, and also improves performance, while being safe since the hashref isn't mutated.
my $a = $dbh->selectall_arrayref("select * from foo order by c1", { Slice => {} });
ok($a, "got results arrayref back") or diag($dbh->errstr);

is_deeply($a,[{c1 => 100, c2 => 'one'},{c1 => 200, c2 => 'two'},{ c1 => 300, c2 =>'three'}], "data matches");
note(Dumper($a));

