# Test of SQL::Interpolate with source filtering enabled.

use strict;
use DBIx::Interpolate;
use SQL::Interpolate FILTER => 1, qw(:all);
use Data::Dumper;

my @colors = ('blue', 'green');
my $rcolors = \@colors;
my $x = 3;
my($start, $count) = (3, 5);
my $sqlo = sql[
    SELECT * FROM table
    WHERE color IN @colors
          OR color IN ['green', 'red', @colors]
          AND color IN $rcolors
             AND d = $x
    LIMIT(start => $start, count => $count*2)
];
print Dumper( $sqlo );
print Dumper( sql_interp $sqlo );


unlink('test.sqlt');
my $dbx = DBIx::Interpolate->connect(
    "dbi:SQLite:dbname=test.sqlt", "", "",
    {RaiseError => 1, AutoCommit => 1}
);
$dbx->do( sql[CREATE TABLE mytable(one INTEGER PRIMARY KEY, two INTEGER)] );
#die Dumper(sql[INSERT INTO mytable one => $n, two => $n+1]);
for(my $n=0; $n<5; $n++) {
   $dbx->do( sql[INSERT INTO mytable {one => $n, two => $n+1} ] );
}
for(my $n=6; $n<10; $n++) {
    my $r = {one => $n, two => $n+1};
   $dbx->do( sql[INSERT INTO mytable $r ] );
}

my $rows = $dbx->selectall_arrayref(sql[
    SELECT * FROM mytable WHERE one > 3
]);
print Dumper($rows);

