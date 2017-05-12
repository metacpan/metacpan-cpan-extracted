#Test that we can correctly strip comments
use strict;
use warnings;
use Test::More;
use Test::LongString;
use t::parser::TestSoarProdParser;
plan tests => 1*blocks;

filters {
	no_comment 		=> 'remove_comments',
	parse_success 	=> 'parse_success',
	# expected		=> 'chomp',
};

for my $block ( blocks('no_comment')){
	is_string_nows($block->no_comment, $block->expected, $block->name)
}

for my $block ( blocks('parse_success')){
	is_string_nows($block->parse_success, $block->expected, $block->name)
}

__END__
=== remove normal comments
--- no_comment
sp {one
# sp {two
	-{(state <s> ^foo 1) #stuff
		(<s> ^nested baz)
	}
	#}
-->
}
--- expected
sp {one

	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}

-->
}
=== remove ;# comments
--- no_comment
sp {one
# sp {two
	-{(state <s> ^foo 1) ;#stuff
		(<s> ^nested baz)
	}
	}
-->
}
--- expected
sp {one

	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}
	}
-->
}

=== don't remove quoted comments
--- no_comment
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |###|)
}
--- expected
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |###|)
}

=== don't remove quoted comment with escaping
--- no_comment
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}
--- expected
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}
=== remove commented ending bracket
--- no_comment
sp {one
# sp {two
	-{(state <s> ^foo 1) #stuff
		(<s> ^nested baz)
	}
	#}
-->
}
--- expected
sp {one

	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}

-->
}
=== remove ;# comments
--- no_comment
sp {one
# sp {two
	-{(state <s> ^foo 1) ;#stuff
		(<s> ^nested baz)
	}
	}
-->
}
--- expected
sp {one

	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}
	}
-->
}

=== don't remove quoted comments
--- no_comment
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |###|)
}
--- expected
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |###|)
}

=== don't remove quoted comment with escaping
--- no_comment
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}
--- expected
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}

=== parse normal commented
--- parse_success
sp {one
# sp {two
	-{(state <s> ^foo 1) #stuff
		(<s> ^nested baz)
	}
	#}
-->
}
--- expected: 1

=== parse ;# commented
--- parse_success
sp {one
	(state <s> ^foo 1) ; #}
	(<s> ^nested baz)
-->
}
--- expected: 1

=== parse quote
--- parse_success
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |###|)
}
--- expected: 1

=== parse quote with escaping
--- parse_success
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}
--- expected: 1
