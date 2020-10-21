use Test::More;

use Struct::Conditional;

my $struct = {
	"thing" => {
		"for" => {
			"key" => "testing",
			"each" => "abc",
			"if" => {
				"m" => "test",
				"key" => "test",
				"then" => {
					"abc" => 123
				}
			},
			"elsif" => {
				"m" => "other",
				"key" => "test",
				"then" => {
					"def" => 456
				}
			},
			"else" => {
				"then" => {
					"ghi" => 789
				}
			}
		},
		"def"  => 123
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
	thing => {
		abc => [
			{ def => 456 },
			{ abc => 123 },
			{ def => 456 },
			{ ghi => 789 },
		],
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
