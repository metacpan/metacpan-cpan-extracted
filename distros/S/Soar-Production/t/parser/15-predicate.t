#test preferences (<=, etc.)

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 		=> 'parse_success',
	parse_struct		=> ['parse', 'dive=LHS,conditions,0,condition,attrValueTests,0,values'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# print 'got: ' . Dumper($block->parse_struct);
	# print 'expecting: ' . Dumper($block->expected_structure);
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the preference of foo
=== greater than number
--- parse_success
sp {breater-than
	(state <s> ^foo > 1)
-->	(<s> ^foo bar)
}
--- expected: 1

=== same-type as variable
--- parse_success
sp {same-type
	(state <s> ^foo <=> <x>)
-->	(<s> ^foo bar)
}
--- expected: 1

=== not equal to quoted string
--- parse_success
sp {inequality
	(state <s> ^foo <> |foo bar| )
-->	(<s> ^bar ||)
}
--- expected: 1

=== multiple vals
--- parse_success
sp {multiple-vals
	(state <s> ^foo 1 b |stuff|)
-->	(<s> ^foo bar)
}
--- expected: 1

=== multiple tests
--- parse_success
sp {multiple-tests
	(state <s> ^foo 1 > 0 <=> 45 <> NaN)
-->	(<s> ^foo bar)
}
--- expected: 1

=== structure of multiple tests
--- parse_struct
sp {multiple-tests
	(state <s> ^foo 1 > 0 <=> 45 <> NaN)
-->	(<s> ^foo bar)
}
--- expected_structure
[
	{test => {simpleTest => {type => 'int', constant => '1'}}, '+' => 'no'},
	{test => {simpleTest => {relationTest => {test => {type => 'int', constant => '0'}, relation => '>'}}},'+' => 'no'},
	{test => {simpleTest => {relationTest => {test => {type => 'int', constant => '45'}, relation => '<=>'}}},'+' => 'no'},
	{test => {simpleTest => {relationTest => {test => {type => 'sym', constant => {type => 'string', value => 'NaN'}}, relation => '<>'}}},'+' => 'no'},
]

=== conjunction with unary prefs
from page 45 of the manual
--- parse_success
sp {conjunct-unary-pref
	(state <s> ^foo { <= <a> >= <b> })
-->	(<s> ^bar ||)
}
--- expected: 1

=== conjunction with binary pref
from page 45 of the manual
--- parse_success
sp {conjunct-binary-pref
	(state <s> ^foo { <a> > <b> })
-->	(<s> ^bar ||)
}
--- expected: 1

=== conjunction with mixed prefs
from page 45 of the manual
--- parse_success
sp {conjunct-mixed-pref
	(state <s> ^foo { <=> <x> > <y> << 1 2 3 4 >> <z> } )
-->	(<s> ^bar ||)
}
--- expected: 1

=== conjunction with mixed prefs structure
from page 45 of the manual
--- parse_struct
sp {conjunct-mixed-pref
	(state <s> ^foo { <=> <x> > <y> << 1 2 3 4 >> <z> } )
-->	(<s> ^bar ||)
}
--- expected_structure
[
	{'test' => {'conjunctiveTest' => [
		{'relationTest' => {'test' => {'variable' => 'x'},'relation' => '<=>'}},
		{'relationTest' => {'test' => {'variable' => 'y'},'relation' => '>'}},
		{'disjunctionTest' => [
			{'type' => 'int','constant' => '1'},
			{'type' => 'int','constant' => '2'},
			{'type' => 'int','constant' => '3'},
			{'type' => 'int','constant' => '4'}
		]},
		{'variable' => 'z'}
	]}, '+' => 'no'}
]
