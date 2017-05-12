use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $init;

{
	package Foo;
	
	use Moose;
	use MooseX::CustomInitArgs;
	
	has foo => (
		is        => 'ro',
		init_args => [
			'fu',
			'comfute' => sub { $_ },
		],
	);
}

sub except ($$$)
{
	my ($args, $expected, $name) = @_;
	
	ref $expected eq ref qr{}
		and return like(
			exception { Foo->new(@$args) },
			$expected,
			$name,
		);
	
	return is(
		exception { Foo->new(@$args) },
		$expected,
		$name,
	);
}

for my $count (0..1)
{
	except [ foo     => 42 ], undef, 'standard init_arg ok';
	except [ fu      => 42 ], undef, 'alternative init_arg ok';
	except [ comfute => 42 ], undef, 'computed init_arg ok';

	except
		[ fu => 42, foo => 42 ],
		qr{^Conflicting init_args \(foo, fu\)},
		'pair throws (standard + alternative)';

	except
		[ foo => 42, comfute => 42 ],
		qr{^Conflicting init_args \(comfute, foo\)},
		'pair throws (standard + computed)';

	except
		[ fu => 42, comfute => 42 ],
		qr{^Conflicting init_args \(comfute, fu\)},
		'pair throws (computed + alternative)';

	except
		[ fu => 42, foo => 42, comfute => 42 ],
		qr{^Conflicting init_args \(comfute, foo, fu\)},
		'triplet throws';
	
	Foo->meta->make_immutable;
}

my $wrongness = q{
	package Bar;
	
	use Moose;
	use MooseX::CustomInitArgs;
	
	has foo => (
		is        => 'ro',
		init_arg  => undef,
		init_args => [
			'fu',
			'comfute' => sub { $_ },
		],
	);
	
	1;
};

ok(!eval $wrongness, 'wrongness is wrong');
like $@, qr{^Attribute foo defined with init_args but no init_arg}, 'wrongness has right error message';

done_testing;
