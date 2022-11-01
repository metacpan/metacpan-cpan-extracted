use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

Mooish::AttributeBuilder::add_shortcut(
	sub {
		my ($name, %args) = @_;

		$args{shortcut1} = 'added';
		return %args;
	}
);

Mooish::AttributeBuilder::add_shortcut(
	sub {
		my ($name, %args) = @_;

		$args{shortcut1} = 'replaced';
		return %args;
	}
);

Mooish::AttributeBuilder::add_shortcut(
	sub {
		my ($name, %args) = @_;

		is_deeply \%args,
			{
				_type => 'field',
				one => 1,
				two => 2,
				three => 3,
				shortcut1 => 'replaced',
			},
			'args ok';

		$args{shortcut2} = 1;
		return %args;
	}
);

subtest 'testing custom shortcuts' => sub {
	my ($name, %params) = field 'test', one => 1, two => 2, three => 3;

	is_deeply \%params,
		{
			is => 'ro',
			init_arg => undef,
			one => 1,
			two => 2,
			three => 3,
			shortcut1 => 'replaced',
			shortcut2 => 1,
		},
		'return value ok';
};

done_testing;

