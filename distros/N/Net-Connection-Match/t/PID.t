#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match::PID' ) || print "Bail out!\n";
}

my $connection_args={
					 foreign_host=>'10.0.0.1',
					 foreign_port=>'22',
					 local_host=>'10.0.0.2',
					 local_port=>'12322',
					 proto=>'tcp4',
					 state=>'LISTEN',
					 pid=>0,
					 };

my %args=(
		  pids=>[
				 '0',
				 '>1000',
				 ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::PID->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PID->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::PID->new resulted in... '.$@);

# make sure it will not accept null input
my $returned=1;
eval{
	$returned=$checker->match;
};
ok( $returned eq '0', 'undef match check') or diag('match accepted undefined input');

# make sure it will not accept a improper ref type
$returned=1;
eval{
	$returned=$checker->match($checker);
};
ok( $returned eq '0', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# Create a connection with a matching pid and see if it matches
my $conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'pid match check') or diag('Failed to match a matching good pid');

# Create a connection with a matching pid greater than 1000 protocol and make sure it does not match
$connection_args->{pid}='1001';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'pid match check 2') or diag('Failed to match a good pid');

# Create a connection with a matching pid greater than 1000 protocol and make sure it does not match
$connection_args->{pid}='900';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'pid non-match check') or diag('Matched a pid that it should not of');

done_testing(8);
