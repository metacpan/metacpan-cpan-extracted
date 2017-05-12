use Pg::Corruption qw/ connect_db  tbl_byoid /;
use Test::More qw( no_plan );
use DBI;

use constant DEVELOPMENT => getlogin ;

my $o1 = { 'db' => 'postgres', verbose=>0 };
my $dh ;


SKIP: {
    skip 'developer test', 3     if 'ioannis' cmp DEVELOPMENT;
	$dh = connect_db($o1);
	ok $dh;
	ok !  tbl_byoid(333, $dh);

    $dh->disconnect;
	$dh = connect_db($o1);
	is  tbl_byoid(19042, $dh), 'public.t';
}
END { $dh and $dh->rollback and   $dh->disconnect }
