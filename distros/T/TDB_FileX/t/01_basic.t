#! /usr/bin/perl -w

#
# test basic open/store/fetch (TDB_INTERNAL)
#

use Test;
use Fcntl;

BEGIN {plan tests => 4 };

use TDB_FileX;
ok(1); # test loading

my $tdb = TDB_FileX->open ("dummy.tdb", tdb_flags => TDB_FileX::INTERNAL, open_flags => O_RDWR, mode => 0664);

ok($tdb);

my $val = $tdb->fetch('foo');

ok(not defined $val);

$tdb->store(key1 => 'value1');
$tdb->store(key2 => 'value2', TDB_FileX::REPLACE);

ok($tdb->fetch('key1'), 'value1');
