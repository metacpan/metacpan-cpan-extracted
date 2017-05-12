#test correct flag handling

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> 'parse',
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
=== i support
--- parse_success
sp {isupport
	:i-support
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== o support
--- parse_success
sp {osupport
	:o-support
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== chunk
--- parse_success
sp {chunk
	:chunk
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== default
--- parse_success
sp {default
	:default
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== interrupt
--- parse_success
sp {interrupt
	:interrupt
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== multiple
--- parse_success
sp {multiple
	:interrupt
	:i-support
	:chunk
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== with doc
--- parse_success
sp {with-doc
	"foo"
	:i-support
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== bad flag
--- parse_success
sp {bad-flag
	x-support
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== structure of flags
--- parse_struct
sp {foo
	:i-support
	:o-support
	:chunk
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected_structure
{ flags => [ qw( i-support o-support chunk ) ] }

=== structure of missing flag
--- parse_struct
sp {foo
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected_structure
{ flags => [] }
