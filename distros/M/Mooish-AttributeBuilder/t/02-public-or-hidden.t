use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

subtest 'testing public reader on public field' => sub {
	my ($name, %params) = field 'field', reader => 1;

	is $name, 'field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => 'get_field'},
		'return value ok';
};

subtest 'testing public reader (forced) on public field' => sub {
	my ($name, %params) = field 'field', reader => -public;

	is $name, 'field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => 'get_field'},
		'return value ok';
};

subtest 'testing hidden reader (forced) on public field' => sub {
	my ($name, %params) = field 'field', reader => -hidden;

	is $name, 'field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => '_get_field'},
		'return value ok';
};

subtest 'testing hidden reader on hidden field' => sub {
	my ($name, %params) = field '_field', reader => 1;

	is $name, '_field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => '_get_field'},
		'return value ok';
};

subtest 'testing hidden reader (forced) on hidden field' => sub {
	my ($name, %params) = field '_field', reader => -hidden;

	is $name, '_field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => '_get_field'},
		'return value ok';
};

subtest 'testing public reader (forced) on hidden field' => sub {
	my ($name, %params) = field '_field', reader => -public;

	is $name, '_field', 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, reader => 'get_field'},
		'return value ok';
};

done_testing;

