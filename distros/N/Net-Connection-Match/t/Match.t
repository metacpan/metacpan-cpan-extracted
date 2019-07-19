#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match' ) || print "Bail out!\n";
}

my $connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'22',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'LISTEN',
					  };

my $nm_connection_args={
					  foreign_host=>'10.0.0.1',
					  foreign_port=>'80',
					  local_host=>'10.0.0.2',
					  local_port=>'12322',
					  proto=>'tcp4',
					  state=>'LISTEN',
					  };

my %args=(
		  testing=>1,
		  checks=>[
				   {
					type=>'Ports',
					invert=>0,
					args=>{
						   ports=>[
								   '22',
								   ],
						   lports=>[
									'53',
									],
						   fports=>[
									'12345',
									],
						   }
					}
				   ]
		  );

my %args2=(
		  testing=>1,
		  checks=>[
				   {
					type=>'Ports',
					invert=>0,
					args=>{
						   ports=>[
								   '22',
								   ],
						   lports=>[
									'53',
									],
						   fports=>[
									'12345',
									],
						   }
					},
				   {
					type=>'Protos',
					invert=>0,
					args=>{
						   protos=>[
									'tcp4',
									],
						   }
					}
				   ]
		   );


my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check') or diag('Calling Net::Connection::Match::Ports->new resulted in... '.$@);

# make sure it will not accept a improper ref type
my $returned;
eval{
	$returned=$checker->match($checker);
};
ok( $checker->error eq '2', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# make sure it will not accept null input
eval{
	$returned=$checker->match();
};
ok( $checker->error eq '2', 'match null input check') or diag('match accepted null input');

# Create a matching connection and see if it matches
my $conn=Net::Connection->new( $connection_args );
$returned=0;
eval{
	$returned=$checker->match($conn);
};
ok( $returned eq '1', 'match good conn check') or diag('match failed on a connection that should match');

# Create a non-matching connection and see if it matches
my $nm_conn=Net::Connection->new( $nm_connection_args );
$returned=0;
eval{
	$returned=$checker->match($nm_conn);
};
ok( $returned eq '0', 'match bad conn check') or diag('match on a connection that should not match');

# makes sure we can init with good args
$worked=0;
eval{
	$checker=Net::Connection::Match->new( \%args2 );
	$worked=1;
};
ok( $worked eq '1', 'init check2') or diag('Calling Net::Connection::Match::Ports->new resulted in... '.$@);

# Create a matching connection and see if it matches
$returned=0;
eval{
	$returned=$checker->match($conn);
};
ok( $returned eq '1', 'match good conn check2') or diag('match failed on a connection that should match');

done_testing(9);
