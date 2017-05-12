#test correct numbers (intConstant and floatConstant)

use t::parser::TestSoarProdParser;
use Test::Deep;
use Data::Dumper;
use Test::More 0.88;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> ['parse', 'dive=LHS,conditions,0,condition,attrValueTests,0,values,0,test,simpleTest'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the value of foo

=== positive int
--- parse_success
sp {one
	(state <s> ^foo 1)
-->
}
--- expected: 1

=== structure of positive int
--- parse_struct 
sp {one
	(state <s> ^foo 1)
-->
}
--- expected_structure
{ type=>'int', constant=>'1' }

=== negative int
--- parse_success
sp {one
	(state <s> ^foo -1)
-->
}
--- expected: 1

=== structure of negative int
--- parse_struct 
sp {negative-one
	(state <s> ^foo -1)
-->
}
--- expected_structure
{ type=>'int', constant=>'-1' }
