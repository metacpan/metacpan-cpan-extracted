use strict;
use warnings;

use Test::More 1;

my $class  = 'Set::CrossProduct';
my $method = 'jump_to';

subtest 'sanity' => sub {
	use_ok( $class ) or BAIL_OUT( "$class did not compile" );
	can_ok $class, $method;
	};

my $cross = $class->new( [ [qw(a b)], [qw(x y z)], [qw(red blue green yellow)], [1,2,3] ] );
isa_ok $cross, $class;

subtest 'bad n' => sub {
	my $cross = $class->new( [ [1,2,3], [qw(a b c)] ] );
	isa_ok $cross, $class;

	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };

	subtest 'no arg' => sub {
		$warning = undef;
		is $cross->$method(), undef, "missing n returns undef";
		like $warning, qr/undefined argument/, 'floating point n error matches';
		};

	subtest 'undef arg' => sub {
		$warning = undef;
		is $cross->$method(undef), undef, "n as undef returns undef";
		like $warning, qr/undefined argument/, 'floating point n error matches';
		};

	subtest 'too many args' => sub {
		$warning = undef;
		is $cross->$method(1, 2, 3), undef, "too many args returns undef";
		like $warning, qr/too many arguments/, 'floating point n error matches';
		};

	subtest 'large n' => sub {
		$warning = undef;
		is $cross->$method(66), undef, "n larger than cardinality returns undef";
		like $warning, qr/too large/, 'large n error matches';
		};

	subtest 'cardinality' => sub {
		$warning = undef;
		is $cross->$method($cross->cardinality), undef, "n larger than cardinality returns undef";
		like $warning, qr/too large/, 'large n error matches';
		};

	subtest 'negative' => sub {
		$warning = undef;
		is $cross->$method($cross->cardinality), undef, "n below zero returns undef";
		like $warning, qr/less than/, 'large n error matches';
		};

	subtest 'non-whole number' => sub {
		$warning = undef;
		is $cross->$method($cross->cardinality), undef, "n as floating point returns undef";
		like $warning, qr/positive whole number/, 'floating point n error matches';
		};
	};

subtest 'jump to middle' => sub {
	my $n = 53;
	is $cross->position, 0, 'initial position is zero';

	my $cross_again = $cross->jump_to($n);
	isa_ok $cross_again, $class;
	is $cross->position, $n, 'position reports same value of n';

	is_deeply scalar $cross->previous, [ qw(b y blue 2) ], 'previous before get returns right tuple';

	is_deeply scalar $cross->get, [ qw(b y blue 3) ], 'get returns right tuple';
	is $cross->position, $n + 1, 'position reports value of n + 1';

	is_deeply scalar $cross->previous, [ qw(b y blue 3) ], 'previous after get returns the same tuple';
	is_deeply scalar $cross->next, [ qw(b y green 1) ], 'next returns right tuple';
	is $cross->position, $n + 1, 'position reports value of n + 1 after next and previous';
	};

subtest 'jump to start' => sub {
	my $n = 0;

	my $cross_again = $cross->jump_to($n);
	isa_ok $cross_again, $class;
	is $cross->position, $n, 'position reports same value of n';

	subtest 'previous at start' => sub {
		my $warning;
		local $SIG{__WARN__} = sub { $warning = $_[0] };
		is $cross->previous, undef, 'previous before get returns empty tuple';
		like $warning, qr/previous at/, 'expected error message';
		};

	is_deeply scalar $cross->get, [ qw(a x red 1) ], 'get returns right tuple';
	is $cross->position, $n + 1, 'position reports value of n + 1';

	is_deeply scalar $cross->previous, [ qw(a x red 1) ], 'previous after get returns the same tuple';
	is_deeply scalar $cross->next, [ qw(a x red 2) ], 'next returns right tuple';
	is $cross->position, $n + 1, 'position reports value of n + 1 after next and previous';
	};

done_testing();

__END__
# print STDERR "COMBOS: " . Dumper( [ map { [ $b++, $_ ] } $cross->combinations ] );

COMBOS: $VAR1 = [
          [
            0,
            [
              'a',
              'x',
              'red',
              1
            ]
          ],
          [
            1,
            [
              'a',
              'x',
              'red',
              2
            ]
          ],
          [
            2,
            [
              'a',
              'x',
              'red',
              3
            ]
          ],
          [
            3,
            [
              'a',
              'x',
              'blue',
              1
            ]
          ],
          [
            4,
            [
              'a',
              'x',
              'blue',
              2
            ]
          ],
          [
            5,
            [
              'a',
              'x',
              'blue',
              3
            ]
          ],
          [
            6,
            [
              'a',
              'x',
              'green',
              1
            ]
          ],
          [
            7,
            [
              'a',
              'x',
              'green',
              2
            ]
          ],
          [
            8,
            [
              'a',
              'x',
              'green',
              3
            ]
          ],
          [
            9,
            [
              'a',
              'x',
              'yellow',
              1
            ]
          ],
          [
            10,
            [
              'a',
              'x',
              'yellow',
              2
            ]
          ],
          [
            11,
            [
              'a',
              'x',
              'yellow',
              3
            ]
          ],
          [
            12,
            [
              'a',
              'y',
              'red',
              1
            ]
          ],
          [
            13,
            [
              'a',
              'y',
              'red',
              2
            ]
          ],
          [
            14,
            [
              'a',
              'y',
              'red',
              3
            ]
          ],
          [
            15,
            [
              'a',
              'y',
              'blue',
              1
            ]
          ],
          [
            16,
            [
              'a',
              'y',
              'blue',
              2
            ]
          ],
          [
            17,
            [
              'a',
              'y',
              'blue',
              3
            ]
          ],
          [
            18,
            [
              'a',
              'y',
              'green',
              1
            ]
          ],
          [
            19,
            [
              'a',
              'y',
              'green',
              2
            ]
          ],
          [
            20,
            [
              'a',
              'y',
              'green',
              3
            ]
          ],
          [
            21,
            [
              'a',
              'y',
              'yellow',
              1
            ]
          ],
          [
            22,
            [
              'a',
              'y',
              'yellow',
              2
            ]
          ],
          [
            23,
            [
              'a',
              'y',
              'yellow',
              3
            ]
          ],
          [
            24,
            [
              'a',
              'z',
              'red',
              1
            ]
          ],
          [
            25,
            [
              'a',
              'z',
              'red',
              2
            ]
          ],
          [
            26,
            [
              'a',
              'z',
              'red',
              3
            ]
          ],
          [
            27,
            [
              'a',
              'z',
              'blue',
              1
            ]
          ],
          [
            28,
            [
              'a',
              'z',
              'blue',
              2
            ]
          ],
          [
            29,
            [
              'a',
              'z',
              'blue',
              3
            ]
          ],
          [
            30,
            [
              'a',
              'z',
              'green',
              1
            ]
          ],
          [
            31,
            [
              'a',
              'z',
              'green',
              2
            ]
          ],
          [
            32,
            [
              'a',
              'z',
              'green',
              3
            ]
          ],
          [
            33,
            [
              'a',
              'z',
              'yellow',
              1
            ]
          ],
          [
            34,
            [
              'a',
              'z',
              'yellow',
              2
            ]
          ],
          [
            35,
            [
              'a',
              'z',
              'yellow',
              3
            ]
          ],
          [
            36,
            [
              'b',
              'x',
              'red',
              1
            ]
          ],
          [
            37,
            [
              'b',
              'x',
              'red',
              2
            ]
          ],
          [
            38,
            [
              'b',
              'x',
              'red',
              3
            ]
          ],
          [
            39,
            [
              'b',
              'x',
              'blue',
              1
            ]
          ],
          [
            40,
            [
              'b',
              'x',
              'blue',
              2
            ]
          ],
          [
            41,
            [
              'b',
              'x',
              'blue',
              3
            ]
          ],
          [
            42,
            [
              'b',
              'x',
              'green',
              1
            ]
          ],
          [
            43,
            [
              'b',
              'x',
              'green',
              2
            ]
          ],
          [
            44,
            [
              'b',
              'x',
              'green',
              3
            ]
          ],
          [
            45,
            [
              'b',
              'x',
              'yellow',
              1
            ]
          ],
          [
            46,
            [
              'b',
              'x',
              'yellow',
              2
            ]
          ],
          [
            47,
            [
              'b',
              'x',
              'yellow',
              3
            ]
          ],
          [
            48,
            [
              'b',
              'y',
              'red',
              1
            ]
          ],
          [
            49,
            [
              'b',
              'y',
              'red',
              2
            ]
          ],
          [
            50,
            [
              'b',
              'y',
              'red',
              3
            ]
          ],
          [
            51,
            [
              'b',
              'y',
              'blue',
              1
            ]
          ],
          [
            52,
            [
              'b',
              'y',
              'blue',
              2
            ]
          ],
          [
            53,
            [
              'b',
              'y',
              'blue',
              3
            ]
          ],
          [
            54,
            [
              'b',
              'y',
              'green',
              1
            ]
          ],
          [
            55,
            [
              'b',
              'y',
              'green',
              2
            ]
          ],
          [
            56,
            [
              'b',
              'y',
              'green',
              3
            ]
          ],
          [
            57,
            [
              'b',
              'y',
              'yellow',
              1
            ]
          ],
          [
            58,
            [
              'b',
              'y',
              'yellow',
              2
            ]
          ],
          [
            59,
            [
              'b',
              'y',
              'yellow',
              3
            ]
          ],
          [
            60,
            [
              'b',
              'z',
              'red',
              1
            ]
          ],
          [
            61,
            [
              'b',
              'z',
              'red',
              2
            ]
          ],
          [
            62,
            [
              'b',
              'z',
              'red',
              3
            ]
          ],
          [
            63,
            [
              'b',
              'z',
              'blue',
              1
            ]
          ],
          [
            64,
            [
              'b',
              'z',
              'blue',
              2
            ]
          ],
          [
            65,
            [
              'b',
              'z',
              'blue',
              3
            ]
          ],
          [
            66,
            [
              'b',
              'z',
              'green',
              1
            ]
          ],
          [
            67,
            [
              'b',
              'z',
              'green',
              2
            ]
          ],
          [
            68,
            [
              'b',
              'z',
              'green',
              3
            ]
          ],
          [
            69,
            [
              'b',
              'z',
              'yellow',
              1
            ]
          ],
          [
            70,
            [
              'b',
              'z',
              'yellow',
              2
            ]
          ],
          [
            71,
            [
              'b',
              'z',
              'yellow',
              3
            ]
          ]
        ];
