use Test::More;

use Struct::Conditional;

my $struct = {
	"thing" => {
		"for" => {
			"key" => "testing",
			"keys" => 1,
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
		"def" => 123
	}
};

my $compiled = Struct::Conditional->new->compile($struct, {
	testing => { 
		a => { test => "other" },
		b => { test => "test" },
		c => { test => "other" },
		d => { test => "thing" },
	}
}, 1);

my $expected = {
	thing => {
		a => { def => 456 },
		b => { abc => 123 },
		c => { def => 456 },
		d => { ghi => 789 },
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
