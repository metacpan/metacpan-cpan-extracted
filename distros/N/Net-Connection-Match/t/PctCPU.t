#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;
use lib './t';
use MockProcessTable 'mock_process_table';

BEGIN {
    use_ok( 'Net::Connection::Match::PctCPU' ) || print "Bail out!\n";
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
					  pctcpu=>'10.5',
					  };

my %args=(
		  pctcpus=>[
					'>1',
				   ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we error when pctcpus is not a array
$worked=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>'>1' } );
	$worked=1;
};
ok( $worked eq '0', 'non-array init check') or diag('Calling new with a non-array pctcpus key worked');

# makes sure we error when pctcpus is a empty array
$worked=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[] } );
	$worked=1;
};
ok( $worked eq '0', 'empty array init check') or diag('Calling new with a empty pctcpus array worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::PctCPU->new resulted in... '.$@);

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

# a connection without a pctcpu can not match
my %pctcpuless_args=%{ $connection_args };
delete $pctcpuless_args{pctcpu};
$conn=Net::Connection->new( \%pctcpuless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'no pctcpu check') or diag('Matched a connection lacking a pctcpu');

# each of the equalities checked against a pctcpu of 10.5
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
		my $equality_checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ $value ] } );
		$returned=$equality_checker->match( $conn );
	};
	ok( ( defined( $returned ) && ( $returned eq $expected ) ), $description.' check, "'.$value.'"' )
		or diag('"'.$value.'" against a pctcpu of 10.5 did not return '.$expected);
}

# make sure any value in the array may match, not just the first
$returned=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '>90', '<20', '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'multiple value match check') or diag('Failed to match on a value other than the first');

# make sure a array in which nothing matches does not match
$returned=1;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '>90', '<1', '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'multiple value non-match check') or diag('Matched a array in which nothing should of matched');

# non-numeric values, such as those some platforms return, are treated as zero
$connection_args->{pctcpu}='nan';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'non-numeric pctcpu check') or diag('A non-numeric pctcpu was not treated as zero');

#
# the process table lookup used when the connection has no proc set
#

mock_process_table(
				   {
					pid=>1234,
					cmndline=>'/usr/sbin/sshd -D',
					pctcpu=>'10.5',
					},
				   );

my %procless_args=%{ $connection_args };
delete $procless_args{proc};
delete $procless_args{pctcpu};
$procless_args{pid}=1234;

# the pctcpu should be pulled from the process table
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '>10' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'process table lookup check') or diag('Failed to match a pctcpu found via the process table');

# and it should still be compared properly
$returned=1;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '>11' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'process table lookup non-match check') or diag('Matched a pctcpu found via the process table that it should not of');

# a PID that is not in the process table can not match
$procless_args{pid}=4321;
$conn=Net::Connection->new( \%procless_args );
$returned=1;
eval{
	$checker=Net::Connection::Match::PctCPU->new( { pctcpus=>[ '>0' ] } );
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'missing from process table check') or diag('Matched a PID that is not in the process table');

done_testing( 15 + scalar( @equality_checks ) );
