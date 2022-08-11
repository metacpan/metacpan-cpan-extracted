use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

subtest 'testing init_arg with "1" on public field' => sub {
	my ($name, %params) = param 'param', init_arg => 1;

	is_deeply
		\%params,
		{is => 'ro', required => 1, init_arg => 'param'},
		'return value ok';
};

subtest 'testing init_arg with "1" on hidden field' => sub {
	my ($name, %params) = param '_param', init_arg => 1;

	is_deeply
		\%params,
		{is => 'ro', required => 1, init_arg => '_param'},
		'return value ok';
};

subtest 'testing init_arg with -public on hidden field' => sub {
	my ($name, %params) = param '_param', init_arg => -public;

	is_deeply
		\%params,
		{is => 'ro', required => 1, init_arg => 'param'},
		'return value ok';
};

subtest 'testing init_arg with -hidden on public field' => sub {
	my ($name, %params) = param 'param', init_arg => -hidden;

	is_deeply
		\%params,
		{is => 'ro', required => 1, init_arg => '_param'},
		'return value ok';
};

done_testing;

