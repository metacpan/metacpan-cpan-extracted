#!/usr/bin/env perl 

use 5.012;
use Cwd ;
use Config::General;
#use IhasQuery ;
use DBIx::Simple ;
use File::Copy ;
use strict ;
use Pg::BulkCopy ;
# 
#use Test::More tests => 27;
use Test::More 'no_plan' ;

 
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
unlink "$tdata/test_bad5.err" ;

# Run a basic test with the default tab seperated file.
#  Checks that the right number of records imported, 
# verifies the reject file.

my $table = 'millions' ;
my $filename = "errors_25.tsv" ;

my $mext = qq |
my \$bad5 = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    errorlog  => 'test_bad5.err', 
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    debug      => 2 ,
    table     => $table, ); | ;
    say $mext ;

my $bad5 = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    errorlog  => 'test_bad5.err', 
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    debug      => 2 ,
    table     => $table, ); 

#my $millions = IhasQuery->new( $bad5->CONN(), 'millions' ) ;
$testing = DBIx::Simple->new(  $bad5->CONN() ) ;
$Q = 'select count(*) from millions' ; 
$A = undef ;

$bad5->TRUNC() ;
$bad5->LOAD() ;
is ( $bad5->errcode() , 1 , 'Return Status should be 1' ) ;
is ( $bad5->errstr() , '' , 'Return string should be empty' ) ;
$testing->query( $Q )->into( $A ) ;
is ( $A , 22, "Counted 22 records loaded." ) ;

open FH, "<$tdata/$filename.REJECTS" or die $!;
like (  <FH> , 
        qr/1	1368689183	97	reconciler/,
        "reject matches: 1	1368689183	97	reconciler") ;
like (  <FH> , 
        qr/12	5728931094	92	fluctuating	ZAPPA/,
        "reject matches: 12	5728931094	92	fluctuating	ZAPPA") ;
like (  <FH> , 
        qr/25	Jubilee/,
        "reject matches: 25	Jubilee") ; 
my $temp = <FH> ;
my $len = length $temp ;
ok ( $len <= 1 , "Testing that if there is an extra line, it should be empty" ) ;
ok( eof FH == 1 , "Confirm end of reject file" );                        

close FH ;

# The following are tests of the dbg function to insure that messages are logged at the correct level.
# Here debug = 2 is tested.
open FHL, "<$tdata/test_bad5.err" or die $! ;
my (@FHL) = (<FHL>) ;
close FHL ;
my $lookedforit = 0 ;
for ( @FHL ) { if ( $_ =~  m/1368689183/ ) { $lookedforit++ } }
is ( $lookedforit, 1 , 'Found string from a reject 1 time in the error log.' ) ;
$lookedforit = 0 ; 
for ( @FHL ) { if ( $_ =~  m/9330515197/ ) { $lookedforit++ } }
is ( $lookedforit, 0 , 'A record that was not a reject should not be in this error file.' ) ;
$lookedforit = 0 ; 
for ( @FHL ) { if ( $_ =~  m/Optionstr/ ) { $lookedforit++ } }
ok ( $lookedforit > 0 , 'With debug set to 2 this string should be in the log.' ) ;
$lookedforit = 0 ; 


# Similar to above except that a different csv file is used.

$filename = "errors_25.csv" ;
$bad5->iscsv(1);
$bad5->filename($filename) ;
$bad5->LOAD() ;
is ( $bad5->errcode(), 1 , 'Return Status should be 1' ) ;
is ( $bad5->errstr() , '' , 'Return string should be empty' ) ;
$A = undef ; $testing->query( $Q )->into( $A ) ;
is ( $A , 42, "Counted 42 records loaded." ) ;


open FH, "<$tdata/$filename.REJECTS" or die $!;
like (  <FH> , 
        qr/33,2791161243,182,Locke/,
        "reject matches: 33,2791161243,182,Locke") ;
like (  <FH> , 
        qr/36,3650751672,217,regenerates, degenerate/,
        "reject matches: 36,3650751672,217,regenerates, degenerate") ;                    
like (  <FH> , 
        qr/7,1784270707,182,hammering/,
        "reject matches: 7,1784270707,182,hammering") ;     
like (  <FH> , 
        qr/124,tyrant,/,
        "reject matches: 124,tyrant,") ; 
like (  <FH> , 
        qr/125,040403232,318,"Macaroni Macaroon",,/,
        "reject matches: 125,040403232,318,\"Macaroni Macaroon\",,") ; 
$temp = <FH> ;
$len = 0 ;
$len = length $temp ;
ok ( $len <= 1 , "Testing that if there is an extra line, it should be empty" ) ;
ok( eof FH == 1 , "Confirm end of reject file" );                      

close FH ;

# This is just an extra test run of a different file.

$filename = "t157a.csv" ;
$table = 'testing' ;


TODO: {
    local $TODO = qq / Fix CSV problems / ;

my $PG_Test1 = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => $filename,
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    iscsv       => 1,
    table     => $table, );

is( $PG_Test1->TRUNC(), 0, 'Confirm a TRUNC' ) ;
is ( $PG_Test1->LOAD() , 1 , 'Return Status should be 1' ) ;
my $a, $b ;
$a = $PG_Test1->errcode() ;
$b = $PG_Test1->errstr() ;
say "Error Code $a\nError Str $b" ;

$A = undef ; $testing->query( $Q )->into( $A ) ;
is ( $A , 42, "Counted 42 records loaded." ) ;
#my $qPG_Test1 = IhasQuery->new( $PG_Test1->CONN() , 'testing' ) ;
is ( $A , 156 , "Should have loaded 156 records." ) ;

# This is a further test of the dbg function. 
# Here the default debug = 1 is tested (it is set by default not explicitly). 
my $errfile = $PG_Test1->errorlog() ;
open FH2, "<$errfile" ;
my (@FH2) = (<FH2>) ;
close FH2 ;
$lookedforit = 0 ;
for ( @FH2 )  { if ( $_ =~  m/Optionstr/ ) { $lookedforit++ } }
is ( $lookedforit, 0 , 'With debug set to 1 the item searched for in log should not be there.' ) ;
$lookedforit = 0 ; 
}

