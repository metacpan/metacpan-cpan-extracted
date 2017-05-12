use strict;
use warnings;

use Test::More;
use Ryu;

subtest import => sub {
	BEGIN { Ryu->import(qw($ryu)) }
	isa_ok($ryu, 'Ryu');
	can_ok($ryu, qw(from just));
	done_testing;
};

subtest instantiate => sub {
	my $ryu = new_ok('Ryu');
	can_ok($ryu, qw(from just));
	done_testing;
};

done_testing;

