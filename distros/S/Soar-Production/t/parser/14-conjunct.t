#test conjunctions ({ x y })

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> ['parse', 'dive=LHS,conditions,0,condition,attrValueTests,0,values,0,test,conjunctiveTest'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the value of foo

=== strings
--- parse_success
sp {strings
	(state <s> ^foo { a b })
-->	(<s> ^foo bar)
}
--- expected: 1

=== strings no space
--- parse_success
sp {strings-spaceless
	(state <s> ^foo {a b})
-->	(<s> ^foo bar)
}
--- expected: 1

=== quotes
--- parse_success
sp {quoted
	(state <s> ^foo { |a| |\|b| |c| })
-->	(<s> ^foo bar)
}
--- expected: 1

=== disjunct
--- parse_success
sp {disjunct
	(state <s> ^foo { << a b c >> << t u >> })
-->	(<s> ^foo bar)
}
--- expected: 1

=== variable
--- parse_success
sp {variable
	(state <s> ^foo { <bar> baz })
-->	(<s> ^foo bar)
}
--- expected: 1

=== missing brace
Curly brace cannot be part of a string in Soar
--- parse_success
sp {no-ending
	(state <s> ^foo {a b)
-->	(<s> ^foo bar)
}
--- expected: 0

=== missing brace
Curly brace cannot be part of a string in Soar
--- parse_success
sp {no-ending
	(state <s> ^foo a b})
-->	(<s> ^foo bar)
}
--- expected: 0

=== structure
--- parse_struct
sp {disjunction
	(state <s> ^foo { a b })
-->	(<s> ^foo bar)
}
--- expected_structure
[
	{ type => 'sym', constant => { type => 'string', value => 'a' }  },
	{ type => 'sym', constant => { type => 'string', value => 'b' }  }
]
