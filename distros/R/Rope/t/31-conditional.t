use Test::More;
use lib '.';

{
	package Custom;

	use Rope;
	use Rope::Autoload;
	use Rope::Conditional;
	use Rope::Chain;

	prototyped (
		chached_data => {}
	);

	conditional data => (
		for => {
			key => "countries",
			each => "countries",
			if => {
				m => "Thailand",
				key => "country",
				then => {
					"rank" => 1
				}
			},
			elsif => {
				m => "Indonesia",
				key => "country",
				then => {
					rank => 2
				}
			},
			else => {
				then => {
					rank => undef
				}
			},
			country => "{country}"
		}
	);

	chain data => 'store_data' => sub {
		my ($self, $data) = @_;
		$self->cached_data = $data;
		return $data;
	};

	#conditional json_data => ['JSON', 't/test.json'];
	#conditional yaml_data => ['YAML', 't/test.yml'];

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
			rank => 1,
			country => "Thailand"
		},
		{
			rank => 2,
			country => 'Indonesia'
		},
		{
			rank => undef,
			country => 'Japan',
		},
		{
			rank => undef,
			country => 'Cambodia'
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


ok(1);

done_testing();
