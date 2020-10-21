use Test::More;

use Struct::Conditional;

my $struct = {
	"other" => "{testing}",
	"nested" => {
		"nested" => {
			"other" => "{testing}"
		}
	},
	"for" => {
		"key" => "testing",
		"each" => "testing",
		"remap" => "{test}",
		"abc" => 123
	}
};

my $compiled = Struct::Conditional->new->compile($struct, {
	testing => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	]
}, 1);

my $expected = {
	other => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	],
	nested => {
		nested => {
			other => [ 
				{ test => "other" },
				{ test => "test" },
				{ test => "other" },
				{ test => "thing" },
			]
		}
	},
	testing => [
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "test" },
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "thing" },
	]
};

is_deeply($compiled, $expected);

done_testing;
