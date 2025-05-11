use Test::More;

{
	package One;
	use Moo;
	use Data::Dumper;

	use MooX::Keyword extends => '+Readonly';

	readonly "one";

	readonly thing => ( is => 'rw' );

	readonly built => ( 
		builder => sub {
			return { a => 'builder' };
		}
	);

	1;
}


{
	package Two;

	use Moo;
	use MooX::Keyword extends => 'One';
	
	readonly "thing" => ( is => 'ro' );

}

my $n = One->new({thing => { a => 1, b => 2, c => 3 }, one => [qw/1 2 3/]});

is_deeply($n->one, [qw/1 2 3/]);

eval {
	push @{$n->one}, 4;
};

like($@, qr/Modification of a read-only value attempted/);

is_deeply($n->thing, { a => 1, b => 2, c => 3 });

eval {
	$n->thing->{d} = 4;
};

like($@, qr/Attempt to access disallowed key 'd' in a restricted hash/);

$n->thing({ a => 1 });

is_deeply($n->thing, { a => 1 });

eval {
	$n->thing->{d} = 4;
};

like($@, qr/Attempt to access disallowed key 'd' in a restricted hash/);

$n = Two->new({thing => { a => 1, b => 2, c => 3 }, one => [qw/1 2 3/]});

eval {
	$n->thing({ a => 1 });
};

like($@, qr/(Usage\: Two\:\:thing\(self\))|(thing is a read-only accessor)/);

done_testing();

