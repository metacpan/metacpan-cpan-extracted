use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;
use Data::Dumper;

subtest 'testing array with default' => sub {
	my $default_sub = sub { };
	my ($name, %params) = field ['field1', 'field2'], default => $default_sub;

	is_deeply $name, ['field1', 'field2'], 'name ok';
	is_deeply
		\%params,
		{is => 'ro', init_arg => undef, default => $default_sub},
		'return value ok';
};

subtest 'testing array exception with builder' => sub {
	my $result = eval {
		my ($name, %params) = field ['field1', 'field2'], builder => 1;
		diag Dumper([$name, \%params]);
		1;
	};

	ok !$result, 'array name with builder dies ok';
	like $@, qr/builder is not supported/, 'array name with builder error message ok';
};

subtest 'testing array on extends keyword' => sub {
	my ($name, %params) = extended ['field1', 'field2'], lazy => 0;

	is_deeply $name, ['+field1', '+field2'], 'name changed ok';
};

done_testing;

