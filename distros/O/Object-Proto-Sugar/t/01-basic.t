use Test::More;

{
	package Test;

	use Object::Proto::Sugar;
		
	has taste => (
	  is => 'ro',
	);

	has brand => (
	  is  => 'rw',
	  isa => sub {
	    die "Only sweet supported!" unless $_[0] eq 'sweet'
	  },
	);

	has pounds => (
	  is  => 'rw',
	  isa => sub { die "$_[0] is too much cat food!" unless $_[0] < 15 },
	);

	1;
}

package main;

my $test = new Test "sour", "sweet", 10;

is($test->taste, "sour", "expects sour");
is($test->brand, "sweet", "expects sweet");
is($test->pounds, 10, "expects pounds");

eval {
	$test->taste('sweet');
};
like ($@, qr/readonly/, "Should die when setting as readonly");

eval {
	$test->brand('sour');
};
like ($@, qr/Only sweet supported/, "Should die when setting a value that is not sweet");

eval {
	 new Test "sweet", "sour", 5;
};
like ($@, qr/Only sweet supported/, "Should die early");




done_testing();
