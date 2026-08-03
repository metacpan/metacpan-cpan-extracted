#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;
use lib './t';
use MockProcessTable 'mock_process_table';

BEGIN {
    use_ok( 'Net::Connection::Match::Command' ) || print "Bail out!\n";
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
					  };

my %args=(
		  commands=>[
					 '^/usr/sbin/sshd',
					 'irssi',
					],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::Command->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we error when commands is not a array
$worked=0;
eval{
	$checker=Net::Connection::Match::Command->new( { commands=>'/usr/sbin/sshd' } );
	$worked=1;
};
ok( $worked eq '0', 'non-array init check') or diag('Calling new with a non-array commands key worked');

# makes sure we error when commands is a empty array
$worked=0;
eval{
	$checker=Net::Connection::Match::Command->new( { commands=>[] } );
	$worked=1;
};
ok( $worked eq '0', 'empty array init check') or diag('Calling new with a empty commands array worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::Command->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::Command->new resulted in... '.$@);

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

# matches the first regex in the array
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'command match check') or diag('Failed to match a matching command');

# matches the second regex in the array
$connection_args->{proc}='/usr/local/bin/irssi';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'second command match check') or diag('Failed to match against the second regex in the array');

# the anchored regex should not match a command it merely appears in
$connection_args->{proc}='/usr/local/bin/sudo /usr/sbin/sshd -D';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'anchored regex check') or diag('A anchored regex matched somewhere other than the start');

# make sure a non-matching command does not match
$connection_args->{proc}='/bin/cat /tmp/foo';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'command non-match check') or diag('Matched a command that it should not of');

#
# the process table lookup used when the connection has no proc set
#

mock_process_table(
				   {
					pid=>1234,
					cmndline=>'/usr/sbin/sshd -D',
					},
				   {
					pid=>1235,
					cmndline=>'',
					fname=>'kernel',
					},
				   );

my %procless_args=%{ $connection_args };
delete $procless_args{proc};
$procless_args{pid}=1234;

# the command should be pulled from the process table
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'process table lookup check') or diag('Failed to match a command found via the process table');

# kernel processes have a empty command line and are matched on the fname
$procless_args{pid}=1235;
$conn=Net::Connection->new( \%procless_args );
$returned=0;
eval{
	my $kernel_checker=Net::Connection::Match::Command->new( { commands=>[ '^\[kernel\]$' ] } );
	$returned=$kernel_checker->match( $conn );
};
ok( $returned eq '1', 'kernel process check') or diag('Failed to match a kernel process by its fname');

# a PID that is not in the process table can not match
$procless_args{pid}=4321;
$conn=Net::Connection->new( \%procless_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'missing from process table check') or diag('Matched a PID that is not in the process table');

done_testing(15);
