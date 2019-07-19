#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match::CIDR' ) || print "Bail out!\n";
}

my $connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'22',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'ESTABLISHED',
					  };

my %bad_args=(
		  cidrs=>[
				  '10.0.0.0/33'
				  ],
		  );

my %args=(
		  cidrs=>[
				  '127.0.0.0/24',
				  '192.168.0.0/16',
				  '10.0.0.0/8'
				  ],
		  );
my $cidr_checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$cidr_checker=Net::Connection::Match::CIDR->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we can init with good args
$worked=0;
eval{
	$cidr_checker=Net::Connection::Match::CIDR->new( \%bad_args );
	$worked=1;
};
ok( $worked eq '0', 'bad CIDR init check') or diag('new accepts invalid CIDRs');

# makes sure we can init with good args
$worked=0;
eval{
	$cidr_checker=Net::Connection::Match::CIDR->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::CIDR->new resulted in... '.$@);

# make sure it will not accept null input
my $returned=1;
eval{
	$returned=$cidr_checker->match;
};
ok( $returned eq '0', 'match undef check') or diag('match accepted undefined input');

# make sure it will not accept a improper ref type
$returned=1;
eval{
	$returned=$cidr_checker->match($cidr_checker);
};
ok( $returned eq '0', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# Create a connection with a matching CIDR and see if it matches
my $conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$cidr_checker->match( $conn );
};
ok( $returned eq '1', 'CIDR match check') or diag('Failed to match a matching good CIDR');

# Create a connection with a non-matching CIDR and make sure it does not match
$connection_args->{foreign_host}='1.1.1.1';
$connection_args->{local_host}='1.1.1.2';
$conn=Net::Connection->new( $connection_args );
$returned=1;
eval{
	$returned=$cidr_checker->match( $conn );
};
ok( $returned eq '0', 'CIDR non-match check') or diag('Matched a CIDR that it should not of');

done_testing(8);
