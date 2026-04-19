use Test::More;

my $class = 'Object::Iterate';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, qw(_check_object);
	};

my @table = (
	[ [ {}              ], 'anonymous hash'  ],
	[ [ []              ], 'anonymous array' ],
	[ [ bless {}, 'Foo' ], 'blessed object'  ],
	[ [ undef           ], 'undef'           ],
	[ [                 ], 'empty'           ],
	);

foreach my $row ( @table ) {
	my( $args, $label ) = @$row;
	$result = not eval{ Object::Iterate::_check_object( @$args ) };
	ok $result, $label;
	}

done_testing();
