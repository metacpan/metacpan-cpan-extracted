#test preferences (<, =, etc.)
#manual page 58-9

use t::parser::TestSoarProdParser;
use Test::Deep;
use Test::More 0.88;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> ['parse','dive=RHS,0,attrValueMake,0,valueMake'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
We just vary the preference of operator
=== unary
--- parse_success
sp {unary
	(state <s>)
-->	(<s> ^operator bar @)
}
--- expected: 1

=== unary
--- parse_success
sp {unary
	(state <s>)
-->	(<s> ^operator <o> ~)
}
--- expected: 1

=== double value
--- parse_success
sp {double
	(state <s>)
-->	(<s> ^operator <o1> <o2>)
}
--- expected: 1

=== binary
--- parse_success
sp {binary
	(state <s>)
-->	(<s> ^operator 1 < <o> )
}
--- expected: 1

=== multiple
--- parse_success
sp {multiple
	(state <s>)
-->	(<s> ^operator <o1> <o2> + <o2> < <o1> <o3> =, <o4>)
}
--- expected: 1

=== the default preference is '+'
--- parse_struct
sp {acceptable-pref
	(state <s>)
-->	(<s> ^operator <o>)
}
--- expected_structure
[
	{
		'preferences' => [
			{
				'value' => '+',
				'type' => 'unary'
			}
		],
		'rhsValue' => {
			variable => 'o'
		}
	}
]

=== unary structure
--- parse_struct
sp {unary
	(state <s>)
-->	(<s> ^operator <o> ~)
}
--- expected_structure
[
	{
		'preferences' => [
			{
				'value' => '~',
				'type' => 'unary'
			}
		],
		'rhsValue' => {
			variable => 'o'
		}
	}
]

=== binary structure
--- parse_struct
sp {binary
	(state <s>)
-->	(<s> ^operator <o1> < <o2> )
}
--- expected_structure
[
	{
		'preferences' => [
			{
				'value' => '<',
				'type' => 'binary',
				'compareTo' => {
					variable => 'o2',
				}
			}
		],
		'rhsValue' => {
			variable => 'o1'
		}
	}
]

=== multiple structure comma
comma causes '=' to be unary
--- parse_struct
sp {multiple
	(state <s>)
-->	(<s> ^operator <o1> <o2> + <o2> < <o1> <o3> =, <o4>)
}
--- expected_structure
[
   {
	 'preferences' => [
						{
						  'value' => '+',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o1'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '+',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o2'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '<',
						  'type' => 'binary',
						  'compareTo' => {
										   'variable' => 'o1'
										 }
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o2'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '=',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o3'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '+',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o4'
				   }
   }
]

=== multiple structure no comma
comma causes '=' to be binary
--- parse_struct
sp {multiple
	(state <s>)
-->	(<s> ^operator <o1> <o2> + <o2> < <o1> <o3> = <o4>)
}
--- expected_structure
[
   {
	 'preferences' => [
						{
						  'value' => '+',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o1'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '+',
						  'type' => 'unary'
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o2'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '<',
						  'type' => 'binary',
						  'compareTo' => {
										   'variable' => 'o1'
										 }
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o2'
				   }
   },
   {
	 'preferences' => [
						{
						  'value' => '=',
						  'type' => 'binary',
						  'compareTo' => {
										   'variable' => 'o4'
										 }
						}
					  ],
	 'rhsValue' => {
					 'variable' => 'o3'
				   }
   }
]
