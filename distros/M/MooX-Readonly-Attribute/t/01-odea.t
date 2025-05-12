use Test::More;

{
	package Test;
	
	use Moo;
	use MooX::Readonly::Attribute;

	has hash => (
		is => 'rw',
		readonly => 1,
		default => sub {
			return { a => 1, b => 2, c => 3 };
		}
	);

	has array => (
		is => 'rw',
		readonly => 1,
		default => sub {
			return [ qw/1 2 3/ ];
		}
	);

	has coerce => (
		is => 'rw',
		readonly => 1,
		coerce => sub { ref $_[0] eq 'ARRAY' ? $_[0]->[0] : $_[0] },
		default => sub { [ { a => 1 } ] }
	);


	1;
}

ok(my $test = Test->new);

is_deeply($test->hash, { a => 1, b => 2, c => 3 });
is_deeply($test->array, [qw/1 2 3/]);

eval { push @{ $test->array }, 4; };

like($@, qr/Modification of a read-only value attempted/);

is_deeply($test->array, [qw/1 2 3/]);

eval {$test->hash->{a} = 4; };

like($@, qr/Modification of a read-only value attempted/);

is_deeply($test->coerce, { a => 1 } );

eval { $test->coerce->{a} = 4; };

like($@, qr/Modification of a read-only value attempted/);

ok($test->hash({ d => 4 }));

is_deeply($test->hash, { d => 4 });

eval { $test->hash->{a} };

like($@, qr/Attempt to access disallowed key 'a' in a restricted hash/);

ok($test->array([qw/4 5 6/]));

is_deeply($test->array, [qw/4 5 6/]);

eval { $test->array->[4] = 7  };

like($@, qr/Modification of a read-only value attempted/);

ok($test->coerce([{ b => 2}]));

is($test->coerce->{b}, 2);

eval { delete $test->coerce->{b} };

like($@, qr/Attempt to delete readonly key \'b\' from a restricted hash/);

is(exists $test->coerce->{a} ? 1 : 0, 0);

done_testing();
