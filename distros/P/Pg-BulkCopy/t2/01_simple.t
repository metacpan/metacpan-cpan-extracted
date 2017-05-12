#!perl 

use strict ;
use warnings ;
use 5.012 ;
use Cwd ;
#use Config::Std;
use Config::General;
use IhasQuery ;
use DBIx::Simple ;
use File::Copy ;

use Test::More ; #tests => 26;
#use Test::More 'no_plan' ;

diag( "Testing Pg::BulkCopy $Pg::BulkCopy::VERSION, Perl $], $^X" );
BEGIN {
    use_ok( 'Pg::BulkCopy' ) || print "Bail out!";
    }
 
########################################################################
# COMMON CODE. CUT AND PASTE TO ALL TESTS.
#######

# get pwd, should be distribution directory where harness.sh was invoked from.
my $pwd = getcwd;

my $tdata = "$pwd/tdata" ;

# Load named config file into specified hash...
#read_config  => my %config;
my $conf = new Config::General( "$pwd/t2/test.conf" );
my %config = $conf->getall;

# Extract the value of a key/value pair from a specified section...
my $dbistring  = $config{DBI}{dbistring};
my $dbiuser  = $config{DBI}{dbiuser};
my $dbipass = $config{DBI}{dbipass};

# Change this value to choose your own temp directory.
# Make sure that both the script user and the postgres user
# have rights to the directory and to each other's files.
my $tmpdir = $config{OTHER}{'tmpdir'} || '/tmp' ;
my $table = 'testing' ;
 
# Suppress Errors from the console.
# Comment to see all the debug and dbi errors as your test runs.
open STDERR, ">>/dev/null" or die ;

# reusable variables.
my $testing = undef ; my $Q = undef ; my $A = undef ; my @AA = () ; my %B = () ;
my $Simple = DBIx::Simple->new( $dbistring, $dbiuser, $dbipass ) ;

my $QCount = sub {
    my $table = shift ;
    $Simple->query( "SELECT COUNT(*) FROM $table" )->into( my $A ) ;
    return $A ;
} ;

########################################################################
# END OF THE COMMON CODE
#######


# Delete files for this test that might have been created previously.
unlink "$tdata/blob1.tsv.REJECTS" ;
unlink "$tdata/pg_BulkCopy.ERR" ;
unlink '/tmp/pg_BulkCopy.ERR' ;
unlink "$tdata/blob2.csv.REJECTS" ;
unlink "$tdata/DUMP1.tsv" ;
unlink "$tdata/DUMP1.csv" ;
unlink "$tdata/DUMP1.csv.REJECTS" ;
unlink "$tdata/DUMP1.tsv.REJECTS" ;
unlink "$tdata/t133992.tsv.REJECTS" ;

# Run a basic test with the default tab seperated file.

my $filename = "blob1.tsv" ;

note( qq |
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    icsv      => 0 ,
    table     => $table, | ) ;   



my $PG_Test1 = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    icsv      => 0 ,
    table     => $table, );

ok( $PG_Test1, "Have a variable for new object" ) ;

# Tests the trigger on workingdir. the first test object uses the mandatory trailing slash!
is ( $PG_Test1->{'workingdir'} , "$tdata/" , "Confirm working directory is set to $tdata/" ) ;

is( $PG_Test1->TRUNC(), 0, 'A TRUNC operation succeeded.' ) ;

is ( $PG_Test1->LOAD() , 1 , 'Return Status should be 1' ) ;
is ( $PG_Test1->{'errcode'} , 1 , 'Internal Error Code should also be 1' ) ;
is ( $PG_Test1->{'errstr'} , '' , 'Return string should be empty' ) ;

my $testing = undef ; my $Q = undef ; my $A = undef ;
#my $testing = IhasQuery->new( $PG_Test1->CONN() , 'testing' ) ;
$testing = DBIx::Simple->new( $PG_Test1->CONN() ) ;

$Q = "select count(*) from testing" ;
$A = undef ;
$testing->query( $Q )->into( $A ) ;
is ( $A , 15631 , "Should load 15631" ) ;

$PG_Test1->filename( 'DUMP1.tsv' ) ;
is( $PG_Test1->filename(), 'DUMP1.tsv', 'Successfully set a new filename for new operation') ;
$PG_Test1->DUMP() ;
is ( $PG_Test1->errcode() , 1 , 'Return Status should be 1' ) ;
is ( $PG_Test1->errstr() , '' , 'Return string should be empty' ) ;

my @S1 = stat "$pwd/tdata/$filename" ;
my @S2 = stat "$pwd/tdata/DUMP1.tsv" ;
ok(  $S1[7] == $S2[7] , "The dump and load file should by the same size, but records may be in different order." ) ;

# Now do a test with a csv file.

$filename = "blob2.csv" ;

my $PG_Test2 = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata",
    tmpdir 		=> $tmpdir ,
    iscsv     => 1, 
    table     => $table, );

ok( $PG_Test2, "Have a variable for new object" ) ;

# Tests the trigger on workingdir. The second object omits the mandatory trailing slash!
# The trigger should fix it so that users may include or omit the trailing slash.
is ( $PG_Test2->{'workingdir'} , "$tdata/" , "Confirm working directory is set to $tdata/" ) ;

@S1 =() ; 
@S2 = () ;

# clear the table.
is( $PG_Test2->TRUNC(), 0, "TRUNC thinks it ran" ) ;

# $Q is the same as last test.
$testing->query( $Q )->into( $A ) ;
is ( $A , 0, 'Confirm that Trunc worked.' ) ;

is ( $PG_Test2->LOAD() , 1 , 'Return Status should be 1' ) ;
is ( $PG_Test2->errstr() , '' , 'Return string should be empty' ) ;

$testing->query( $Q )->into( $A ) ;
is ( $A , 33992 , "Should load 33992, old records should have been truncated." ) ;

$PG_Test2->filename( 'DUMP1.csv' ) ;
is( $PG_Test2->filename(), 'DUMP1.csv', 'Successfully set a new filename for new operation') ;
is ( $PG_Test2->DUMP() , 1 , 'Return Status should be 1' ) ;
is ( $PG_Test2->errstr() , '' , 'Return string should be empty' ) ;
my @SS1 = stat "$pwd/tdata/$filename" ;
my @SS2 = stat "$pwd/tdata/DUMP1.csv" ;
ok(  $SS1[7] == $SS2[7] , "The dump and load file should by the same size, but records may be in different order." ) ;

$PG_Test2->filename( 't133992.tsv' ) ;
$PG_Test2->iscsv( 0 ) ;
$PG_Test2->table( 'millions' ) ;
is( $PG_Test2->table(), 'millions', 'confirm attribute set' ) ;
$PG_Test2->TRUNC() ;
my $millions = IhasQuery->new( $PG_Test2->CONN() , 'millions' ) ;
is( $millions->count(), 0, 'Confirm truncation' ) ;
$PG_Test2->LOAD() ;
is( $millions->count(), 133992, 'Confirm Load of 133992 records.' ) ;



done_testing() ;