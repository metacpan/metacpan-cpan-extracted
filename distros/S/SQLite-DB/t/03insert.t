use strict;
use Test;
BEGIN { plan tests => 9 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");
ok($db);
ok($db->connect);
ok($db->exec("INSERT INTO f VALUES (?, ?, ?)","Luck","Skywalker","luck\@jedi.com"));
ok($db->exec("INSERT INTO f VALUES (?, ?, ?)","test", "test", "1"));
ok($db->exec("INSERT INTO f VALUES (?, ?, ?)","test", "test", "2"));
ok($db->exec("INSERT INTO f VALUES (?, ?, ?)","test", "test", "3"));
ok($db->exec("DELETE FROM F WHERE f1=?",'test'));
ok(($db->get_affected_rows==3));
ok($db->disconnect);