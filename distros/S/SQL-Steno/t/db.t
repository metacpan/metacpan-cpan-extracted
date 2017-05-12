use strict;
use warnings;

use SQL::Steno;

my $dbh;

BEGIN { eval q{ use DBI; $SQL::Steno::dbh = $dbh = DBI->connect( 'dbi:File:' ) }}

use Test::More;

plan skip_all => 'DBI, DBD::File or SQL::Statement not available'
    unless $dbh->{sql_statement_version};



plan tests => 4;

$dbh->do( "CREATE TEMP TABLE abcde AS IMPORT(?)", {},
	  [
	   [qw(a b c d e)],
	   [0..4],
	   [5..9],
	   [10..14],
	   [15..19]
	  ]
	 );


$dbh->do( "CREATE TEMP TABLE xyz AS IMPORT(?)", {},
	  [
	   [qw(x y z)],
	   [0..2],
	   [5..7],
	   [10..12]
	  ]
	 );

SQL::Steno::init;

sub test($$;$) {
    open my $fh, '>', \my $str;
    my $ofh = select $fh;
    eval { local $_ = $_[1]; SQL::Steno::convert; print "$_\n"; SQL::Steno::run $_ };
    close $fh;
    select $ofh;
    is $str, $_[2], $_[0];
}

test abcde => '#ab:2', <<\OUT;
select * from ABCDE limit 2
a|b|c|d|e|
-|-|-|-|-|
0|1|2|3|4|
5|6|7|8|9|
OUT

test xyz => '#x:ob x desc', <<\OUT;
select * from XYZ order by x desc
 x| y| z|
--|--|--|
10|11|12|
 5| 6| 7|
 0| 1| 2|
OUT

test join => 'a cola, b, c, d, e, y, z;#ab :jx on a = x', <<\OUT;
select a cola, b, c, d, e, y, z from ABCDE join XYZ on a = x
cola
  | b| c| d| e| y| z|
--|--|--|--|--|--|--|
 0| 1| 2| 3| 4| 1| 2|
 5| 6| 7| 8| 9| 6| 7|
10|11|12|13|14|11|12|
OUT

test where => 'ab.a + ab.b as sum, ab.c * ab.d as prod, rou(ab.e / xy.y), z;#ab# :jxy# on c = z;b > 1', <<\OUT;
select ab.a + ab.b as sum, ab.c * ab.d as prod, round(ab.e / xy.y), z from ABCDE ab join XYZ xy on c = z where b > 1
sum
  |prod
  |   |round
  |   | | z|
--|---|-|--|
11| 56|2| 7|
21|156|1|12|
OUT
