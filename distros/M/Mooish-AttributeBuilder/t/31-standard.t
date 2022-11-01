use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder -standard;

Mooish::AttributeBuilder::add_shortcut(
	sub {
		my ($name, %args) = @_;

		$args{shortcut1} = 'added';
		return %args;
	}
);

subtest 'testing standard interface' => sub {
	my ($name, %params) = field 'test';

	is_deeply \%params,
		{
			is => 'ro',
			init_arg => undef,
		},
		'return value ok';
};

done_testing;

