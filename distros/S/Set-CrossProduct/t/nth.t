use strict;
use warnings;

use Test::More 1;
my $class = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, 'nth';
	};

subtest 'bad n' => sub {
	my $cross = $class->new( [ [1,2,3], [qw(a b c)] ] );
	isa_ok $cross, $class;

	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };

	subtest 'no arg' => sub {
		$warning = undef;
		is $cross->nth(), undef, "missing n returns undef";
		like $warning, qr/undefined argument/, 'floating point n error matches';
		};

	subtest 'undef arg' => sub {
		$warning = undef;
		is $cross->nth(undef), undef, "n as undef returns undef";
		like $warning, qr/undefined argument/, 'floating point n error matches';
		};

	subtest 'too many args' => sub {
		$warning = undef;
		is $cross->nth(1, 2, 3), undef, "too many args returns undef";
		like $warning, qr/too many arguments/, 'floating point n error matches';
		};

	subtest 'large n' => sub {
		$warning = undef;
		is $cross->nth(66), undef, "n larger than cardinality returns undef";
		like $warning, qr/too large/, 'large n error matches';
		};

	subtest 'cardinality' => sub {
		$warning = undef;
		is $cross->nth($cross->cardinality), undef, "n larger than cardinality returns undef";
		like $warning, qr/too large/, 'large n error matches';
		};

	subtest 'negative' => sub {
		$warning = undef;
		is $cross->nth($cross->cardinality), undef, "n below zero returns undef";
		like $warning, qr/less than/, 'large n error matches';
		};

	subtest 'non-whole number' => sub {
		$warning = undef;
		is $cross->nth($cross->cardinality), undef, "n as floating point returns undef";
		like $warning, qr/positive whole number/, 'floating point n error matches';
		};
	};

subtest 'two sets' => sub {
	my $cross = $class->new( [ [1,2,3], [qw(a b c)] ] );
	isa_ok $cross, $class;

	is $cross->cardinality, 9, "Cardinality is expected";

	my @table = (
		[ 0, [ 1, 'a' ] ],
		[ 3, [ 2, 'a' ] ],
		);

	foreach my $row ( @table ) {
		my $tuple = $cross->nth( $row->[0] );
		is_deeply $row->[1], $tuple, 'nth tuple is expected';
		}
	};

subtest 'two sets labeled' => sub {
	my $cross = $class->new( { number => [1,2,3], letter => [qw(a b c)] } );
	isa_ok $cross, $class;

	is $cross->cardinality, 9, "Cardinality is expected";

	my @table = (
		[ 0, { number => 1, letter => 'a' } ],
		[ 3, { number => 1, letter => 'b' } ],
		);

	foreach my $i ( 0 .. $#table ) {
		subtest "row $i" => sub {
			my $tuple = $cross->nth( $table[$i][0] );
			isa_ok $tuple, ref {}, '$tuple';
			is_deeply $table[$i][1], $tuple, 'nth tuple is expected';
			};
		}
	};

subtest 'three sets' => sub {
	my $cross = $class->new([ [1,2,3], [qw(a b c)], [qw(red blue green)] ]);
	isa_ok $cross, $class;

	is( $cross->cardinality, 27, "Cardinality is expected" );

	# figure out what is where:
	# print "COMBOS: " . Dumper( [ map { [ $b++, $_ ] } $cross->combinations ] );
	my @table = (
		[ 0,  [ 1, 'a', 'red'   ] ],
		[ 9,  [ 2, 'a', 'red'   ] ],
		[ 19, [ 3, 'a', 'blue' ] ],
		[ 26, [ 3, 'c', 'green' ] ],
		);

	foreach my $row ( @table ) {
		my $tuple = $cross->nth( $row->[0] );
		is_deeply $row->[1], $tuple, "$row->[0] tuple is expected";
		}
	};

subtest 'four sets' => sub {
	my $cross = $class->new([ [1,2,3], [qw(a b c)], [qw(red blue green)], [qw(cat dog)] ]);
	isa_ok $cross, $class;

	is( $cross->cardinality, 54, "Cardinality is expected" );

	# figure out what is where:
	# print "COMBOS: " . Dumper( [ map { [ $b++, $_ ] } $cross->combinations ] );
	my @table = (
		[ 0,  [ 1, 'a', 'red', 'cat' ] ],
		[ 9,  [ 1, 'b', 'blue', 'dog'   ] ],
		[ 31, [ 2, 'c', 'red', 'dog'  ] ],
		[ 39, [ 3, 'a', 'blue', 'dog'  ] ],
		[ 50, [ 3, 'c', 'blue', 'cat' ] ],
		);

	foreach my $row ( @table ) {
		my $tuple = $cross->nth( $row->[0] );
		is_deeply $row->[1], $tuple, "$row->[0] tuple is expected";
		}
	};

subtest 'iterator' => sub {
	my $cross = $class->new([ [1,2,3], [qw(a b c)], [qw(red blue green)], [qw(cat dog)] ]);
	isa_ok $cross, $class;

	is( $cross->cardinality, 54, "Cardinality is expected" );

	is_deeply scalar $cross->get,    [ 1, 'a', 'red', 'cat' ], 'get gets the first tuple';
	is_deeply scalar $cross->next,   [ 1, 'a', 'red', 'dog' ], 'next sees the second tuple';
	is_deeply scalar $cross->nth(5), [ 1, 'a', 'green', 'dog' ], 'nth(5) get gets sixth tuple';

	# same as before, cursor did not advance
	is_deeply scalar $cross->next,   [ 1, 'a', 'red', 'dog' ], 'next sees the second tuple';
	is_deeply scalar $cross->get,    [ 1, 'a', 'red', 'dog' ], 'get sees the second tuple';
	};

done_testing();
