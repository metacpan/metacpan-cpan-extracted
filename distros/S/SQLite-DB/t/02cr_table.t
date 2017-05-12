use strict;
use Test;
BEGIN { plan tests => 5 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");
ok($db);
ok($db->connect);
ok($db->exec("CREATE TABLE f (f1, f2, f3)"));
ok($db->select("SELECT f.f1, f.* FROM f",sub {}));
ok($db->disconnect);
