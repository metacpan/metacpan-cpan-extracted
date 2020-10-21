use Test::More;

use Struct::Conditional;

my $struct = {
	"for" => {
		"key" => "testing",
		"each" => "testing",
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
	testing => [
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
	]
};

is_deeply($compiled, $expected);

done_testing;
