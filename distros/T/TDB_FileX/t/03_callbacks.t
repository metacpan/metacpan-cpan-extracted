#! /usr/bin/perl -w

#
# test persistant storage and error returns
#

use Test;
use Fcntl;

BEGIN { plan tests => 9 };

use TDB_FileX ":all";

unlink("test.tdb");
my $tdb = TDB_FileX->open("test.tdb", tdb_flags => DEFAULT, open_flags => O_RDWR, mode => 0664);
ok(!$tdb);

$tdb = TDB_FileX->open("test.tdb", tdb_flags => CLEAR_IF_FIRST);
ok($tdb);

ok (!eval { $tdb->store (foo => 'bar', MODIFY), 1 });
ok($! == TDB_FileX::ERR_NOEXIST);
ok($tdb->error, ERR_NOEXIST);
ok($tdb->errorstr, 'Record does not exist');

ok (eval { $tdb->store (foo => 'bar', INSERT); 1 });

undef $tdb;

ok($tdb = TDB_FileX->open("test.tdb"));

ok($tdb->fetch('foo'), 'bar');
