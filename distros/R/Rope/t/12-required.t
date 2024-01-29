use Test::More;

{
	package Required;

	use Rope;

	property thing => (
		value => 500,
		enumerable => 1,
		initable => 1,
		required => 1,
	);

	property nope => (
		initable => 1,
		required => 1
	);

	property yep => (
		initable => 1,
		configurable => 1,
		required => 0
	);

	1;
}

my $init = Required->new(
	nope => 200,
	yep => 300
);

is($init->{thing}, 500);

is($init->{nope}, 200);

is($init->{yep}, 300);

eval {
	$init = Required->new(
		yep => 300
	);
};

like($@, qr/Required property \(nope\) in object \(Required\) not set/);

is ($init->{yep}, 300);

my $init = Required->new(
	nope => 200,
);

is($init->{thing}, 500);

is($init->{nope}, 200);

is($init->{yep}, undef);

done_testing();
