#test correct string handling

use t::parser::TestSoarProdParser;
# use t::parser::TestSoarProdParser::Filter;
use Test::More 0.88;
use Test::Deep;
use Data::Dumper;
use Test::Warn;
use Data::Diver 'Dive';

plan tests => (1*blocks('parse_struct')) + (1*blocks('parse_success')) + (2*blocks('check_error'));

#for carp checking, we need local versions of our filters.
my $parser = Soar::Production::Parser->new();
my $diveString = 'LHS,conditions,0,condition,attrValueTests,0,values,0,test,simpleTest';
my @dive = split ',', $diveString;
sub parse { 
	$parser->parse_text($_[0]);
}

filters {
	parse_success 		=> 'parse_success',
	parse_struct		=> ['parse', "dive=$diveString"],
	# check_err			=> 'eval_stderr',
	expected_structure	=> 'eval'
};

# print '#hello';
run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# print Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

#check for correct warning and structure at the same time
for my $block( blocks('check_error')){
	my $structure;
	warning_is {$structure = parse($block->check_error)} { carped => $block->carps }, $block->name . ' carps';
	
	cmp_deeply($block->expected_structure, Dive($structure,@dive), $block->name . ' structure')
		or diag explain Dive($structure,@dive);
}

__END__
We just vary the value of foo.
Handling of preference-like characters is tricky, especially > and <.

=== normal
--- parse_struct
sp {string
	(state <s> ^foo stuff)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'sym', constant=> { type => 'string', value => 'stuff'  } }

=== garbage
--- parse_struct
sp {garbage
	(state <s> ^foo az09AZ$%&*+/:=?_<>-)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'sym', constant=> { type => 'string', value => 'az09AZ$%&*+/:=?_<>-'  } }

=== <xxx
--- check_error
sp {carp
	(state <s> ^foo <xxx)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'sym', constant=> { type => 'quoted', value => '<xxx'  } }
--- carps chomp
Suspicious string constant: "<xxx". Did you mean to use a variable or disjunction?

=== xxx>
--- check_error
sp {carp
	(state <s> ^foo xxx>)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'sym', constant=> { type => 'quoted', value => 'xxx>'  } }
--- carps chomp
Suspicious string constant: "xxx>". Did you mean to use a variable or disjunction?

=== brackets only
--- parse_success
sp {blank
	(state <s> ^foo <<)
-->	(<s> ^foo bar)
}
--- expected: 0

=== brackets only
--- parse_success
sp {blank
	(state <s> ^foo >>)
-->	(<s> ^foo bar)
}
--- expected: 0

=== brackets only (<>)
--- parse_success
sp {blank
	(state <s> ^foo <>)
-->	(<s> ^foo bar)
}
--- expected: 0

=== brackets only (><)
--- parse_success
sp {blank
	(state <s> ^foo ><)
-->	(<s> ^foo bar)
}
--- expected: 1
