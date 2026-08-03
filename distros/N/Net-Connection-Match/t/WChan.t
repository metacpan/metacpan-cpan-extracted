#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;
use lib './t';
use MockProcessTable 'mock_process_table';

BEGIN {
    use_ok( 'Net::Connection::Match::WChan' ) || print "Bail out!\n";
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
					  wchan=>'kqread',
					  };

my %args=(
		  wchans=>[
				   '^kqread$',
				   'select',
				  ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::WChan->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we error when wchans is not a array
$worked=0;
eval{
	$checker=Net::Connection::Match::WChan->new( { wchans=>'kqread' } );
	$worked=1;
};
ok( $worked eq '0', 'non-array init check') or diag('Calling new with a non-array wchans key worked');

# makes sure we error when wchans is a empty array
$worked=0;
eval{
	$checker=Net::Connection::Match::WChan->new( { wchans=>[] } );
	$worked=1;
};
ok( $worked eq '0', 'empty array init check') or diag('Calling new with a empty wchans array worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::WChan->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::WChan->new resulted in... '.$@);

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

# a connection without a wchan can not match
my %wchanless_args=%{ $connection_args };
delete $wchanless_args{wchan};
$conn=Net::Connection->new( \%wchanless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'no wchan check') or diag('Matched a connection lacking a wchan');

# matches the first regex in the array
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'wchan match check') or diag('Failed to match a matching wchan');

# matches the second regex in the array
$connection_args->{wchan}='select';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'second wchan match check') or diag('Failed to match against the second regex in the array');

# the anchored regex should not match a wchan it is merely a substring of
$connection_args->{wchan}='kqreadx';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'anchored regex check') or diag('A anchored regex matched more than it should of');

# make sure a non-matching wchan does not match
$connection_args->{wchan}='nanslp';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'wchan non-match check') or diag('Matched a wchan that it should not of');

#
# the process table lookup used when the connection has no proc set
#

mock_process_table(
				   {
					pid=>1234,
					cmndline=>'/usr/sbin/sshd -D',
					wchan=>'kqread',
					},
				   );

my %procless_args=%{ $connection_args };
delete $procless_args{proc};
delete $procless_args{wchan};
$procless_args{pid}=1234;

# the wchan should be pulled from the process table
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'process table lookup check') or diag('Failed to match a wchan found via the process table');

# a PID that is not in the process table can not match
$procless_args{pid}=4321;
$conn=Net::Connection->new( \%procless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'missing from process table check') or diag('Matched a PID that is not in the process table');

done_testing(15);
