#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match::All' ) || print "Bail out!\n";
}

my $connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'22',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'ESTABLISHED',
					  };
my $checker;

# makes sure we can init, which takes no args
my $worked=0;
eval{
	$checker=Net::Connection::Match::All->new;
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::All->new resulted in... '.$@);

# make sure passing args to new is harmless
$worked=0;
eval{
	$checker=Net::Connection::Match::All->new( { foo=>'bar' } );
	$worked=1;
};
ok( $worked eq '1', 'init with args check') or diag('Calling new with a arg hash resulted in... '.$@);

# a connection should always match
my $conn=Net::Connection->new( $connection_args );
my $returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'match check') or diag('Failed to match a connection');

# a differing connection should also match
$connection_args->{state}='LISTEN';
$connection_args->{proto}='udp6';
$conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'differing connection match check') or diag('Failed to match a differing connection');

# undef matches as well, as it matches everything
$returned=0;
eval{
	$returned=$checker->match;
};
ok( $returned eq '1', 'match undef check') or diag('match did not return 1 for undefined input');

done_testing(6);
