use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

my %expected_prefixes = (
	1 => {
		writer => 'set',
		predicate => 'has',
		clearer => 'clear',
		builder => '_build',
	},
	-public => {
		writer => 'set',
		predicate => 'has',
		clearer => 'clear',
		builder => 'build',
	},
	-hidden => {
		writer => '_set',
		predicate => '_has',
		clearer => '_clear',
		builder => '_build',
	},
);

# reader was tested in test 02
for my $argument (sort keys %expected_prefixes) {
	for my $method_type (sort keys %{$expected_prefixes{$argument}}) {
		subtest "testing $method_type for $argument" => sub {
			my ($name, %params) = field 'field', $method_type => $argument;

			is $name, 'field', 'name ok';
			is_deeply
				\%params,
				{is => 'ro', init_arg => undef, $method_type => "$expected_prefixes{$argument}{$method_type}_field"},
				'return value ok';
		};
	}
}

done_testing;

