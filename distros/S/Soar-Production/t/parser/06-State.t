#test correct state handling

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
	# print STDERR Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
=== state
--- parse_success
sp {state
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== impasse
--- parse_success
sp {impasse
	(impasse <i>)
-->	(<i> ^foo <bar>)
}
--- expected: 1

=== no <s>
--- parse_success
sp {no-variable
	(state ^foo <bar>)
-->	(<bar> ^foo <bar>)
}
--- expected: 1

=== structure of state
--- parse_struct dive=LHS,conditions,0,condition
sp {foo
	(state)
-->
}
--- expected_structure
{
	condType 			=> 'state',
	idTest			=> undef,
	attrValueTests 	=> [],
}
