use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

subtest 'testing literal parameters' => sub {
	my ($name, %params) = field ['field'], -lazy => 1, -reader => -public;

	is_deeply $name, ['field'], 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, lazy => 1, reader => -public},
		'return value ok';
};

done_testing;

