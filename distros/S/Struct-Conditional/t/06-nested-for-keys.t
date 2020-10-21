use Test::More;

use Struct::Conditional;

my $struct = {
	"thing" => {
		"for" => {
			"key" => "testing",
			"keys" => "nested",
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
			},
			"extend" => 1
		},
		"def"  => 123
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
		nested => {
			a => { 
				def => 456,
				extend => 1
			},
			b => { 
				abc => 123, 
				extend => 1
			},
			c => { 
				def => 456, 
				extend => 1
			},
			d => { 
				ghi => 789,
				extend => 1
			}
		},
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
