use Test::More tests => 3;

use constant ITERATIONS => 100; # sufficiently large to overcome probability
our $AMBIGUOUS = 'o01ilvwc|_\-.,:;\[\](){}'; # keys of String::MkPasswd::IS_AMBIGUOUS in regex form

BEGIN { use_ok('String::MkPasswd') };

my $password;

subtest 'Test distributed passwords with "-noambiguous" enabled' => sub {
	plan tests => ITERATIONS;
	for ( my $i = 0; $i < ITERATIONS; $i++ ) {
		$password = String::MkPasswd::mkpasswd( -dist => 1, -noambiguous => 1 );
		ok( $password !~ /[$AMBIGUOUS]/, 'Distributed password contains no ambiguous characters');
	}
};

subtest 'Test non-distributed passwords with "-noambiguous" enabled' => sub {
	plan tests => ITERATIONS;
	for ( my $i = 0; $i < ITERATIONS; $i++ ) {
		$password = String::MkPasswd::mkpasswd( -dist => 0, -noambiguous => 1 );
		ok( $password !~ /[$AMBIGUOUS]/, 'Non-distributed password contains no ambiguous characters');
	}
};
