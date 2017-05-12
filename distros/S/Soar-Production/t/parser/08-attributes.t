#test attributes

use t::parser::TestSoarProdParser;
use Test::Deep;
use Data::Dumper;
use Test::More 0.88;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> 'parse',
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the att name
=== simple match
--- parse_success
sp {simple
	(state <s> ^foo)
-->
}
--- expected: 1

=== match is not negative structure
--- parse_struct dive=LHS,conditions,0,condition,attrValueTests,0,negative
sp {simple
	(state <s> ^foo)
-->
}
--- expected_structure
'no'

=== simple negative match
--- parse_success
sp {simple-negative
	(state <s> -^foo)
-->
}
--- expected: 1

=== simple negative match structure
--- parse_struct dive=LHS,conditions,0,condition,attrValueTests,0,negative
sp {simple-negative
	(state <s> -^foo)
-->
}
--- expected_structure
'yes'

=== variable match
--- parse_success
sp {variable
	(state <s> ^<foo>)
-->
}
--- expected: 1

=== simple concatenated match
--- parse_success
sp {simple-cat
	(state <s> ^foo.bar)
-->
}
--- expected: 1

=== concatenated match with bad parent
only string/quoted/variable can have a child
--- SKIP
--- parse_success
sp {cat
	(state <s> ^foo.1.bar)
}
--- expected: 0

=== simple conjunction match
--- parse_success
sp {conjunction
	(state <s> ^{foo bar})
-->
}
--- expected: 1

=== complicated conjunction match
--- parse_success
sp {conjunction-mess
	(state <s> ^{foo << bar baz >> <=> 21})
-->
}
--- expected: 1

=== complicated conjunction concatenation match
--- parse_success
sp {conjunction-mess-cat
	(state <s> ^{foo << bar baz >> <=> 21}.{fu bear}.| haleluja! |)
-->
}
--- expected: 1

=== simple concatenation match structure
--- parse_struct dive=LHS,conditions,0,condition,attrValueTests,0,attrs
sp {simple-cat
	(state <s> ^foo.bar)
-->
}
--- expected_structure
[
	{
		'simpleTest' => {
			'type' => 'sym',
			'constant' => {
				'value' => 'foo',
				'type' => 'string'
			}
		}
	},
	{
		'simpleTest' => {
			'type' => 'sym',
			'constant' => {
				'value' => 'bar',
				'type' => 'string'
			}
		}
	}
]

=== complicated conjunction concatenation match structure
--- parse_struct dive=LHS,conditions,0,condition,attrValueTests,0,attrs,0
sp {conjunction
	(state <s> ^{foo bear})
-->
}
--- expected_structure
{
	'conjunctiveTest' => [
		{'type' => 'sym', 'constant' => {
			'value' => 'foo',
			'type' => 'string'
			}
		},
		{
			'type' => 'sym','constant' => {
				'value' => 'bear',
				'type' => 'string'
			}
		}
	]
}

=== simple make
--- parse_success
sp {simple
	(state <s>)
--> (<s> ^foo <bar>)
}
--- expected: 1

=== concatenated make
--- parse_success
sp {cat
	(state <s>)
--> (<s> ^foo.bar <bar>)
}
--- expected: 1

=== concatenated make with bad parent
only string/quoted/variable can have a child
--- SKIP
--- parse_success
sp {cat
	(state <s>)
--> (<s> ^foo.1.bar)
}
--- expected: 0

=== concatenated variable make
--- parse_success
sp {variable
	(state <s>)
--> (<s> ^foo.<bar> <baz>)
}
--- expected: 1

=== concatenated varied make
--- parse_success
sp {varied
	(state <s>)
--> (<s> ^<foo>.| spa ce |.more.4 <bar>)
}
--- expected: 1

=== concatenated make structure
--- parse_struct dive=RHS,0,attrValueMake,0,attr
sp {cat
	(state <s>)
--> (<s> ^foo.bar <bar>)
}
--- expected_structure
[{
	'value' => 'foo',
	'type' => 'string'
},
{
	'value' => 'bar',
	'type' => 'string'
}]
