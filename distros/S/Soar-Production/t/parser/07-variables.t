#test correct variable (symConstant) handling

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
	# print Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the name of the state variable
=== basic
--- parse_success
sp {one-letter
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== junk name
--- parse_success
sp {lots-o-garbage
	(state <AZaz09$%&*+/:=?_->)
-->	(<AZaz09$%&*+/:=?_-> ^foo <bar>)
}
--- expected: 1

=== no alphanumeric
--- parse_success
sp {lots-o-garbage
	(state <$%&*+/:=?_->)
-->	(<$%&*+/:=?_-> ^foo <bar>)
}
--- expected: 1

=== empty name
--- parse_success
sp {empty
	(state <>)
-->	(<> ^foo <bar>)
}
--- expected: 0

=== space
--- parse_success
sp {empty
	(state <a b>)
-->	(<a b> ^foo <bar>)
}
--- expected: 0

=== empty name
--- parse_success
sp {empty
	(state <>)
-->	(<> ^foo <bar>)
}
--- expected: 0

=== contains period
--- parse_success
sp {lots-o-garbage
	(state <a.a>)
-->	(<a.a> ^foo <bar>)
}
--- expected: 0

=== contains forward slash
--- parse_success
sp {lots-o-garbage
	(state <a\a>)
-->	(<a\a> ^foo <bar>)
}
--- expected: 0

=== variable structure
--- parse_struct dive=LHS,conditions,0,condition,idTest,simpleTest
sp {var-struct
	(state <s>)
-->	(<s> ^foo bar)
}
--- expected_structure
{variable => 's'}