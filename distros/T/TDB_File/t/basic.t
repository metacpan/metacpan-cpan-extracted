#! /usr/bin/perl -w

#
# test basic open/store/fetch (TDB_INTERNAL)
#

use Test;
use Fcntl;

BEGIN {plan tests => 4 };

use TDB_File;
ok(1); # test loading

my $tdb = TDB_File->open("dummy.tdb", TDB_INTERNAL, O_RDWR, 0664);

ok($tdb);

my $val = $tdb->fetch('foo');

ok(not defined $val);

$tdb->store(key1 => 'value1');
$tdb->store(key2 => 'value2', TDB_REPLACE);

ok($tdb->fetch('key1'), 'value1');
