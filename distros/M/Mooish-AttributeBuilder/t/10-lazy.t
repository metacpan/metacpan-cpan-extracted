use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

subtest 'testing lazy with default' => sub {
	my $subref = sub { };
	my ($name, %params) = field 'param', lazy => $subref;

	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, lazy => 1, default => $subref},
		'return value ok';
};

subtest 'testing lazy with builder name' => sub {
	my ($name, %params) = field 'param', lazy => 'sub';

	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, lazy => 1, builder => 'sub'},
		'return value ok';
};

subtest 'testing lazy with "1"' => sub {
	my ($name, %params) = field 'param', lazy => 1;

	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, lazy => 1, builder => '_build_param'},
		'return value ok';
};

subtest 'testing lazy with "0"' => sub {
	my ($name, %params) = field 'param', lazy => 0;

	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, lazy => 0},
		'return value ok';
};

done_testing;

