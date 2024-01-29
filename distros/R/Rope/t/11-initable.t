use Test::More;

{
	package Initable;

	use Rope;

	property thing => (
		value => 500,
		enumerable => 1,
		initable => 1,
	);

	property nope => (
		value => 999,
		initable => 0
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

is($init->{nope}, 999);

eval {
	Initable->new(
		nope => 111
	);
};

like ($@, qr/Cannot initalise Object \(Initable\) property \(nope\) as initable is not set to true./);

done_testing();
