use Test::More;
use lib '.';

BEGIN {
    eval {
        require Struct::JSON::Ordered;
        Struct::JSON::Ordered->new();
        1;
    } or do {
        plan skip_all => "Struct::JSON::Ordered is not available";
    };
}


{
	package Custom;

	use Rope;
	use Rope::Autoload;
	use Rope::Conditional;
	use Rope::Chain;

	prototyped (
		chached_data => {},
		object_data => {}
	);

	conditional data => ['JSON::Ordered', '{
		"for": {
			"key": "countries",
			"each": "countries",
			"if": {
				"m": "Thailand",
				"key": "country",
				"then": {
					"rank": 1
				}
			},
			"elsif": {
				"m": "Indonesia",
				"key": "country",
				"then": {
					"rank": 2
				}
			},
			"else": {
				"then": {
					"rank": null
				}
			},
			"country": "{country}"
		}
	}'];

	chain data => 'store_data' => sub {
		my ($self, $data) = @_;
		$self->cached_data = $data;
		$self->object_data = Rope->from_nested_data($data, { use => ['Rope::Autoload'] });
		return $data;
	};

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}

my $c = Custom->new();

my $expected  = {
	countries => [
		{
			country => "Thailand",
			rank => 1
		},
		{
			country => 'Indonesia',
			rank => 2
		},
		{
			country => 'Japan',
			rank => undef
		},
		{
			country => 'Cambodia',
			rank => undef
		}
	]
};

is_deeply(
	$c->data({
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	}),
	$expected
);

is_deeply($c->cached_data, $expected);

is($c->object_data->countries->[1]->country, 'Indonesia');

ok(1);

done_testing();
