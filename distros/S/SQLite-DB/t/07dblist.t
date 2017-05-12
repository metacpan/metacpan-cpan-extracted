use strict;
use Test;
BEGIN { plan tests => 13 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");
my $resultset;

ok($db);
ok($db->connect);

ok($db->exec("CREATE TABLE dblist (id, lbl)"));

ok($db->exec("INSERT INTO dblist VALUES(1, 'ITEM1')"));
ok($db->exec("INSERT INTO dblist VALUES(2, 'ITEM2')"));
ok($db->exec("INSERT INTO dblist VALUES(3, 'ITEM3')"));

$resultset = $db->get_dblist("select * from dblist","lbl","id");

if (ref $resultset) {
   for (my $i=1; $i<4; $i++) {    
     ok($resultset->[$i-1]->{id},$i);
     ok($resultset->[$i-1]->{value},"ITEM".$i);
   }
}

ok($db->disconnect);

