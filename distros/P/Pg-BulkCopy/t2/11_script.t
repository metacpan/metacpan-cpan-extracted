#!perl 
use strict ;
use warnings ;
use 5.012;
use Cwd ;
use Config::Std;
use Config::General;
use IhasQuery ;
use File::Copy ;
use Test::Exception ;
use IO::CaptureOutput qw/capture_exec/ ;

use Test::More ;#tests => 17;
#use Test::More 'no_plan' ;

diag( "Testing Pg::BulkCopy $Pg::BulkCopy::VERSION, Perl $], $^X" );
BEGIN {
    use_ok( 'Pg::BulkCopy' ) || print "Bail out!";
    }
    
    # All of this script is marked as TODO because it takes extra effort to test the script!
    # You will need to tweak some things including the script's testparam file.    
# TODO: { 
    # local $TODO = qq /If you have it working, you can remove the TODO!/ ;
# 
########################################################################
# COMMON CODE. CUT AND PASTE TO ALL TESTS.
#######

# get pwd, should be distribution directory where harness.sh was invoked from.
my $pwd = getcwd;
my $tdata = "$pwd/tdata" ;
if ( stat '/tmp/BULKCOPY.JOB' ) {
	unlink '/tmp/BULKCOPY.JOB' ;
	 die "Cant delete file from prior run. Try \"sudo rm /tmp/BULKCOPY.JOB\"" if ( stat '/tmp/BULKCOPY.JOB' ) ;
	 }

# Load named config file into specified hash...
my %config = () ;
# If yaml use read_config
#read_config "$pwd/t2/test.conf" => %config;
# If apache style config use general.
my $conf = new Config::General( "$pwd/t2/test.conf" );
%config = $conf->getall;


# Extract the value of a key/value pair from a specified section...
my $dbistring  = $config{DBI}{dbistring};
my $dbiuser  = $config{DBI}{dbiuser};
my $dbipass = $config{DBI}{dbipass};

# Change this value to choose your own temp directory.
# Make sure that both the script user and the postgres user
# have rights to the directory and to each other's files.
my $tmpdir = '/tmp' ;
my $table = 'testing' ;

# Suppress Errors from the console.
# Comment to see all the debug and dbi errors as your test runs.
#open STDERR, STDIN or die ;

########################################################################
# END OF THE COMMON CODE
#######

# Your script may be somewhere else!
my $script = "$pwd/bin/pg_bulkcopy.pl" ;

# Run Test executes a test of the script via system().
# It takes a hash with the keys: 
#	command = a string containg the exact command to execute.
#	read = a string a filename specified with the read switch.
# 	readtext = a string containing the contents to write to the specified read file.
#	windows = a reserved boolean for future support of Windows. 
# It returns the output of the command (both STDIN and STDERR) as a string.

sub RunTest {
	my %params = @_  ;
	my @keys = qw / command read readtext windows / ;
	foreach my $k (@keys) { unless ( $params{ $k } ) { $params{ $k } = 0 } }
	if ( $params{ read } and $params{ readtext } ) {
		# say "Run Command $params{ command }" ;
		# say "I will write this text to $params{ read }:\n $params{ readtext }" ;
		open READFILE , ">$params{ read }" or die "Cant write to $params{ read }" ;
		print READFILE $params{ readtext } ;
		close READFILE ;
		}
	my $testoutput = "$pwd/testpgbcp.t11" ;
	if ( stat "$testoutput" ) 
		{ unlink $testoutput or
			die "Can\t delete existing file $testoutput $! " } ;
	my %r = () ;
	($r{ stdout }, $r{ stderr }, $r { success }, $r{ exit_code })  
		= capture_exec( $params{ command } ) ;
	return %r ;	
	}
	

ok( require( $script ) , 'Load script successfully' ) or exit ;

my $config1 = "$pwd/t2/script1.params" ;
my $config2 = "$pwd/t2/script2.params" ;
my $command3 = "$script --read $config1" ; 
my $command4 = "$script --read $config2" ; 

my %t1 = RunTest( 'command' => $script ) ;
#say "Raw test results \n******\nstdout $t1{ stdout } \nstderr $t1{ stderr }\n******" ;
ok( $t1{ stderr } =~ m/information about how to use pg_bulkcopy.pl./i, 
	'With no parameters information about how to get help prints on stderr' ) ;
	
my %t2 = RunTest( 'command' => "$script -?" ) ;
ok( $t2{ stderr } =~ m/information about how to use pg_bulkcopy.pl./i, 
	'A question mark -? should get the same response.' ) ;

$config1 = qq |
[options]
filename : blob1.tsv
load : 1
dump :
iscsv :
dbistring : $dbistring
dbiuser : $dbiuser
dbipass : $dbipass
table : testing
#workingdir : /psql_scr/testing/tdata/
workingdir : $tdata
#tmpdir : /psql_scr/testing/tmp/
tmpdir : $tmpdir
batchsize :
errorlog : 
maxerrors : 50
debug : 2
trunc : 1
| ;


#done_testing() ; exit ;

my $handle_on_testing = Pg::BulkCopy->new(
    dbistring => $dbistring,
    dbiuser   => $dbiuser,
    dbipass   => $dbipass,
    filename  => 'dummyfilename',
    workingdir => "$tdata/",
    tmpdir 		=> $tmpdir ,
    icsv      => 0 ,
    table     => 'testing', );
my $QueryHandleTesting = IhasQuery->new( $handle_on_testing->CONN() , 'testing' ) ; 

note( qq {
my %t3 = RunTest( 
	'command' => "$script --read $pwd/config1",
	'read' => "$pwd/config1",
	'readtext' => $config1 , } ) ;

my %t3 = RunTest( 
	'command' => "$script --read $pwd/config1",
	'read' => "$pwd/config1",
	'readtext' => $config1 , ) ;
# say "Raw test results \n******\nstdout $t3{ stdout } \nstderr $t3{ stderr }\nsuccess? $t3{ success}
	# exit_code   $t3{ exit_code}\n******" ;	
is( $t3{ success } , 1 , 'Execution should report success.' );
is( $t3{ exit_code} , 0 , 'Should have a 0 exit code.' );
like( $t3{ stdout } , qr/iscsv 0/, 'Should spew icsv 0' ) ;
ok( $t3{ stderr } =~ m/TRUNCATE testing/i, 
	'stderr should inform us that it will truncate the table' ) ;
is ( $QueryHandleTesting->count() , 15631 , "Should load 15631" ) ;

my @commands3a = ( 
	"$script " ,
	'--filename more1.tsv' , 
	'--iscsv 0' ,
	"--dbistring \"$dbistring\"" ,
	"--dbiuser $dbiuser" ,
	"--dbipass $dbipass" ,
	"--table testing",
	"--workingdir $tdata",
	"--tmpdir $tmpdir" ,
	"--debug 1" ,
	) ;
my $commands3a = "@commands3a" ;
say "===== Commands3a ======\n$commands3a\n" ;
my %t3a = RunTest( 'command' => $commands3a ) ;
say $QueryHandleTesting->count()  ; 
if ( $QueryHandleTesting->count() != 15633 ) 
	{ say "incorrect recoord count ", $QueryHandleTesting->count() ; exit }
is ( $QueryHandleTesting->count() , 15633 , "Should have added 2 more." ) ;
	

my @commands4 = ( 
	"$script " ,
	'--filename shaved.csv' , 
	'--iscsv 1' ,
	"--dbistring \"$dbistring\"" ,
	"--dbiuser $dbiuser" ,
	"--dbipass $dbipass" ,
	"--table testing",
	"--workingdir $tdata",
	"--tmpdir $tmpdir" ,
	"--maxerrors 1" ,
	) ;
my $commands4 = "@commands4" ;
# Uncomment to get a debug on what your command is. Useful for debugging testing itself.
# say $commands4 ; exit ;

SKIP: {
	skip( 'Fixing CSV is a todo for later than this release' ,1 ) ;
TODO: {
local $TODO = 'Until some csv issues are sorted out expect some problems' ;
my %t4 = RunTest( 'command' => $commands4 ) ;
say $QueryHandleTesting->count()  ; 
say "Raw test results \n******\nstdout $t4{ stdout } \nstderr $t4{ stderr }\nsuccess? $t4{ success}
	 exit_code   $t4{ exit_code}\n******" ;	
ok( $t4{ success } == 1 , 'Execution should report success.' );
ok( $t4{ exit_code} == 0 , 'Should have a 0 exit code.' );
ok( $t4{ stdout } =~ m/iscsv 1/, 'Should spew icsv 1' ) ;
ok( $t4{ stdout } =~ m/trunc 0/, 'Should not truncate.' ) ;
my $temp = $QueryHandleTesting->count() ;
ok( $temp > 15631 , 'Should now have more records than before.' ) ;
ok( $temp > 0 , 'If there are now 0 records in table testing something is really wrong' ) ;
} ; #SKIP
} ; #TODO

unlink( "$tdata/exported.tsv" )  ;
my @commands5 = ( 
	"$script " ,
	'--filename exported.tsv' , 
	"--dbistring \"$dbistring\"" ,
	"--dbiuser $dbiuser" ,
	"--dbipass $dbipass" ,
	"--table testing",
	"--workingdir $tdata",
	"--tmpdir $tmpdir" ,
	"--maxerrors 10" ,
	"--dump" ,
	) ;
my $command5 = "@commands5" ;	
say "Command would be $command5" ;

my %t5 = RunTest( 'command' => $command5 ) ;
ok( $t5{ success } == 1 , 'Execution should report success.' );
ok( $t5{ exit_code} == 0 , 'Should have a 0 exit code.' );
ok( $t5{ stdout } =~ m/iscsv 0/, 'Should spew icsv 0' ) ;
ok( $t5{ stdout } =~ m/trunc 0/, 'Should not truncate.' ) ;

open EXP, "<$tdata/exported.tsv" or die "Cant open $tdata/exported.tsv $!" ;
my $explinecnt = 0 ;
my $foundtkk = 0 ;
my $foundcockroach = 0 ;
while (<EXP>) { 
	if ( $_ =~ m/TKK/ ) { if  ( $_ =~ m/gutsy/ ) { $foundtkk++ } }
	if ( $_ =~ m/cockroach/ ) { if  ( $_ =~ m/excavated inadvertently/ ) { $foundcockroach++ } }	
	$explinecnt++ ;
	}
is( $foundtkk, 1, 'Should find TKK from the second file loaded in dump.' ) ;
is( $foundcockroach, 1, 'Should find cockroach from the first file loaded in dump.' ) ;	

done_testing() ;