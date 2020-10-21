use Test::More;

use Struct::Conditional;

my $struct = {
	"given" => {
		"key" => "test",
		"when" => {
			"test" => {
				"abc" => 123
			},
			"other" => {
				"def" => 456	
			},
			"default" => {
				"ghi" => 789
			}
		}
	},
	"overlord" => 1
};

my $compiled = Struct::Conditional->new->compile($struct, { 
	test => "other", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	def => 456,
};

is_deeply($compiled, $hash);

$compiled = Struct::Conditional->new->compile($struct, { 
	test => "again", 
	again => "yay" 
}, 1);

$hash = {
	overlord => 1,
	ghi => 789,
};

is_deeply($compiled, $hash);

done_testing;
