#test correct numbers (intConstant and floatConstant)

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> ['parse', 'dive=LHS,conditions,0,condition,attrValueTests,0,values,0,test,simpleTest'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# print Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the value of foo

=== blank
--- parse_struct
sp {blank
	(state <s> ^foo ||)
-->	(<s> ^foo bar)
}
--- expected_structure
{ type => 'sym', constant => { type => 'quoted', value => '' } }

=== lots of garbage
--- parse_struct 
sp {garbage
	(state <s> ^foo |foo bar	\"'!@#$%^&*}
{()[]_+=-.,:;|)
-->	(<s> ^foo bar)
}
--- expected_structure
{ type => 'sym', constant => { type => 'quoted', value => 'foo bar	\"\'!@#$%^&*}
{()[]_+=-.,:;'}  }

=== bar escaping
--- parse_struct 
sp {escaped
	(state <s> ^foo |a bar (\|)|)
-->	(<s> ^foo bar)
}
--- expected_structure
{ type => 'sym', constant => { type => 'quoted', value => 'a bar (|)' }  }

=== no closing bar
--- parse_success
sp {unfinished
	(state <s> ^foo |infinite comment...)
-->	(<s> ^foo bar)
}
--- expected: 0

=== quoted # character
From big.soar; the following 3 commands test the fix for issues 95 and 102
--- parse_success
sp {literals_test
   (state <s> ^superstate nil) # }}}}
-->
   (<s> ^literal |##}}}}}{{##|)}
--- expected: 1
