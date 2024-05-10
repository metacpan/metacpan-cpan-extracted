use Test::More;

{
	package Initable;

	use Rope;

	property [qw/thing nope/] => (
		value => 500,
		enumerable => 1,
		initable => 1,
	);

	properties (
		[qw/give more/] => {
			value => 555,
			enumerable => 1,
			initable => 1,
		}
	);

	prototyped (
		['worst', 'option', 'always'] => -1
	);

	1;
}

my $init = Initable->new();

is($init->{thing}, 500);

$init = Initable->new(
	thing => 123
);

is($init->{thing}, 123);

eval {
	$init->{thing} = 'kaput';
};

like ($@, qr/Cannot set Object \(Initable\) property \(thing\)/);

is($init->{nope}, 500);

is($init->{give}, 555);

is($init->{more}, 555);

is($init->{worst}, -1);

is($init->{always}, -1);

done_testing();
