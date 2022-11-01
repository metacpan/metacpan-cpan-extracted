use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Mooish::AttributeBuilder');
}

subtest 'testing param()' => sub {
	my ($name, %params) = param 'param', f => 'v';

	is $name, 'param', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', required => 1, f => 'v'},
		'return value ok';
};

subtest 'testing option()' => sub {
	my ($name, %params) = option 'option', f => 'v';

	is $name, 'option', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', required => 0, predicate => 'has_option', f => 'v'},
		'return value ok';
};

subtest 'testing field()' => sub {
	my ($name, %params) = field 'field', f => 'v';

	is $name, 'field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', f => 'v', init_arg => undef},
		'return value ok';
};

subtest 'testing extended()' => sub {
	my ($name, %params) = extended 'field', f => 'v';

	is $name, '+field', 'name ok';
	is_deeply
		\%params,
		{f => 'v'},
		'return value ok';
};

subtest 'testing whether is => rw will get overridden' => sub {
	my ($name, %params) = field 'field', is => 'rw';

	is $name, 'field', 'name ok';
	is_deeply
		\%params,
		{is => 'rw', init_arg => undef},
		'return value ok';
};

done_testing;

