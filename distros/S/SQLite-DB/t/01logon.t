use Test;
BEGIN { plan tests => 3 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");
ok($db);
ok($db->connect);
ok($db->disconnect);