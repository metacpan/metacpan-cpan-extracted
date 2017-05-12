#test function calls

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 		=> 'parse_success',
	parse_struct		=> 'parse',
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	# print 'expecting: ' . Dumper($block->expected_structure);
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the value of foo
=== arithmetic
--- parse_success
sp {arithmatic
	(state <s>)
-->	(<s> ^foo (+ 1 5) (* 3 6) (/ 4 2) (- 3 1))
}
--- expected: 1

=== clrf
--- parse_success
sp {crlf
	(state <s>)
-->	(<s> ^foo (crlf))
}
--- expected: 1

=== clrf structure
--- parse_struct dive=RHS,0,attrValueMake,0,valueMake,0,rhsValue
sp {crlf
	(state <s>)
-->	(<s> ^foo (crlf))
}
--- expected_structure
'(crlf)'

=== string function with args
--- parse_success
sp {various-args
	(state <s>)
-->	(<s> ^foo (buy <book> bag |shelf from Ikea's|))
}
--- expected: 1

=== can't specify RHS function name with variable
--- parse_success
sp {var-is-name
	(state <s>)
-->	(<s> ^foo (<name> <arg>))
}
--- expected: 0

=== arguments are functions
--- parse_success
sp {crlf
	(state <s>)
-->	(<s> ^foo (buy (groceryList <needs> <wants>) (askWife groceryList)))
}
--- expected: 1

=== string function with args structure
--- parse_struct dive=RHS,0,attrValueMake,0,valueMake,0,rhsValue
sp {various-args
	(state <s>)
-->	(<s> ^foo (buy <book> bag))
}
--- expected_structure
{
	'args' => [
		{
		  'variable' => 'book'
		},
		{
		  'type' => 'sym',
		  'constant' => {
						  'value' => 'bag',
						  'type' => 'string'
						}
		}
	  ],
	'function' => {
		'value' => 'buy',
		'type' => 'string'
	}
}
