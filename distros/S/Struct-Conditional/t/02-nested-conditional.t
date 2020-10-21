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
			"ghi" => 789,
			"nested" => {
				"if" => {
					"eq" => "test",
					"key" => "other",
					"then" => {
						"abc" => 123,
						"nested_array" => [
							{
								"if" => {
									"ne" => "yay",
									"key" => "again",
									"then" => {
										"level" => 1
									},
									"elsif" => {
										"ne" => "yay",
										"key" => "again",
										"then" => {
											"level" => 2
										},
										"elsif" => {
											"ne" => "test",
											"key" => "again",
											"then" => {
												"level" => 3
											}
										}	
									}
								}
							}
						]
					}
				}
			}
		}
	},
	"overlord" => 1
};

my $compiled = Struct::Conditional->new->compile($struct, { 
	test => "again", 
	other => "test", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	ghi => 789,
	nested => {
		abc => 123,
		nested_array => [
			{
				level => 3
			}
		],
	}
};

is_deeply($compiled, $hash);

done_testing;
