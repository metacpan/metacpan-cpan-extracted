# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Scalar-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Scalar::Array') };

{
	my $rr = [ 1, 2, 3, 4 ];
	round_robin( $rr );

	ok( $rr == 1 );
	ok( $rr == 2 );
	ok( $rr == 3 );
	ok( $rr == 4 );
}

{
	my $sh = [ 1, 2, 3, 4 ];
	shrink( $sh );

	ok( $sh == 1 );
	ok( $sh == 2 );
	ok( $sh == 3 );
	ok( $sh == 4 );
	ok( not defined $sh );
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

