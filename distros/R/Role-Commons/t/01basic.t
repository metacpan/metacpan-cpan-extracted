use Test::More;

BEGIN {
	package Local::Class;
	use Role::Commons -all;
	our $AUTHORITY = 'http://www.example.com/';
	our $VERSION   = '42.0';
	sub new  { bless [], shift };
	sub bumf { 123 };
}

my $obj = new_ok 'Local::Class';
can_ok $obj => $_ for qw( AUTHORITY tap object_id does );

is(
	Local::Class->AUTHORITY,
	'http://www.example.com/',
	'AUTHORITY get',
);

ok(
	Local::Class->AUTHORITY('http://www.example.com/'),
	'AUTHORITY assert',
);

ok(
	!eval { Local::Class->AUTHORITY('http://www.example.net/') },
	'AUTHORITY assert (failure)',
);

is(
	Local::Class->tap('bumf'),
	'Local::Class',
	'tap',
);

isnt(
	Local::Class->new->object_id,
	Local::Class->new->object_id,
	'object_id',
);

done_testing();

