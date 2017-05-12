#test correct production name checking
use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
# use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 			=> [qw(parse_success)],
	parse_struct			=> 'parse',
	expected_structure		=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# warn 'comparing ' . Dumper($block->parse_struct) . ' with ' . Dumper $block->expected_structure;
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
=== alphanumeric
--- parse_success
sp {0123456789AbCdZz
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected: 1

=== alpha and then a bunch of junk
--- parse_success
sp {a$%&*=<>?_-/
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== number and then a bunch of junk
--- parse_success
sp {1$%&*=@<>?_-/
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== doesn't start with alphanumeric
--- parse_success
sp {$a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== colon
--- parse_success
sp {a:a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 1

=== comma
--- parse_success
sp {a,a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== exclamation point
--- parse_success
sp {a!a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== plus
--- parse_success
sp {a+a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== bracket
--- parse_success
sp {a[a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== bar
--- parse_success
sp {a|a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== forward slash
--- parse_success
sp {a\a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== period
--- parse_success
sp {a.a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== semicolon
--- parse_success
sp {a;a
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== not ASCII
--- parse_success
sp {aぐ
	(state <s>)
-->	(<s> ^foo <bar>)
}
--- expected: 0

=== structure of name
--- parse_struct
sp {the-name
	(state <s>)
-->
	(<s> ^foo <bar>)
}
--- expected_structure
{name => 'the-name'}
