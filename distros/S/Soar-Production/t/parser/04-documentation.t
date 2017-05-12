#test correct documentation string handling
use utf8;
use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;

plan tests => 1*blocks;

filters { 
	parse_success 			=> [qw(parse_success)],
	parse_struct			=> 'parse',
	expected_structure		=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}
__END__
=== one line quote
--- parse_success
sp {one-line-quote
	"stuff that I think is cool"
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== two line quote
--- parse_success
sp {two-line-quote
	"stuff that I 
	think is cool"
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== utf8
--- parse_success
sp {utf8
	"ぐ"
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== two lines, two quotes
--- parse_success
sp {twice-doc
	"this production"
	"shouldn't load"
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== missing quote
--- parse_success
sp {twice-doc
	"bad
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== structure of doc
--- parse_struct
sp {foo
	"bar"
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected_structure
{doc => 'bar'}

=== structure of missing doc
--- parse_struct
sp {foo
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected_structure
{doc => undef}
