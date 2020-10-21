use Test::More;

use Struct::Conditional;

my $c = Struct::Conditional->new();

my $struct = {
	"for" => {
		"key" => "countries",
		"each" => "countries",
		"if" => {
			"m" => "Thailand",
			"key" => "country",
			"then" => {
				"rank" => 1
			}
		},
		"elsif" => {
			"m" => "Indonesia",
			"key" => "country",
			"then" => {
				"rank" => 2
			}
		},
		"else" => {
			"then" => {
				"rank" => undef
			}
		},
		"country" => "{country}"
	}
};

my $compiled = $c->compile($struct, {
	countries => [
		{ country => "Thailand" },
		{ country => "Indonesia" },
		{ country => "Hawaii" },
		{ country => "Canada" },
	]
}, 1);

my $expected = {
	'countries' => [
		{
			'rank' => 1,
			'country' => 'Thailand'
		},
		{
			'rank' => 2,
			'country' => 'Indonesia'
		},
		{
			'country' => 'Hawaii',
			'rank' => undef
		},
		{
			'rank' => undef,
			'country' => 'Canada'
		}
	]
};

is_deeply($compiled, $expected);

done_testing;
