use Pg::Corruption qw/ connect_db dup_pks/;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 , quiet=>1};
my $o2 = { 'db' => 'lessons' , verbose=>0 , quiet=>1};
my ($dh,$pks) ;


SKIP: {
    skip 'developer test', 7     if 'ioannis' cmp DEVELOPMENT;
	$dh = connect_db($o1);
	ok $dh;
	is  dup_pks('public','t',['name'], $dh,$o1), 0;

	$dh->disconnect;
	$dh = connect_db($o2);
	ok $dh;
	$pks = [ qw/ city /];
	is  dup_pks('fk','person',['city'], $dh,$o2), 0;
	is  dup_pks('fk','person',['first'], $dh,$o2), 2;
	is  dup_pks('fk','person',[qw/first city/], $dh,$o2), 0;
	is  dup_pks('fk','person',[qw/first age city/], $dh,$o2), 0;

	$dh->{ PrintWarn } = 0;
	is  dup_pks('fk','person',['ffff'], $dh,$o2), -1;

}
END { $dh and $dh->rollback and   $dh->disconnect }
