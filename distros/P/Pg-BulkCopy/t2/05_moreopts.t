#!perl 
use 5.012;
use Cwd ;
use Config::Std;
use Config::General;
use IhasQuery ;
use DBIx::Simple ;
use File::Copy ;

use Test::More tests => 17;
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

unlink "$tdata/blob1.tsv.REJECTS" ;
unlink "$tdata/pg_BulkCopy.ERR" ;
unlink "$tdata/blob2.csv.REJECTS" ;
unlink "$tdata/DUMP1.tsv" ;
unlink "$tdata/DUMP1.csv" ;
unlink "$tdata/DUMP1.csv.REJECTS" ;
unlink "$tdata/DUMP1.tsv.REJECTS" ;
unlink "$tdata/t133992.tsv.REJECTS" ;

# t157a and t157b are similar files, a is not quoted b is quoted with ".
# b also has a header record. batchsize is set down to 10.

my $filename = "t157a.csv" ;
my $table = 'testing' ;

TODO: {
    local $TODO = qq / CSV problems CSV tests not requried for release / ;
my $PG_Test = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    iscsv       => 1,
    debug       => 2 ,
    batchsize   => 10, 
    table     => $table, );

$PG_Test->TRUNC() ;
$PG_Test->LOAD() ;
is ( $PG_Test->errcode() , 1 , 'Return Status should be 1' ) ;

is ( $PG_Test->errstr() , '' , 'Return string should be empty' ) ;

#my $IhQ_testing = IhasQuery->new( $PG_Test->CONN() , 'testing' ) ;

is ( $QCount->( 'testing' ) , 156 , "Should load 156" ) ;

open FHL, "<$tdata/pg_BulkCopy.ERR" or die $!;
my (@FHL) = (<FHL>) ;
close FHL ;
say ( @FHL ) ;
my $found = 0 ;
for ( @FHL ) { if ( $_ =~ m/Processing Batch\: 16/ ) { $found++ } }
is ( $found, 1, 'Found Batch 16 in log.' ) ;
$found = 0 ;
for ( @FHL ) { if ( $_ =~ m/Processing Batch\: 17/ ) { $found++ } }
is ( $found, 0, 'Did not find Batch 17 in log. There should have been 16 batches.' ) ;


$PG_Test->TRUNC() ;



# The file with the " and the header is failing. figure out why and implement header support.

    # Set file name to t157b.csv
    $PG_Test->filename( 't157b.csv' ) ;
# Test::More has an issue with the BulkCopy object exiting when LOAD has a critical failure
# commented instead of SKIP inside TODO.
#SKIP: {    $PG_Test->LOAD() ; }
    is ( $PG_Test->errcode() , 1 , 'Return Status should be 1' ) ;
    is ( $PG_Test->errstr() , '' , 'Return string should be empty' ) ;
    is ( $QCount->( 'testing' ) , 156 , "Should load 156" ) ;
}  


#Now test for maxerrrors.
$filename = 'large_5_errors.tsv' ;
#my $filename = 'errors_25.tsv' ;
$table = 'millions' ;
my $MaxErrors = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    iscsv       => 0,
    debug       => 2 ,
    batchsize   => 5000, 
    maxerrors   => 6,
    table     => $table, );
 
$MaxErrors->TRUNC() ;
$MaxErrors->LOAD() ;

is ( $MaxErrors->errcode() , 1 , 'Return Status should be 1' ) ;
is ( $MaxErrors->errstr() , '' , 'Return string should be empty' ) ;
my $IhQ_Max = IhasQuery->new( $MaxErrors->CONN() , $table  ) ;
is ( $IhQ_Max->count() , 33989 , "Should load 33989" ) ;  
 
# It should have worked with max errors at 6. now we chop max errors to 5, so the last error should kill it.
$MaxErrors->TRUNC() ;
$MaxErrors->maxerrors( 5 ) ;
$MaxErrors->LOAD() ;
is ( $MaxErrors->errcode() , -1 , 'Return Status should be -1 because the load failed.' ) ;
like ( $MaxErrors->errstr() , qr/Max Errors 5 reached/, 'Return string should tell us Max Errors was reached.' ) ;
$MaxErrors->maxerrors( 0 ) ;
is ( $MaxErrors->maxerrors(), 99999, "Setting maxerrors to 0 should set it to 99999" ) ;
$MaxErrors->maxerrors( 1 ) ;
is ( $MaxErrors->maxerrors(), 1, "Now maxerrors is set to 1." ) ;
$MaxErrors->TRUNC() ;
$MaxErrors->LOAD() ;
like ( $MaxErrors->errstr() , qr/Max Errors 1 reached/, 'Return string should tell us 1 Max Errors was reached.' ) ;
