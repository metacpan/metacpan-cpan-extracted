#! /usr/bin/perl -w

#
# test persistant storage and error returns
#

use Test;
use Fcntl;

BEGIN { plan tests => 8 };

use TDB_File;

unlink("test.tdb");
my $tdb = TDB_File->open("test.tdb", TDB_DEFAULT, O_RDWR, 0664);
ok(!$tdb);

$tdb = TDB_File->open("test.tdb", TDB_CLEAR_IF_FIRST);
ok($tdb);

my $ret = $tdb->store(foo => 'bar', TDB_MODIFY);
ok(!$ret);
ok($tdb->error, TDB_ERR_NOEXIST);
ok($tdb->errorstr, 'Record does not exist');

$ret = $tdb->store(foo => 'bar', TDB_INSERT);
ok($ret);

undef $tdb;

ok($tdb = TDB_File->open("test.tdb"));

ok($tdb->fetch('foo'), 'bar');
