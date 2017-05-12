#!perl
use Test::More;
use Test::Exception ;
use DBI;

package My::Object;
use Moose;
with qw/Pg::Blobs/;
has 'dbh' => ( is => 'ro', required => 1);
sub pgblobs_dbh{ return shift->dbh(); }
1;

package main;

BEGIN{
  eval{ require Test::PostgreSQL;};
  if( $@ ){
    plan skip_all => 'No Test::PostgreSQL';
    done_testing();
  };
}

diag("Building new Test::PostgreSQL");
my $pgsql = Test::PostgreSQL->new();
unless( $pgsql ){
  plan skip_all => "Error building Test::PostgreSQL: ".$Test::PostgreSQL::errstr;
  done_testing();
}
diag ("Done - Starting actual tests on temp DB: ".$pgsql->dsn());


my $dsn = $pgsql->dsn;
ok( my $dbh = DBI->connect($dsn , '' , '' , { AutoCommit => 1 }) , "Ok connecting to db");
unless( $dbh ){
    BAIL_OUT("Could not connect to DB using $dsn");
}

ok( my $o = My::Object->new({ dbh => $dbh }) , "Ok created o");
$dbh->begin_work();

ok( my $oid = $o->pgblobs_create_blob() , "Blob is created");
ok( $oid = $o->pgblobs_store_blob('BINARYCONTENT') , "Something is stored in blob");
ok( my $rc =  $o->pgblobs_fetch_blob($oid) , "Fetched content");
ok( $rc eq 'BINARYCONTENT' , "Same content was retrieved");
{
    ## A bit of cake streaming now
    my $nslices = 1000;
    my $cake;
    my $read = sub{
	unless( $nslices-- ){ return undef ;}
	my $slice =  int(rand(1000)) + 1 ;
	$cake .= $slice ;
	return $slice;
    };
    ok( my $other_oid = $o->pgblobs_stream_in_blob($read) , "Ok got other_oid");
    ok( my $other_cake = $o->pgblobs_fetch_blob($other_oid) , "Ok got other cake");
    cmp_ok($other_cake, 'eq' , $cake , "Two cakes are equal");

    ## Now let us try to stream it out.
    my $streamed_out;
    ok( my $streamed_out_length = 
	$o->pgblobs_stream_out_blob(sub{my $fresh_bytes = shift; $streamed_out .= $fresh_bytes; } , $other_oid)
	, "Ok streamed out");
    cmp_ok(length($streamed_out),'==', $streamed_out_length , "Lenghts are the same");
    cmp_ok($streamed_out , 'eq' , $cake , "Streamed out is equal to cake");


}

done_testing();
