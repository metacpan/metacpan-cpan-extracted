#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Net::Random::QRBG' );
}

my $obj = Net::Random::QRBG->new();
isa_ok($obj,"Net::Random::QRBG");
