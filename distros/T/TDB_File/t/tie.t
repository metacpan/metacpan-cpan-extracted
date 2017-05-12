#! /usr/bin/perl -w

#
# test tie interface
#

use Test;

BEGIN { plan tests => 9 };

use TDB_File;

{
  # prime test.tdb
  my $tdb = TDB_File->open("test.tdb", TDB_CLEAR_IF_FIRST);
  ok($tdb);

  ok($tdb->store(foo => 'bar', TDB_INSERT));
}

my %db;
ok(tie %db, 'TDB_File', 'test.tdb');

ok($db{foo}, 'bar');

ok(not exists $db{baz});

$db{baz} = 1234;
ok($db{baz}, 1234);

delete $db{baz};
ok(not exists $db{baz});

ok(scalar keys(%db), 1);

%db = ();
ok(not scalar %db);
