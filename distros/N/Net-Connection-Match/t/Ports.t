#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match::Ports' ) || print "Bail out!\n";
}

my $connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'22',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'LISTEN',
					  };

my %args=(
		  ports=>[
				   '22',
				  ],
		  lports=>[
				  '53',
				   ],
		  fports=>[
				   '12345',
				   ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::Ports->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match::Ports->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::Ports->new resulted in... '.$@);

# make sure it will not accept null input
my $returned=1;
eval{
	$returned=$checker->match;
};
ok( $returned eq '0', 'ports undef check') or diag('match accepted undefined input');

# make sure it will not accept a improper ref type
$returned=1;
eval{
	$returned=$checker->match($checker);
};
ok( $returned eq '0', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# Create a connection with a matching general port and see if it matches
my $conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'port match check') or diag('General port match failed');

# Create a connection with a matching local port and see if it matches
$connection_args->{local_port}='53';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'local port match check') or diag('Failed to matching local port');

# Create a connection with a matching local port and see if it matches
$connection_args->{local_port}='80';
$connection_args->{foreign_port}='12345';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'foreign port match check') or diag('Failed to matching foreign port');

done_testing(8);
