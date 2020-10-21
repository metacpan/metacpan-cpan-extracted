use Test::More;

use Struct::Conditional;

my $struct = {
	"if" => {
		"m" => "test",
		"key" => "test",
		"then" => {
			"abc" => 123
		},
		"and" => {
			"key" => "testing",
			"m" => "other",
			"and" => {
				"key" => "tester",
				"m" => "thing"
			}
		}
	}
};

my $compiled = Struct::Conditional->new->compile($struct, { test => "test", testing => "other", tester => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
