#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;
use POSIX ();
use lib './t';
use MockProcessTable 'mock_process_table';

# physmem may fall back on running sysctl, so make the environment taint safe
delete @ENV{ 'PATH', 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

BEGIN {
    use_ok( 'Net::Connection::Match::PctMem' ) || print "Bail out!\n";
}

# proc is always set below so the process table is never consulted
my $connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'22',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'ESTABLISHED',
					  pid=>1,
					  proc=>'/usr/sbin/sshd -D',
					  pctmem=>'10.5',
					  };

my %args=(
		  pctmems=>[
					'>1',
				   ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::PctMem->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we error when pctmems is not a array
$worked=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>'>1' } );
	$worked=1;
};
ok( $worked eq '0', 'non-array init check') or diag('Calling new with a non-array pctmems key worked');

# makes sure we error when pctmems is a empty array
$worked=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[] } );
	$worked=1;
};
ok( $worked eq '0', 'empty array init check') or diag('Calling new with a empty pctmems array worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::PctMem->new resulted in... '.$@);

# make sure it will not accept null input
my $returned=1;
eval{
	$returned=$checker->match;
};
ok( $returned eq '0', 'match undef check') or diag('match accepted undefined input');

# make sure it will not accept a improper ref type
$returned=1;
eval{
	$returned=$checker->match($checker);
};
ok( $returned eq '0', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# a connection without a PID can never match
my %pidless_args=%{ $connection_args };
delete $pidless_args{pid};
my $conn=Net::Connection->new( \%pidless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'no PID check') or diag('Matched a connection lacking a PID');

# a connection without a pctmem can not match
my %pctmemless_args=%{ $connection_args };
delete $pctmemless_args{pctmem};
$conn=Net::Connection->new( \%pctmemless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'no pctmem check') or diag('Matched a connection lacking a pctmem');

# each of the equalities checked against a pctmem of 10.5
my @equality_checks=(
					 [ '10.5',   1, 'exact' ],
					 [ '10.6',   0, 'exact non-matching' ],
					 [ '>10',    1, 'greater than' ],
					 [ '>10.5',  0, 'greater than, equal value' ],
					 [ '>11',    0, 'greater than, larger value' ],
					 [ '>=10.5', 1, 'greater than or equal to, equal value' ],
					 [ '>=10',   1, 'greater than or equal to' ],
					 [ '>=11',   0, 'greater than or equal to, larger value' ],
					 [ '<11',    1, 'less than' ],
					 [ '<10.5',  0, 'less than, equal value' ],
					 [ '<10',    0, 'less than, smaller value' ],
					 [ '<=10.5', 1, 'less than or equal to, equal value' ],
					 [ '<=11',   1, 'less than or equal to' ],
					 [ '<=10',   0, 'less than or equal to, smaller value' ],
					 );

$conn=Net::Connection->new( $connection_args );
foreach my $equality_check ( @equality_checks ){
	my ( $value, $expected, $description )=@{ $equality_check };

	$returned=undef;
	eval{
		my $equality_checker=Net::Connection::Match::PctMem->new( { pctmems=>[ $value ] } );
		$returned=$equality_checker->match( $conn );
	};
	ok( ( defined( $returned ) && ( $returned eq $expected ) ), $description.' check, "'.$value.'"' )
		or diag('"'.$value.'" against a pctmem of 10.5 did not return '.$expected);
}

# make sure any value in the array may match, not just the first
$returned=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '>90', '<20', '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'multiple value match check') or diag('Failed to match on a value other than the first');

# make sure a array in which nothing matches does not match
$returned=1;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '>90', '<1', '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'multiple value non-match check') or diag('Matched a array in which nothing should of matched');

# non-numeric values, such as those some platforms return, are treated as zero
$connection_args->{pctmem}='nan';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'non-numeric pctmem check') or diag('A non-numeric pctmem was not treated as zero');

#
# the helpers used when the process table does not provide pctmem
#

$checker=Net::Connection::Match::PctMem->new( \%args );

# physmem is not available everywhere, but when it is it must be a sane size
my $physmem;
eval{
	$physmem=$checker->physmem;
};
ok( ( ( !defined( $physmem ) ) || ( ( $physmem =~ /^[0-9]+$/ ) && ( $physmem > 0 ) ) ), 'physmem check')
	or diag('physmem returned a value that is not a positive integer... '.$physmem);

# make sure repeated calls are consistent, as the value is cached
my $physmem_again;
eval{
	$physmem_again=$checker->physmem;
};
ok( ( ( !defined( $physmem ) && !defined( $physmem_again ) )
	  || ( defined( $physmem_again ) && ( $physmem_again eq $physmem ) ) ), 'physmem caching check')
	or diag('A second call to physmem returned a differing value');

# a undefined proc can not be computed
my $computed=0;
eval{
	$computed=$checker->pctmem_compute;
};
ok( !defined( $computed ), 'pctmem_compute undef check') or diag('pctmem_compute returned a value for a undefined proc');

# neither can a proc lacking both rss and rssize
$computed=0;
eval{
	$computed=$checker->pctmem_compute( {} );
};
ok( !defined( $computed ), 'pctmem_compute sizeless proc check') or diag('pctmem_compute returned a value for a proc lacking rss and rssize');

# a proc with a rss should compute to a percentage, assuming physmem is known
$computed=undef;
eval{
	$computed=$checker->pctmem_compute( { rss=>1024 } );
};
ok( ( ( !defined( $physmem ) && !defined( $computed ) )
	  || ( defined( $computed ) && ( $computed > 0 ) && ( $computed <= 100 ) ) ), 'pctmem_compute rss check')
	or diag('pctmem_compute did not return a sane percentage for a proc with a rss');

#
# the process table lookup used when the connection has no proc set
#

my $pagesize;
eval{
	$pagesize=POSIX::sysconf( POSIX::_SC_PAGESIZE() );
};

mock_process_table(
				   {
					pid=>1234,
					cmndline=>'/usr/sbin/sshd -D',
					pctmem=>'10.5',
					},
				   {
					# lacks pctmem, so it must be computed from rss
					pid=>1235,
					cmndline=>'/usr/sbin/sshd -D',
					rss=>100,
					},
				   {
					# lacks both pctmem and rss, so rssize is used
					pid=>1236,
					cmndline=>'/usr/sbin/sshd -D',
					rssize=>100,
					},
				   );

my %procless_args=%{ $connection_args };
delete $procless_args{proc};
delete $procless_args{pctmem};
$procless_args{pid}=1234;

# the pctmem should be pulled from the process table
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '>10' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'process table lookup check') or diag('Failed to match a pctmem found via the process table');

# and it should still be compared properly
$returned=1;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '>11' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'process table lookup non-match check') or diag('Matched a pctmem found via the process table that it should not of');

# a rss of 100 against a physmem of 1000 is 10 percent
$procless_args{pid}=1235;
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '10' ] } );
	# seed the physmem cache so the computed value is not machine dependent
	$checker->{physmem_checked}=1;
	$checker->{physmem}=1000;
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'rss computed pctmem check') or diag('A pctmem computed from rss was not 10 percent as expected');

# rssize is in pages, so a rssize of 100 against a physmem of 1000 pages is also 10 percent
$procless_args{pid}=1236;
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '10' ] } );
	$checker->{physmem_checked}=1;
	$checker->{physmem}=1000 * ( $pagesize ? $pagesize : 1 );
	$returned=$checker->match( $conn );
};
ok( $returned eq ( $pagesize ? '1' : '0' ), 'rssize computed pctmem check')
	or diag('A pctmem computed from rssize was not 10 percent as expected');

# a PID that is not in the process table can not match
$procless_args{pid}=4321;
$conn=Net::Connection->new( \%procless_args );
$returned=1;
eval{
	$checker=Net::Connection::Match::PctMem->new( { pctmems=>[ '>0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'missing from process table check') or diag('Matched a PID that is not in the process table');

done_testing( 22 + scalar( @equality_checks ) );
