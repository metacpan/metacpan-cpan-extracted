use Test::More;

use Struct::Conditional;

my $struct = {
	"if" => {
		"m" => "test",
		"key" => "test",
		"then" => {
			"abc" => 123
		},
		"or" => {
			"key" => "test",
			"m" => "other",
			"or" => {
				"key" => "test",
				"m" => "thing"
			}
		}
	}
};

my $compiled = Struct::Conditional->new->compile($struct, { test => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
