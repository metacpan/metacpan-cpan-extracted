use Test::More;

use Struct::Conditional;

my $struct = {
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
};

my $compiled = Struct::Conditional->new->compile($struct, { test => "other" });

is_deeply($compiled, { def => 456 });

done_testing;
