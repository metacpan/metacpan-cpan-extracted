#!perl 

use Cwd ;
use Carp::Always ;
use Test::More tests => 9;
#use Test::More 'no_plan' ;

BEGIN {
  use_ok( 'Pg::BulkCopy' ) || print "Bail out!";
}

diag( "Testing Pg::BulkCopy $Pg::BulkCopy::VERSION, Perl $], $^X" );

# This test creates a new object and checks a couple of default behaviors.
# All mandatory values are 'dummy', so nothing can be done with this object
# except checking that defaults are what we expect.

# unlink, because later this file is tested for.
unlink '/tmp/pg_BulkCopy.ERR' ;

my $PG_Test1 = Pg::BulkCopy->new(
    dbistring => 'dummy',
    dbiuser   => 'dummy',
    dbipass   => 'dummy',
    filename  => 'dummy',
    table     => 'dummy', );    
is ( $PG_Test1->workingdir() , '/tmp/', 'workingdir defualts to tmp' ) ;
is ( $PG_Test1->iscsv() , 0, 'iscsv defaults to 0, for tab seperated.' ) ;
is ( $PG_Test1->errorlog() , '/tmp/pg_BulkCopy.ERR', 'Error log file in working directory.' ) ;   
my @s = stat  '/tmp/pg_BulkCopy.ERR' ;
ok ( @s , 'created a log file.') ;

my $workdir = getcwd;
my $delme = "$workdir/pg_BulkCopy.ERR" ;
unlink $delme ;
my $PG_Test2 = Pg::BulkCopy->new(
    dbistring => 'dummy',
    dbiuser   => 'dummy',
    dbipass   => 'dummy',
    filename  => 'dummy',
    table     => 'dummy', 
    iscsv	  => 1 ,
    workingdir => $workdir,
    );    
is ( $PG_Test2->workingdir() , "$workdir/", 'workingdir should not be temp and have appended a slash.' ) ;
is ( $PG_Test2->iscsv() , 1, 'iscsv defaults to 0, for tab seperated. Was set to 1 for csv.' ) ;
is ( $PG_Test2->errorlog() , "$workdir/pg_BulkCopy.ERR", 'Error log file in working directory.' ) ;   
@s = stat  "$workdir/pg_BulkCopy.ERR" ;
ok ( @s , 'created the log file.') ;
