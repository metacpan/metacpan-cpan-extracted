use Pg::Corruption qw/ connect_db foreign_keys /;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o2 = { 'db' => 'lessons', verbose=>0 };
my ( $dh, @arr ,$h);


SKIP: {
    #skip 'developer test', 6    if  $login cmp 'ioannis';
    skip 'developer test', 6    if 'ioannis' cmp DEVELOPMENT;
	$dh  = connect_db($o2);
	ok $dh;
	@arr = foreign_keys('fk','sales',$dh);
    is_deeply $arr[0]->{key}  , [qw/ book /];
	@arr = foreign_keys('fk','house1c',$dh);
    is_deeply $arr[0]->{key}  , [qw/ husband hcity /];
	@arr = foreign_keys('fk','house',$dh);
    is_deeply $arr[0]->{key}  , [qw/ husband hcity /];
    is_deeply $arr[1]->{key}  , [qw/ wife    wcity /];

	ok ! foreign_keys('pg_catalog','pg_database',$dh) ; 
}
END { $dh and $dh->rollback and   $dh->disconnect }

