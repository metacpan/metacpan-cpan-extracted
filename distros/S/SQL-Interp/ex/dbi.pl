# dbi.pl
# simple tests of DBIx::Interp.

use strict;
use Data::Dumper;
use DBIx::Interp qw(:all);
use DBI;

unlink('test.sqlt');
my $dbx = DBIx::Interp->connect(
    "dbi:SQLite:dbname=test.sqlt", "", "",
    {RaiseError => 1, AutoCommit => 1}
);

$dbx->do("CREATE TABLE mytable(one INTEGER PRIMARY KEY, two INTEGER)");
for(my $n=0; $n<10; $n++) {
   $dbx->do("INSERT INTO mytable", {one => $n, two => $n+1});
}

my $rows = $dbx->selectall_arrayref(qq[
    SELECT * FROM mytable WHERE one > ], \3
);
print Dumper($rows);

$rows = $dbx->selectall_hashref(qq[
    SELECT * FROM mytable WHERE one > ], \3, key_field("one")
);
print Dumper($rows);

# list context
my @rows = $dbx->selectrow_array(qq[
    SELECT * FROM mytable WHERE one = ], \3
);
print Dumper(\@rows);

# scalar context
$rows = $dbx->selectrow_array(qq[
    SELECT one FROM mytable WHERE one = ], \3
);
print Dumper($rows);
