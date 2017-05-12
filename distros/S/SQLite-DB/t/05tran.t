use strict;
use Test;
BEGIN { plan tests => 28 }
use SQLite::DB;
my $db = SQLite::DB->new("foo");
my $sql;
my $result;

ok($db);
ok($db->connect);

ok($db->exec("CREATE TABLE MST (id, lbl)"));
ok($db->exec("CREATE TABLE TRN (no, id, qty)"));

ok($db->commit);
ok($db->rollback);

$db->transaction_mode;
ok($db->exec("INSERT INTO MST VALUES(1, 'ITEM1')"));
ok($db->exec("INSERT INTO MST VALUES(2, 'ITEM2')"));
ok($db->exec("INSERT INTO MST VALUES(3, 'ITEM3')"));
ok($db->exec("INSERT INTO TRN VALUES('A', 1, 5)"));
ok($db->exec("INSERT INTO TRN VALUES('B', 2, 2)"));
ok($db->exec("INSERT INTO TRN VALUES('C', 1, 4)"));
ok($db->rollback);

$db->transaction_mode;
ok($db->exec("INSERT INTO MST VALUES(1, 'ITEM1')"));
ok($db->exec("INSERT INTO MST VALUES(2, 'ITEM2')"));
ok($db->exec("INSERT INTO MST VALUES(3, 'ITEM3')"));
ok($db->exec("INSERT INTO TRN VALUES('A', 1, 5)"));
ok($db->exec("INSERT INTO TRN VALUES('B', 2, 2)"));
ok($db->exec("INSERT INTO TRN VALUES('C', 1, 4)"));
ok($db->exec("INSERT INTO TRN VALUES('D', 3, 3)"));
ok($db->commit);

$sql = "SELECT SUM(qty) as TOTAL
        FROM TRN ";

$result = $db->select_one_row($sql);

ok(($$result{TOTAL} == 14));

$sql = "SELECT TRN.id AS ID, SUM(qty) AS TOTAL 
        FROM TRN,MST
	WHERE TRN.ID = MST.ID
	GROUP BY TRN.ID 
	ORDER BY TRN.ID";

$result = $db->select_one_row($sql);

ok(($$result{TOTAL} == 9));

$sql = "SELECT TRN.id AS ID 
        FROM TRN";

$db->select($sql,\&rows_callback);

### FORCE ERRORS BLOCK ################################################

# Force an error in exec

ok(!$db->exec("INSERT INTO TABLE_NO_EXIST VALUES(1, 'ITEM1')"));

# Force an error in select

$db->select("SELECT * FROM TABLE_NO_EXIST",\&rows_callback);

# Force an error in transaction

ok($db->exec("CREATE TABLE TRAN_ERROR (id integer primary key)"));

$db->transaction_mode;

$db->exec("INSERT INTO TRAN_ERROR VALUES (1)");
$db->exec("INSERT INTO TRAN_ERROR VALUES (1)");
$db->exec("INSERT INTO TRAN_ERROR VALUES (1)");

ok(!$db->commit);

$sql = "SELECT SUM(id) as TOTAL FROM TRAN_ERROR ";

$result = $db->select_one_row($sql); 

ok(($$result{TOTAL} == 0)); # The table TRAN_ERROR cannot have any value


ok($db->disconnect);

### SUBFUNCTIONS ################################################

sub rows_callback {
    my $sth = (defined $_[0]) ? shift : return;
    my $rec = 0;
    while (my $d = $sth->fetchrow_hashref) {
	$rec++;
	print "> Record ".$rec."\n";
	for (keys %$d) {
	    print "  ".$_." : ".$d->{$_}."\n";
	}
    }   
}
