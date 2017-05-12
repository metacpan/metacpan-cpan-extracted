use Pg::Corruption qw/ connect_db dup_fks foreign_keys/;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 , quiet=>1};
my $o2 = { 'db' => 'lessons' , verbose=>0 , quiet=>1};
my ($dh,$struct) ;


SKIP: {
    skip 'developer test', 5     if 'ioannis' cmp DEVELOPMENT;

	$dh     = connect_db($o2);
    $struct = [foreign_keys('fk','house1c',$dh)];
	ok  ! dup_fks($struct, $dh,$o1), 'one compound fk';
	$dh->disconnect;

	$dh     = connect_db($o2);
    $struct = [foreign_keys('fk','sales_no',$dh)];
	ok   dup_fks($struct, $dh,$o1), 'no fk';
	$dh->disconnect;

	$dh = connect_db($o2);
	ok $dh;
    $struct = [foreign_keys('fk','sales',$dh)];
	ok   dup_fks( $struct, $dh, $o2), 'one simple fk';
	$dh->disconnect;

	$dh     = connect_db($o2);
    $struct = [foreign_keys('fk','sales_1',$dh)];
	ok   dup_fks($struct, $dh,$o1), 'two simple fks';
	$dh->disconnect;
}
END { $dh and $dh->rollback and   $dh->disconnect }
