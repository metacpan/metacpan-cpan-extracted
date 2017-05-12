#test negative conditions

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
=== negative
--- parse_success
sp {negative
	(state <s>)
	-(<s> ^foo bar)
-->
}
--- expected: 1

=== negative structure
--- parse_struct dive=LHS,conditions,0,negative
sp {negative
	-(<s> ^foo bar)
-->
}
--- expected_structure
'yes'

=== positive structure
--- parse_struct dive=LHS,conditions,0,negative
sp {positive
	(state <s>)
	(<s> ^foo bar)
-->
}
--- expected_structure
'no'
