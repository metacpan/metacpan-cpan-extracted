use Pg::Corruption qw/ connect_db  attnum2attname /;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 };
my $dh ;

SKIP: {
    skip 'developer test', 8    if 'ioannis' cmp DEVELOPMENT;
	$dh = connect_db($o1);
	ok $dh;
 	is_deeply  [attnum2attname( 19042, $dh, 1)]   , ['name'       ] ;
 	is_deeply  [attnum2attname( 19042, $dh, 2)]   , ['age'        ] ;
	is_deeply  [attnum2attname( 19042, $dh, 1, 2)], [qw/ name age/] ;

 	ok ! attnum2attname( 19042, $dh, ),  'emplty request'     ;
	ok ! attnum2attname( 19042, $dh, 0), 'attnum not valid'   ;
	ok ! attnum2attname( 19042, $dh, 9), 'attnum out of range';
	ok ! attnum2attname( 19   , $dh, 1), 'reloid not valid'   ;
	#ok ! attnum2attname( 19042, $dh, 4), 'dropped column'     ;
}
END { $dh and $dh->rollback and   $dh->disconnect }
