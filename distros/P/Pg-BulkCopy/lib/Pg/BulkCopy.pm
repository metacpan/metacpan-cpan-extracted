use warnings;
use strict;
use Moose;
use 5.012 ;
use Time::Piece ;
use DBI ;
use File::Copy ;
use Log::Handler ;

=pod

=head1 NAME

Pg::BulkCopy - Deprecated use https://github.com/ossc-db/pg_bulkload/

=head1 VERSION

Version 0.22

=head1 Deprecated

Back in 2010 when I wrote Pg::BulkCopy I couldn't find a functional bulk load utility for Postgres.
At this time I think that pg_bulkload is a much better utility for this. 

I've written a short article on installing it at my personal blog 
L<techinfo.brainbuz.org/?p=429|http://techinfo.brainbuz.org/?p=429>, 
which will help you get started. 

=cut

package Pg::BulkCopy;
our $VERSION = '0.22' ;
use Moose ;
	has 'dbistring' => ( isa => 'Str', is => 'rw', required => 1, ) ;
	has 'filename' => ( isa => 'Str', is => 'rw', required => 1, ) ;	
	has 'table' => ( isa => 'Str', is => 'rw', required => 1, ) ; 
	has 'dbiuser' => ( isa => 'Str', is => 'rw', required => 0, ) ;
	has 'dbipass' => ( isa => 'Str', is => 'rw', required => 0, ) ;	
	has 'workingdir' => ( 
		isa => 'Str', 
		is => 'rw', 
		default => '/tmp/', 
		trigger => sub {
			my $self = shift ;
			unless ( $self->{'workingdir'} =~ m|/$| )
				{ $self->{'workingdir'} = $self->{'workingdir'} . '/' }
			} ,
		) ;
	
	has 'tmpdir' => ( isa => 'Str', is => 'rw', default => '/tmp/', 
			trigger => sub {
			my $self = shift ;
			unless ( $self->{'tmpdir'} =~ m|/$| )
				{ $self->{'tmpdir'} = $self->{'tmpdir'} . '/' }
			} ,	
		) ;
	has 'batchsize' => ( isa => 'Int', is => 'rw', default => 10000, ) ;
	has 'errorlog' => ( isa => 'Str', is => 'rw', default => 0, ) ;	
	# this makes the default to make empty strings null. set the value to none to have no nulls.
# *****************
#TODO look further into handling of nulls	
# *****************
	has 'null' => ( isa => 'Str', is => 'rw', default => "\'\'", ) ;
	has 'iscsv' => ( isa => 'Int', is => 'rw', default => 0, ) ; 
# This has to be stripped for batching and the headers fed to the column method, which also must be written.	
	has 'maxerrors' => ( isa => 'Int', is => 'rw', default => 10, 
		trigger => sub {
			my $self = shift ;
			if ( $self->{'maxerrors'} == 0 ) { $self->{'maxerrors'} = 99999 }
			} ,
		) ; 
	has 'debug' => ( isa => 'Int', is => 'rw', default => 1, ) ;
	has 'errcode' => ( isa => 'Int', is => 'ro', default => 0, ) ;
	has 'errstr' => ( isa => 'Str', is => 'ro', default => '' ) ;

sub BUILD { 
 	my $self = shift ; 
# Whether error log is omitted, only a file name given or a full path given --
#  Set a default if no error log is provided.
#  Append to the working directory if only a file name is provided.
#  Leave it alone if a path is provided.
# Once the location is known, it is opened as an append to file handle and stored in self->EFH. 	
 	if ( $self->{'errorlog'} eq '0' ) { $self->{'errorlog'} = $self->{'workingdir'} . 'pg_BulkCopy.ERR' } 
 	elsif ( $self->{'errorlog'} !~ m|\/| ) { $self->{'errorlog'} = $self->{'workingdir'} . $self->{'errorlog'} } ;	
 	unless ( $self->{'debug'} == 0 ) { 
# FileHandle is used to make the errorlog hot because the default lazy buffering behaviour is undesireable.
# The performance benefit of Lazy buffering should be trivial compared to the consequences having the log truncate
# prematurely if the program exits unexpectedly. It created problems during testing where tests needed access to the logs
# but the BulkCopy object had not been destroyed and had not flushed the buffer.
		open ( $self->{'EFH'} , '>>', $self->{'errorlog'} ) or die " can\'t open $self->{'errorlog'}\n"  ;
		select( $self->{'EFH'} );
		$| = 1;
	#	$self->{'EFH'} = FileHandle->new( ">>$self->{'errorlog'}" or die " can\'t open $self->{'errorlog'}\n" ) ;
	#	eval { $self->{'EFH'}->autoflush(1) } ; say "Autoflush @_\ n\n" ;
		}
 	my $t = localtime ;
 	$self->_DBG( 1, "Debug Logging to $self->{'errorlog'} $t" ) ;
    my @selfkeys = qw / dbistring dbiuser dbipass table filename workingdir tmpdir 
        errorlog batchsize null iscsv debug / ;
    my $detailed = "Pg::BulkCopy invoked with Parameters:\n" ;
    foreach my $s ( @selfkeys ) { $detailed = "$detailed $s $self->{$s}\n" }
    $self->_DBG( 2, $detailed ) ;	
	}
	
# debug levels 
#	0 Do not debug at all.
#	1 Standard Debug Messages.
#	2 All possible debug messages.
#	3+ Higher numbers are used for debuginng messages in development.

sub _DBG {
	my $self =shift ;
	my $level = shift  ;
	if (  $self->{'debug'} == 0 ) { return } 
	my $EFH = $self->{'EFH'} ;
	if ( $self->{'debug'} >= $level ) { 
		foreach my $w ( @_ ) { say STDERR $w ; say $EFH $w }
		}
	}
	
# Used by a calling program to cause the logging of an event.	
sub LOG { my $self =shift ; $self->_DBG( 1, @_ ); } ;	

sub CONN { 
	my $self =shift ;
	unless ( defined $self->{ 'CONN' } ) { 
		$self->{ 'CONN' } = DBI->connect( 
			$self->{ 'dbistring' } ,
			$self->{ 'dbiuser' } ,
			$self->{ 'dbipass' } ) or die "Error $DBI::err [$DBI::errstr]" ;
		}
	return $self->{ 'CONN' } ;	
	}

sub TRUNC {
	my $self =shift ;
	my $truncstr = 'TRUNCATE ' . $self->{'table'} . ' ;' ;
	my $conn = $self->CONN() ;
	$self->_DBG( 2, $truncstr ) ;
	my $DBH = $conn->prepare( $truncstr ) ;
	$DBH->execute ;
	if ( $DBH->err ) { return $DBH->errstr } 
	else { return 0 }
	}

sub _OPTIONSTR {
	my $self =shift ;
	my $optstr = '' ;
	if ( $self->{ 'iscsv' } ) { 
		$optstr = $optstr . 'CSV ' ; 
		if ( $self->{'csvheader'} ) { $optstr = $optstr . 'HEADER ' ; }		
		} ;
	
	unless ( $self->{'null'} eq 'none' ) { $optstr = $optstr . "NULL $self->{ 'null' } " ; } ;
	if ( length( $optstr ) > 1 ) { $optstr = 'WITH ' . $optstr . ';' ; }
	else  { $optstr = ';' } ; # Even with no opts will need to tack on trailing semicolon.
	$self->_DBG( 2, 'Optionstr: ', $optstr ) ;
	return $optstr ;	
	}

sub DUMP {
	my $self =shift ;
	our $returnstring = '' ;
	our $returnstatus = 1 ;	# Use 1 for successful and negative nos for failure.
	my $filename = $self->{ 'workingdir' } . $self->{ 'filename' } ;
	my $jobfile = $self->{ 'tmpdir' } . 'BULKCOPY.JOB' ;	
	my $conn = $self->CONN() ; #DBI->connect( $dbistr, $dbiuser, $dbipass ) or die "Error $DBI::err [$DBI::errstr]" ;
	my $opts = $self->_OPTIONSTR()  ;
	my $dumpstr = "COPY $self->{'table'} TO \'$jobfile\' $opts"  ; 
	$self->_DBG( 2, "Dump SQL", $dumpstr  );
	my $DBH = $conn->prepare( $dumpstr ) ;
	$DBH->execute ;
	if ( $DBH->err ) { 
		$returnstatus =  $DBH->err ; 
		$returnstring = "Database Error: " . $DBH->errstr ; 
		} else {
		use File::Copy ;
		copy( $jobfile, $filename ) ;
		unlink $jobfile ;
		}
	$self->{ 'errcode' } = $returnstatus ;
	$self->{ 'errstr' } = $returnstring ;	
	$self->_DBG( 1,
		"Executed DUMP: $dumpstr",
		"Return Status: $returnstatus [ 1 indicates no errors returned ]",
		$returnstring ) ;
	return ( $returnstatus ) ; 	
	} #DUMP
	
sub LOAD { 
	my $self =shift ;
	our $returnstring = '' ;
	our $returnstatus = 1 ;	# Use 1 for successful and negative nos for failure.
	my $ErrorCount = 0 ;
	my $fname = $self->{ 'workingdir' } . $self->{ 'filename' } ;
	my $jobfile = $self->{ 'tmpdir' } . 'BULKCOPY.JOB' ;
	my $rejectfile = $fname . '.REJECTS' ;	
	open my $REJECT, ">$rejectfile" or die "Can't open Reject File $rejectfile" ;
	my $opts = $self->_OPTIONSTR()  ;
	my $loadstr = "COPY $self->{'table'} FROM \'$jobfile\' $opts"  ; 
 	my $t = localtime ;
	$self->_DBG( 2, 
		"LOAD at $t",
		"LOAD Command $loadstr" ) ;	
	my $DoLOAD = sub { 
		my $conn = $self->CONN() ;
		my $DBH = $conn->prepare( $loadstr ) ;
		$DBH->execute ;
		if ( $DBH->err ) { 
			my $DBHE = $DBH->errstr ;
			# These chars might end up next to line or the numer we seek.
			# translate turns them to spaces so they don't interfere.
			$DBHE =~ tr/\:\,/  / ;
			$self->_DBG( 2, "DBI Error Encountered. Attempting to identify and reject bad record.\n", $DBHE ) ;
			my @ears = split /\s/, $DBHE  ;
			while ( @ears ) {
				my $ear = shift @ears;
					if ( $ear =~ m/line/i ) {
						$ear = shift @ears  ;
						if ( $ear =~ /^-?\d+$/ ) { 
							$self->_DBG( 2, "Identified Error Line",  $ear ) ;
							return $ear ; } 
						} # if ( $ear =~ m/line/i )
				} # while ( @ears ) 
				$self->_DBG( 1, "Cannot parse line number from \n||$DBHE||n") ;
				exit ;
			} # if ( $DBH->err )
		return 0 ;
		} ; #  $DoLOAD = sub
			
	my $ReWrite = sub {
		my $badline = shift ;
		if ( stat "$jobfile.OLD" ) { unlink "$jobfile.OLD" } ;
		use File::Copy ;
		move( $jobfile, "$jobfile.OLD" ) ;
		open OLD, "<$jobfile.OLD" ;
		open JOB, ">$jobfile" ;
		my $lncnt = 0 ;
		$self->_DBG( 2, "ReWrite is rewriting a job file." ) ;
		while (<OLD>) {
			$lncnt++ ;
			if ( $lncnt == $badline ) { print $REJECT $_ } 
			else { print JOB $_ }
			} ;
		close JOB ; 
		close OLD ;
		$self->_DBG( 2, "New Job File: $jobfile\n", "Old: $jobfile.OLD\n" ) ;
		# If debugging this keeps copies of the most recent jobfiles.		
			if ( $self->{'debug'} > 1) { `cat $jobfile > $jobfile.1` ; my $old = "$jobfile.OLD" ; `cat $old > $jobfile.2` }
		unlink "$jobfile.OLD" ;
		} ;
	open my $FH, "<$fname" or die "Unable to read $fname\n"  ;
	my $batchsize = $self->{ 'batchsize' } ;
	my $jobcount = 0 ;
	my $batchcount = 0 ;
	my $finished = 0 ;
	my $iterator = 1 ;
$self->_DBG( 3, "BatchCount $batchcount, Iterator $iterator") ;		
	until ( $finished == 1 ) {
		# This is normally desired spew, leave debug at 1, call with debug 0 to suppress.
		$self->_DBG( 1, "Processing Batch: $iterator" ) ;
		$batchcount = 0 ;
		open my $JOB, ">$jobfile" or die "Check Permissions on $self->{ 'tmpdir' } $!\n" ;
		while ( $batchcount < $batchsize ) {
$self->_DBG( 3, "BatchCount $batchcount, Iterator $iterator") ;			
			my $line = <$FH> ;
			print $JOB $line ; 
			if ( eof($FH) ) { 
				$batchcount = $batchsize ; 
				$finished = 1 ; 
				$self->_DBG( 2,  "Finished making batches" ) ; 
				} ;			
			$batchcount++ ; $jobcount++ ;
			}
		close $JOB ;
		my $batchcomplete = 0 ;
		until ( $batchcomplete ) {
			my $loaded  = $DoLOAD->() ;
			if ( $loaded == 0 ) { $batchcomplete = 1 ; $iterator++ ; }
			else {  
				$ErrorCount++ ;
				if ( $ErrorCount >= $self->{ 'maxerrors' } ) {
					unlink $jobfile ;
					$batchcomplete = 1 ;
					$returnstring = 
					"Max Errors $ErrorCount reached at $jobcount lines. See $self->{'errorlog'} and $rejectfile."  ;
$self->_DBG( 2, "Return string Set", $returnstring ) ;
					$returnstatus  = -1 ; 
					$finished = 1 ;
#					$self->TRUNC() ;
					}
				else { $ReWrite->( $loaded ) ; }
				} ; 
	
		} # until batchcomplete
	} #until finished
	unlink $jobfile ;
	$self->{ 'errcode' } = $returnstatus ;
$self->_DBG( 2, "Return Value: $returnstatus" ) ;
	$self->{ 'errstr' } = $returnstring ;	
	return ( $returnstatus ) ;
}	 #LOAD

=head1 IMPORTANT NOTE on INSTALLATION

If you are installing this through cpan please be aware that you will not be running any tests. 
The tests are in t2 and not run by any of the CPAN clients. To run the tests you need to download 
the test data L<http://www.cpan.org/authors/id/B/BR/BRAINBUZ/Pg-BulkCopyTest-0.16.tar.gz>. Pg::BulkCopy requires postgres to be installed on the same machine
although it uses dbi it requires a shared directory that postgres and it can both write to. If you 
do not want to setup and run the tests it is recommended that you at least perform a validation trial

=head1 pg bulkCopy.pl

The utility script pg_BulkCopy.pl was written to provide postgreSQL with a convient bulk loading utility. The script is implemented as a wrapper and a module (pg_BulkCopy.pl) so that other programmers may easily incorporate the two useful methods LOAD and DUMP directly into other perl scripts. 

The DUMP Method invokes postgres' COPY TO command, and does nothing useful in addition except copying the dump from the temp directory (because postgres may not have permission on where you want the file). You can choose Tab Delimited Text or CSV with whatever delimiter you want and a Null string of your choice.

The LOAD Method is much more interesting, it breaks the load file into chunks of 10000 (configurable) records in the temp directory and tries to COPY FROM, if it fails, it parses the error message for the line number, then it removes the failed line to a rejects file and tries again. As with DUMP you can select the options supported by the postgres COPY command, you can also set a limit on bad records (default is 10).

Command Line Arguments to script: 

	file|filename|f 
	table|t 
	load|l  
	dump|d  
	iscsv|csv
	dbistring|dbistr|ds
	dbiuser|dbiusr|du 
	dbipass|dp 
	workingdir|working|w 
	tmpdir|tmp 
	batchsize|batch|b 
	errorlog|error|e 
	maxerrors|errors|max 
	debug|dbg 
	trunc|truncate|tr 
	help|h|? 
	read|r [to read additional variables out of a file]
	
Format of a Parameter file (specified with --read):

	[options]
	filename : blob1.tsv
	load : 1
	dump :
	iscsv :
	dbistring : DBI:Pg:dbname=pg_bulkcopy_test;host=127.0.0.1
	dbiuser : postgres
	dbipass : postgres
	table : testing
	workingdir : /psql_scr/testing/tdata/
	tmpdir : /psql_scr/testing/tmp/
	batchsize :
	errorlog : 
	maxerrors : 50
	debug : 2
	trunc : 1

Example command line

	pg_bulkcopy.pl --filename more1.tsv --iscsv 0 --dbistring "DBI:Pg:dbname=pg_bulkcopy_test;host=127.0.0.1" --dbiuser postgres --dbipass postgres --table testing --workingdir /tempdata --tmpdir /mytempfiles --debug 1

Command Line to load all values from bulkcopy.conf

	pg_bulkcopy.pl --read "bulkcopy.conf"

Command Line to load values from bulkcopy.conf but provide or override some values from the command line. Values given on the command line take precedence over conflicting values read from file.

	pg_bulkcopy.pl --read "bulkcopy.conf" --dbistring "DBI:Pg:dbname=pg_bulkcopy_test;host=127.0.0.1" --dbiuser postgres --dbipass postgres 
	
=head2 Description of Command Line Parameters

=head3 dbistr, dbiuser, dbipass

These are the parameters needed to establish a dbi connection. 

=head3 filename, table

B<filename> is a tab or comma seperated values text file containing the data to be imported or exported. B<table> indicates the table in the connected database to be used for the operation.

=head3 iscsv, load and dump, trunc

Boolean values of 0 or 1. An B<iscsv> value of 1 indicates the file is csv. The default B<iscsv> value of 0 indicates tab seperated. The default operation is B<load> (load = 1), setting B<dump> to 1 will set load to 0 and cause the program to dump instead. trunc causes an explicit truncation (deletion) of all data in the table prior to the requested operation (not useful with dump).

=head3 workingdir, tempdir, errorlog

B<workingdir> is where the file, reject and log files will be written, unless the full path/filename is specified it is also expected to find/write the file for the operation here. B<errorlog> is the name of a file to write information about problems to, this will default to <filename>.log. 

B<tempdir> where the temporary working files will be written to. tempdir defaults to /tmp. Do not overlook tempdir, the user executing the script and the uid that postgres is running under must have rw permissions here and the default creation mask must permit access to each other's newly created files! 

=head3 batchsize, maxerrors, debug

B<batchsize> controls the size of the chunks used for loading, the default is 10,000. With clean data a larger batch size will spead processing, with dirty data smaller batches will improve performance. Every time an error is encountered the offending record needs to be eliminated from the batch, which is currently done inneficiently by re-writing the file. 

B<maxerrors> tells the program to abort if too many errors are found. The default is 10.

B<debug> can disable or increase the amount of error logging done. 0 disables error logging, normal is 1. 


=head1 Module Pg::BulkCopy 

All methods used by pg_BulkCopy.pl are provided by Pg::BulkCopy. The method names follow the convention of explicitely defined methods in caps and methods created by Moose in lowercase.

=head2 Systems Supported

This utility is specific to postgreSQL. It is a console application for the server itself. The postgres process must be able to access the data files through the local file system on the server. The utility is targeted towards recent versions of postgres running on unix-like operating systems, if you need to run it on Windows good luck and let me know if you succeed!

=head1 Using Pg::BulkCopy

 my  $PGBCP = Pg::BulkCopy->new(
 dbistring  => $dbistr,
 dbiuser    => $dbiuser,
 dbipass    => $dbipass,
 table      => $table,	
 filename   => $filename,
 workingdir => "$tdata/",
 iscsv      => 1,
 maxerrors  => 10,
 errorlog   => 'myload.log', 
 );

The above example shows the creation of a new BulkCopy object. It requires the dbi information and the name of a table. workingdir will default to /tmp, and filename is required. The default behaviour is Tab Seperated so iscsv is only required for a csv import, icsv => 0 will explicitely request tsv. errorlog is defaulted to $workingdir/pg_BulkCopy.ERR and can be safely omitted. To disable all logging set debug => 0, to log everything set it to 2. maxerrers defaults to 10, setting 0 changes it to an arbitrary large number. All properties have a getter $PGBCP->dbistring() will tell you what the string is, while this property is Read Only, most properties are also a setter to change the value without creating a new object. 

The methods DUMP, TRUNC, and LOAD do most of the work. You can use errcode and errstr to findout about the results. 

The tests in the distributions t2 folder can be referred to for additional examples.


=head1 Methods for Pg::BulkCopy

=head2 CONN

Returns the dbi connection, initializing it if necessary. 

=head2 TRUNC

If the Trunc option is specified, delete all records from table with the postgres TRUNCATE command, instead of carrying out a LOAD or DUMP operation. 

=cut

=head2 LOAD

The main subroutine for importing bulk data into postgres.

=cut

=head2 DUMP

The main subroutine for exporting bulk data into postgres.

=head2 LOG

Write to the log file being used by Pg::BulkCopy. Takes a scalar value or an array, items in an array are written on seperate lines. Remember that if debug is 0 nothing will ever be logged.


=head2 maxerrors

Gets or sets the maximum errors in a job. Setting 0 actually sets an arbitrary large number instead. The default is 10

=head2 batchsize

Gets or sets the batch size. If there are few errors in the source a large batch size is appropriate, if there are many errors a smaller batch will speed processing. The default is 10000.

=head2 errcode, errstr

Returns the last error in numeric or string form. Generally this is just passed back from dbi.

=head2 iscsv

Toggle between Command Tab seperated input. The default is tab seperated, 0. 

=head2 workingdir, tempdir, and filename

The workingdir is where Pg::BulkCopy will look for the data file and where it will write any reject or log files. The tempdir is a scratch directory which both the script user and the postgres user have read write access. The default of both workingdir and tempdir is /tmp. Finally a file name for input or output is needed. 

=head2 Private subroutines

=head3 BUILD 

Is a moose component, it is run "after new".

=head3 _DBG 

is used internally for outputting to stderr and the log file.

=cut

=head1 Troubleshooting and Issues:

=head2 Permissions 

The most persistent problem in getting Pg::BulkCopy to work correctly is permissions. First one must deal with hba.conf. Then once you are able to connect as the script user to psql and through a dbi connection you must deal with the additional issue that you are probably not running the script as the account postgres runs under. The account executing the script must be able to read and execute the script directories, read and write the working directory and the temp directory. Finally the account running the Postgres server must be able to read and write in the temp directory (which is defaulted to /tmp). 

To deal proactively with permissions issues I recommend the following steps. Check umask in /etc/profile, and change it to something like 002 (which gives owner and group read/write other read). Create a group containing the users of the script and the postgres user. On the directory where you are running the scripts, the temp directory and the one containing data use chmod to set the Special bit (chmod g+s). Make sure that the directory and any pre-existing files have the correct group set. Touch a file as a user in the group and confirm that the group is set to the group and not the user. Other options are to use the ACL feature to manage permissions or to try running the script as the postgres user. 

=head2 Other Issues

There is currently an issue I haven't resolved with a quoted csv input test file. The next features I expect to work on involve supporting csv headers and field reordering, which will also make the feature available for tsv files. 

=head1 Options

=head2 No CSV Headers

CSV Headers are not supported yet, you'll need to chop them off yourself. Field reordering also isn't supported. These features will be reconsidered for later versions. 

=head1 Testing

To properly test the module and script it is necessary to have an available configured database. So that the bundle can be installed silently through a cpan utility session very few tests are run during installation. Proper testing must be done manually. Due to the size of the test data it has been removed to a seperate archive, Pg-BulkCopyTest which must be downloaded seperately from cpan. Normally the contents would be restored to the tdata directory.  

=head2 Create and connect to the database

First make sure that the account you are using for testing has sufficient rights on the server. The sql directory contains a few useful scripts for creating a test database. On linux a command like this should be able to create the database: 
C<psql postgres > E<lt> C<create_test.sql>. C<dbitest.pl> adds a row to your new database and then deletes it, use dbitest to verify your dbi string and that it can access the database.

=head2 The real tests are in t2.

Edit the file t2/test.conf. You will need to provide the necessary dsn values for the dbi connection.

If necessary modify harness.sh from the distribution directory as appropriate and execute it to run the tests.

=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pg-bulkcopy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pg-BulkCopy>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::BulkCopy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pg-BulkCopy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pg-BulkCopy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pg-BulkCopy>

=item * Search CPAN

L<http://search.cpan.org/dist/Pg-BulkCopy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010,2012 John Karr.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of Pg::BulkCopy
