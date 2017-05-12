use Pg::Corruption qw/ connect_db verify_one_fk foreign_keys/;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 , quiet=>1};
my $o2 = { 'db' => 'lessons' , verbose=>0 , quiet=>1};
my ($dh,$struct) ;


SKIP: {
    skip 'developer test', 5    if 'ioannis' cmp DEVELOPMENT;

	$dh     = connect_db($o2);
	ok    verify_one_fk('fk.sales','fk.books', 
                     ['book'],['name'], $dh,$o1), 'one simple fk';
	ok    verify_one_fk('fk.sales_1','fk.person_1', ['customer'],['first'], $dh,$o1),;
	ok    verify_one_fk('fk.sales_1','fk.books'   , 
                     ['book']    ,['name' ], $dh,$o1), 'two simple fks';

# ruct = [foreign_keys('fk','sales_1',$dh)];
	ok  ! verify_one_fk(undef,'fk.books'   , ['book']    ,['name' ], $dh,$o1);
	ok  ! verify_one_fk('','fk.books'   , ['book']    ,['name' ], $dh,$o1);
	ok  ! verify_one_fk('fk.sales',''   , ['book']    ,['name' ], $dh,$o1);
	ok  ! verify_one_fk('fk.sales_1','fk.books'   , []    ,['name' ], $dh,$o1);
	ok  ! verify_one_fk('fk.sales_1','fk.books'   , ['book'] ,[], $dh,$o1);
	ok   ! verify_one_fk('fk.house1c','fk.person',
                     [qw/husband hcity/],[qw/first city/], $dh,$o1), 'one compound fk';
	#ok   verify_one_fk('fk.sales_1','fk.books'   , ['book'] ,[''], $dh,$o1);

	$dh->disconnect;

}
END { $dh and $dh->rollback and   $dh->disconnect }
