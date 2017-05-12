use strict;
use Test;
BEGIN { plan tests => 9 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");

ok($db);
ok($db->connect);

if (!$db->exec("XXXXXXXXx")) {
   ok(1);
}

ok($db->exec('create table testerror (a, b)'));
ok($db->exec('insert into testerror values (1, 2)'));
ok($db->exec('insert into testerror values (3, 4)'));

ok($db->exec('create unique index testerror_idx on testerror (a)'));

if (!$db->exec('insert into testerror values (1, 5)')) {
   ok(1);
}

ok($db->disconnect);
