#! /usr/bin/perl

package PGBCmd ;
{
use strict ;
#use warnings ;
use 5.012;
use Getopt::Long;
use Cwd ;
use Config::Std;
use Config::Any;
use strict ;
use Pg::BulkCopy ;


sub HelpMe {
	my $Msg = qq (
   Type "perldoc Pg::BulkCopy" or possibly "man Pg::BulkCopy" to get more 
   information about how to use pg_bulkcopy.pl.
)	;
	for (@_) { $Msg =  "$Msg\n *** $_ ***\n" } ; 
	die $Msg ;
	}

sub main {

my %options = () ;
my @optionkeys = qw /
	iscsv dump load dbistring dbiuser dbipass table workingdir tmpdir
	errorlog batchsize maxerrors debug trunc filename / ;
	
my $loadfile = 0 ; my $help = 0 ;	

unless ( @ARGV ) { HelpMe } ;


GetOptions (
	'file|filename|f=s' => \$options{filename} ,
	'table|t=s' => \$options{table},
	'load|l' => \$options{load} ,
	'dump|d' => \$options{dump} ,
	'iscsv|csv' => \$options{iscsv},	
	'dbistring|dbistr|ds=s' => \$options{dbistring},
	'dbiuser|dbiusr|du=s' => \$options{dbiuser},
	'dbipass|dp=s' => \$options{dbipass},
	'workingdir|working|w=s' => \$options{workingdir},
	'tmpdir|tmp=s' => \$options{tmpdir},
	'batchsize|batch|b=i' => \$options{batchsize},
	'errorlog|error|e=s' => \$options{errorlog},
	'maxerrors|errors|max=i' => \$options{maxerrors},
	'debug|dbg=i' => \$options{debug},
	'trunc|truncate|tr=s' => \$options{debug},
	'help|h|?' => \$help ,
	'read|r=s' => \$loadfile
	) ;
	
HelpMe if $help ;

# This condition is checked immediately after reading the command line in anticipation of a
# collision where the command line specifies dump and the parameters file says load, the
# the command line will prevail because the following code for reading the file does not
# update the hash when there is already a value there. By checking for dump first it takes
# precedence if both options are specified. If no switch is provided and the config file
# tries to set both load and dump, only dump is passed to the object and will prevail.
if ( $options{dump} ) {
	if ( $options{dump} > 0 ) { $options{load} = 0 }  }
else { $options{load} = 1 ; $options{dump} = 0  ; }

if ( $loadfile ) { 
	read_config $loadfile => %options;	
	say "Read Paramters from $loadfile" ; 
	my %optsfromfile = %{$options{options}} ;
	foreach my $optfromfile ( sort keys  %{$options{options}} ) { 
		# Places the value read in the outer hash only if a value
		# wasn't also read from the command line.
		if ( $options{ options }->{ $optfromfile } ) {
			 unless ( $options{ $optfromfile } ) 
				{ $options{ $optfromfile } = $options{ options }->{ $optfromfile } }
			}
		} ; 
	} ;

# In practice the way the values are set all need to be initialized in the script,
# even though in many cases it is to the default.

unless ( $options{ filename } ) 
	{ HelpMe( "No file for input or output has been specified." ) } ;
unless ( $options{ table } ) 
	{ HelpMe( "No table been specified." ) } ;
unless ( $options{ dbistring } ) 
	{  say "dbistring $options{ dbistring }" ;
		HelpMe( "No dbistring has been specified how can you connect? ." ) } ;
unless ( $options{ workingdir } ) { $options{ workingdir } = getcwd; } ;

unless ( $options{ errorlog } ) { 
	$options{ errorlog } = $options{ filename } . '.log' }
unless ( $options{ tmpdir } ) {
	say "A temporary Directory is not specified defaulting to /tmp on Linux
	or if Windows is supported as a platform in future C:\\Windows\\Temp" ;
	$options{ tmpdir } = '/tmp' ;
	}
unless ( $options{ debug } ) { $options{ debug } = 1 } ;
unless ( $options{ iscsv } ) { $options{ iscsv } = 0 } ;
unless ( $options{ batchsize } ) { $options{ batchsize } = 10000 } ;
unless ( $options{ maxerrors } ) { $options{ maxerrors  } = 10 } ;
unless ( $options{ trunc } ) { $options{ trunc } = 0 } ;	

say  "\n****\nBulkCopy Parameters are:\n" ;
for ( sort @optionkeys ) { say "$_ $options{$_} " } ; 	

my $BCP = Pg::BulkCopy->new( 
	table  		=> $options{ table } ,
	filename  	=> $options{ filename } ,
	dbistring  	=> $options{ dbistring } ,
	dbiuser  	=> $options{ dbiuser } ,
	dbipass  	=> $options{ dbipass } ,	
	errorlog  	=> $options{ errorlog } ,
	dump  		=> $options{ dump } ,
	icsv 		=> $options{ icsv } ,
	workingdir  	=> $options{ workingdir } , 
	tmpdir  	=> $options{ tmpdir } ,	
	batchsize  	=> $options{ batchsize } , 
	maxerrors  	=> $options{ maxerrors } ,
	debug  		=> $options{ debug } ,
#	trunc  		=> $options{ trunc } ,
	 );
	 
if ( $options{ dump }) { $options{ trunc } = 0 }  #never truncate on a dump.
if ( $options{ trunc } == 1 ) { $BCP->TRUNC() } 

if ( $options{ dump } ) { $BCP->DUMP() } else { $BCP->LOAD() }

print "Process ran, the return code is: " ;
say $BCP->errcode() ;  say $BCP->errstr() ;


} ; #main
} # PGBCmd
&PGBCmd::main( @ARGV ) unless caller() ;

1 ;
