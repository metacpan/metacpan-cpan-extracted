#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;
use PPI;
use PPIx::EditorTools::Outline;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

my @cases = (
	{   file     => 't/outline/Foo.pm',
		expected => [
			{   'modules' => [
					{   name => 'Method::Signatures',
						line => 3,
					},
				],
				'methods' => [
					{   name => 'new',
						line => 5,
					},
					{   name => 'hello',
						line => 8,
					}
				],
				'line' => 1,
				'name' => 'Foo',
			}
		],
	},
	{   file     => 't/outline/file1.pl',
		expected => [
			{   'methods' => [
					{   'line' => 6,
						'name' => 'qwer'
					}
				],
				'modules' => [
					{   'line' => 2,
						'name' => 'Abc'
					}
				],
				'name'     => 'main',
				'pragmata' => [
					{   'line' => 1,
						'name' => 'strict'
					},
					{   'line' => 1,
						'name' => 'warnings'
					}
				]
			}
		],
	},
	{   code => <<'END_CODE',
use strict;
END_CODE
		expected => [
			{   'pragmata' => [
					{   'line' => 1,
						name   => 'strict',
					},
				],
				'name' => 'main',
			},
		],
	},
	{   file     => 't/outline/file2.pl',
		expected => [
			{   'methods' => [
					{   'line' => 14,
						'name' => 'abc'
					},
					{   'line' => 19,
						'name' => 'def'
					},
					{   'line' => 26,
						'name' => 'xyz'
					}
				],
				'name'     => 'main',
				'pragmata' => [
					{   'line' => 4,
						'name' => 'strict'
					},
					{   'line' => 5,
						'name' => 'autodie'
					},
					{   'line' => 6,
						'name' => 'warnings'
					},
					{   'line' => 8,
						'name' => 'lib'
					}
				]
			}
		]
	},
);

##############
# Moose outline testing follows
##############

push @cases, (
	{   file     => 't/outline/Mooclass.pm',
		expected => [
			{   'modules' => [
					{   'name' => 'MooseX::Declare',
						'line' => 1,
					},
				],
				'methods' => [
					{   'name' => 'pub_sub',
						'line' => 14,
					},
					{   'name' => '_pri_sub',
						'line' => 18,
					},
					{   'name' => 'mm_before',
						'line' => 22,
					},
					{   'name' => 'mm_after',
						'line' => 26,
					},
					{   'name' => 'mm_around',
						'line' => 30,
					},
					{   'name' => 'mm_override',
						'line' => 34,
					},
					{   'name' => 'mm_augment',
						'line' => 38,
					},
				],
				'line'       => 3,
				'name'       => 'Mooclass',
				'attributes' => [
					{   'name' => 'moo_att',
						'line' => 5
					},
					{   'name' => 'label',
						'line' => 7
					},
					{   'name' => 'progress',
						'line' => 7
					},
					{   'name' => 'butWarn',
						'line' => 7
					},
					{   'name' => 'butTime',
						'line' => 7
					},
					{   'name' => 'start_stop',
						'line' => 7
					},
					{   'name' => 'account',
						'line' => 10
					},
					{   'name' => 'non_quoted_attr',
						'line' => 12
					},
				],
			}
		],
	},

	# can we do the same thing with vanilla Moose class definitions?
	{   file     => 't/outline/MooclassVanilla.pm',
		expected => [
			{   'modules' => [
					{   'name' => 'Moose',
						'line' => 3,
					},
				],
				'methods' => [
					{   'name' => 'pub_sub',
						'line' => 13,
					},
					{   'name' => '_pri_sub',
						'line' => 17,
					},
					{   'name' => 'mm_before',
						'line' => 21,
					},
					{   'name' => 'mm_after',
						'line' => 25,
					},
					{   'name' => 'mm_around',
						'line' => 29,
					},
					{   'name' => 'mm_override',
						'line' => 33,
					},
					{   'name' => 'mm_augment',
						'line' => 37,
					},
				],
				'line'       => 1,
				'name'       => 'Moose::Declarations::MethodModifiers::Vanilla',
				'attributes' => [
					{   'name' => 'moo_att',
						'line' => 5,
					},
					{   'name' => 'label',
						'line' => 7,
					},
					{   'name' => 'progress',
						'line' => 7,
					},
					{   'name' => 'butWarn',
						'line' => 7,
					},
					{   'name' => 'butTime',
						'line' => 7,
					},
					{   'name' => 'start_stop',
						'line' => 7,
					},
					{   'name' => 'account',
						'line' => 9,
					},
					{   'name' => 'non_quoted_attr',
						'line' => 11,
					},
				],
			}
		],
	},
	{   file     => 't/outline/Moorole.pm',
		expected => [
			{   'modules' => [
					{   'name' => 'MooseX::Declare',
						'line' => 1,
					},
				],
				'line' => 3,
				'name' => 'Moorole',

				'attributes' => [
					{   'line' => 7,
						'name' => 'balance'
					},
					{   'line' => 13,
						'name' => 'overdraft'
					}
				],
				'pragmata' => [
					{   'line' => 5,
						'name' => 'version'
					}
				]
			}
		]
	},
	{   file     => 't/outline/Moofirst.pm',
		expected => [
			{   'attributes' => [
					{   'line' => 7,
						'name' => 'balance'
					},
					{   'line' => 13,
						'name' => 'overdraft'
					},
					{   'line' => 23,
						'name' => 'name'
					},
					{   'line' => 25,
						'name' => 'account'
					}
				],
				'line'    => 3,
				'methods' => [
					{   'line' => 27,
						'name' => '_build_overdraft'
					}
				],
				'modules' => [
					{   'line' => 1,
						'name' => 'MooseX::Declare'
					}
				],
				'name'     => 'Moofirst',
				'pragmata' => [
					{   'line' => 5,
						'name' => 'version'
					}
				]
			}
		]
	},
);

##############
# has outline testing #1435
##############
push @cases, (
	{   file     => 't/outline/test_1435.pl',
		expected => [
			{   'attributes' => [
					{   'name' => 'first',
						'line' => 3,
					},
					{   'name' => 'second',
						'line' => 5,
					},
				],
				'modules' => [
					{   'line' => 1,
						'name' => 'Class::Accessor'
					}
				],
				'name' => 'main',
			}
		],
	},
);

plan tests => @cases * 1;

foreach my $c (@cases) {
	my $code = $c->{code};
	if ( $c->{file} ) {
		open my $fh, '<', $c->{file} or die( "couldn't read file: ", $c->{file}, ": $!" );
		local $/ = undef;
		$code = <$fh>;
	}
	my $outline = PPIx::EditorTools::Outline->new->find( code => $code );

	#diag explain $outline;
	is_deeply ( $outline, $c->{expected}, $c->{file} ) or diag explain $outline;
}
