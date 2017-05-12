use Pg::Corruption qw/ connect_db primary_keys /;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 };
my $o2 = { 'db' => 'lessons', verbose=>0 };
my $dh ;


SKIP: {
    skip 'developer test', 5    if 'ioannis' cmp DEVELOPMENT;
	$dh = connect_db($o1);
	ok $dh;
	is_deeply [primary_keys('public','t',$dh,$o1)]   , ['name'];

    $dh->disconnect;
	$dh = connect_db($o2);
	is_deeply [primary_keys('fk','person',$dh,$o2)]  , [qw/first city/];
	is_deeply [primary_keys('fk','person3',$dh,$o2)] , [qw/age city first/];
	ok ! primary_keys('pg_catalog','pg_database',$dh,$o2) ; 
}

END { $dh and $dh->rollback and   $dh->disconnect }
