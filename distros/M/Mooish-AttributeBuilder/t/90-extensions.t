use v5.10;
use strict;
use warnings;

use Test::More;

use lib 't/lib';
use CustomBuilder;

subtest 'testing custom module' => sub {
	my ($name, %params) = cache 'test';

	is $name, 'test', 'name ok';
	is ref delete $params{default}, 'CODE', 'default ok';
	is_deeply \%params,
		{
			is => 'ro',
			init_arg => undef,
			lazy => 1,
			clearer => '_hid_cleanse_test',
		},
		'return value ok';
};

done_testing;

