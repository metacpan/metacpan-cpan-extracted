use strict;
use Test::Simple tests => 1;

ok ((sub {
	use Strong::Random;
	my $rand = new Strong::Random;
	return $rand->rand <= 1;
})->(), 'Basic test');
