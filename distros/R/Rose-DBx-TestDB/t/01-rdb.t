use Test::More tests => 8;

use_ok('Rose::DBx::TestDB');

ok( my $db = Rose::DBx::TestDB->new, "new RDB object" );

diag( $db->database );

# create a table, insert some data and search it

ok( my $dbh = $db->retain_dbh, "retain_dbh" );

ok( $dbh->do(
        "create table foo ( id integer primary key autoincrement, name varchar(16) );"
    ),
    "create table"
);

ok( $dbh->do("insert into foo (name) values ('bar');"), "insert bar row" );

ok( my $sth = $dbh->prepare("SELECT name FROM foo WHERE id = ?"),
    "create sth" );

ok( $sth->execute(1), "execute sth" );

is( $sth->fetchall_arrayref->[0]->[0], 'bar', "fetch bar row" );

