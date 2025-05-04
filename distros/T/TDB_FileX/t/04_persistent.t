#! /usr/bin/perl -w

#
# test tie interface
#

use Test;

BEGIN { plan tests => 12 };

use TDB_FileX ":all";

{
  # prime test.tdb
  my $tdb = TDB_FileX->open ("test.tdb", tdb_flags => CLEAR_IF_FIRST);
  ok($tdb);

  ok(eval { $tdb->store (foo => 'bar', TDB_FileX::INSERT); 1});
  ok(eval { $tdb->append (foo => 'baz'); 1});
  ok(eval { $tdb->append (foo2 => 'barf'); 1});
}

my %db;
ok(tie %db, 'TDB_FileX', 'test.tdb');

ok($db{foo}, 'barbaz');
ok($db{foo2}, 'barf');

ok(not exists $db{baz});

$db{baz} = 1234;
ok($db{baz}, 1234);

delete $db{baz};
ok(not exists $db{baz});

ok(scalar keys(%db), 2);

%db = ();
ok(not scalar %db);
