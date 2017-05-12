# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
sub writeTestScript(@)
{
	my ($line) = @_;

	# write the test script to ./_TST_
	unlink '_TST_';
	open FH, '> _TST_';
	print FH $line . "\n";
	close \*FH;
}

sub readSTDOUTfile()
{
	return undef if( ! -f '/tmp/_tst_STDOUT' );
	open FH, '/tmp/_tst_STDOUT' || return undef;
	my @SO = <FH>;
	return \@SO;
}

sub readSTDERRfile()
{
	return undef if( ! -f '/tmp/_tst_STDERR' );
	open FH, '/tmp/_tst_STDERR' || return undef;
	my @SE = <FH>;
	return \@SE;
}

sub readLOGfile()
{
	return undef if( ! -f '/tmp/_TST_.log' );
	open FH, '/tmp/_TST_.log' || return undef;
	my @SE = <FH>;
	return \@SE;
}

sub getResults($)
{
	my ($opt) = @_;

	my $stdout = readSTDOUTfile();
	my $stderr = readSTDERRfile();
	my $logfile= readLOGfile();

	return $stdout, $stderr, $logfile;
}

sub mkTST(@)
{
	my ($line, $opt) = @_;
	
	writeTestScript($line);

	# clean up
	system( "rm -f /tmp/_TST_*.log /tmp/_tst_*.log" );
	# run test
	$opt = defined $opt ? $opt : '';
    my $perlexe = $^X;
	my $rc = system( "$perlexe  _TST_ $opt >/tmp/_tst_STDOUT 2>/tmp/_tst_STDERR" );

	return $rc/256, getResults($opt);
}
#########################


# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 18 };
use Script::Toolbox	qw(:all);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#1-4
# PRINT TO STDERR (default channel)
#  STDOUT: empty
#  STDERR: "_TST_: Thu Aug 26 11:25:27 2004: logtest"
# LOGFILE: undefined 
    ($rc, $sout, $serr, $logf) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); Log("logtest");) );
    is( $rc, 0, 'Log' );
    ok( $#{$sout} == -1, 'Log' );
    ok( !defined $logf, 'Log');
    like( $serr->[0], qr/^_TST_: [A-z]{3} [A-z]{3} +\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: logtest/, 'Log' );




#5-8
# PRINT TO STDOUT
#  STDOUT: "_TST_: Thu Aug 26 11:25:27 2004: logtest"
#  STDERR: empty
# LOGFILE: undefined 
    ($rc, $sout, $serr, $logf) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); Log("logtest", 'STDOUT');) );
    is( $rc, 0, 'Log' );
    ok( $#{$serr} == -1, 'Log' );
    ok( !defined $logf, 'Log');
    like( $sout->[0], qr/^_TST_: [A-z]{3} [A-z]{3} +\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: logtest/, 'Log' );

#9-14
# PRINT TO file
#  STDOUT: empty
#  STDERR: empty
# LOGFILE: undefined
# /tmp/logfile: "_TST_: Thu Aug 26 11:25:27 2004: logtest"
    ($rc, $sout, $serr, $logf) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); Log("logtest", '/tmp/logfile');) );
    is( $rc, 0, 'Log' );
    ok( $#{$serr} == -1, 'Log' );
    ok( $#{$sout} == -1, 'Log' );
    ok( !defined $logf, 'Log');
    ok( -r '/tmp/logfile', 'Log');
    		open( FH ,'/tmp/logfile' );@x = <FH>;
    like( $x[0], qr/^_TST_: [A-z]{3} [A-z]{3} +\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: logtest/, 'Log' );
    		unlink ( '/tmp/logfile');


#15-18
# PRINT TO default logfile
#  STDOUT: empty
#  STDERR: empty
# LOGFILE: "_TST_: Thu Aug 26 11:25:27 2004: logtest"
# /tmp/logfile: "_TST_: Thu Aug 26 11:25:27 2004: logtest"
    ($rc, $sout, $serr, $logf) = mkTST(q(use Script::Toolbox qw(:all);
    					 Script::Toolbox->new({'logdir'=>{'mod'=>'=s','desc'=>'Base directory for logging.','mand'=>0,}}); 					       Log("logtest");
				       ),
				       '-logdir /tmp' );
    is( $rc, 0, 'Log' );
    ok( $#{$serr} == -1, 'Log' );
    ok( $#{$sout} == -1, 'Log' );
    like( $logf->[0], qr/^_TST_: [A-z]{3} [A-z]{3} +\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: logtest/, 'Log' );


unlink "/tmp/_tst_STDOUT";
unlink "/tmp/_tst_STDERR";
