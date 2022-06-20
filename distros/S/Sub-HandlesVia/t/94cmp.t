use strict;
use warnings;
use Test::More;
{ package Local::Dummy; use Test::Requires { 'Moo' => '1.006' } };

{
	package Local::Class;
	use Moo;
	use Sub::HandlesVia;
	has my_num => (
		is          => 'rw',
		handles_via => 'Number',
		handles     => {
			map { 1; "my_num_$_" => $_ }
				qw( cmp eq ne lt gt le ge )
		},
		default     => 0,
	);
	has my_str => (
		is          => 'rw',
		handles_via => 'String',
		handles     => {
			( map { 1; "my_str_$_" => $_ }
				qw( uc lc fc ) ),
			( map { 1; "my_str_$_" => $_, "my_str_$_".'_i' => $_.'_i' }
				qw( match contains starts_with ends_with ) ),
			( map { 1; "my_str_$_" => $_, "my_str_$_".'i' => $_.'i' }
				qw( cmp eq ne lt gt le ge ) ),
		},
		default     => '',
	);
}

my $object = 'Local::Class'->new;
my $ok     = !!1;
my $notok  = !!0;

my @cases = (
	[ my_str => eq  => ( 'foo', 'foo' ) => $ok    ],
	[ my_str => eq  => ( 'foo', 'bar' ) => $notok ],
	[ my_str => ne  => ( 'foo', 'foo' ) => $notok ],
	[ my_str => ne  => ( 'foo', 'bar' ) => $ok    ],
	[ my_str => cmp => ( 'foo', 'foo' ) => $notok ],
	[ my_str => cmp => ( 'foo', 'bar' ) => $ok    ],
	[ my_str => cmp => ( 'foo', 'xyz' ) => $ok    ],
	[ my_str => lt  => ( 'foo', 'foo' ) => $notok ],
	[ my_str => lt  => ( 'foo', 'bar' ) => $notok ],
	[ my_str => lt  => ( 'foo', 'xyz' ) => $ok    ],
	[ my_str => le  => ( 'foo', 'foo' ) => $ok    ],
	[ my_str => le  => ( 'foo', 'bar' ) => $notok ],
	[ my_str => le  => ( 'foo', 'xyz' ) => $ok    ],
	[ my_str => gt  => ( 'foo', 'foo' ) => $notok ],
	[ my_str => gt  => ( 'foo', 'bar' ) => $ok    ],
	[ my_str => gt  => ( 'foo', 'xyz' ) => $notok ],
	[ my_str => ge  => ( 'foo', 'foo' ) => $ok    ],
	[ my_str => ge  => ( 'foo', 'bar' ) => $ok    ],
	[ my_str => ge  => ( 'foo', 'xyz' ) => $notok ],

	[ my_str => eq  => ( 'foo', 'FOO' ) => $notok ],
	[ my_str => ne  => ( 'foo', 'FOO' ) => $ok    ],
	[ my_str => eqi => ( 'foo', 'FOO' ) => $ok    ],
	[ my_str => nei => ( 'foo', 'FOO' ) => $notok ],

	[ my_num => eq  => ( 42, 42 ) => $ok    ],
	[ my_num => eq  => ( 42, 18 ) => $notok ],
	[ my_num => ne  => ( 42, 42 ) => $notok ],
	[ my_num => ne  => ( 42, 18 ) => $ok    ],
	[ my_num => cmp => ( 42, 42 ) => $notok ],
	[ my_num => cmp => ( 42, 18 ) => $ok    ],
	[ my_num => cmp => ( 42, 69 ) => $ok    ],
	[ my_num => lt  => ( 42, 42 ) => $notok ],
	[ my_num => lt  => ( 42, 18 ) => $notok ],
	[ my_num => lt  => ( 42, 69 ) => $ok    ],
	[ my_num => le  => ( 42, 42 ) => $ok    ],
	[ my_num => le  => ( 42, 18 ) => $notok ],
	[ my_num => le  => ( 42, 69 ) => $ok    ],
	[ my_num => gt  => ( 42, 42 ) => $notok ],
	[ my_num => gt  => ( 42, 18 ) => $ok    ],
	[ my_num => gt  => ( 42, 69 ) => $notok ],
	[ my_num => ge  => ( 42, 42 ) => $ok    ],
	[ my_num => ge  => ( 42, 18 ) => $ok    ],
	[ my_num => ge  => ( 42, 69 ) => $notok ],
);

for my $case ( @cases ) {
	my ( $attr, $cmp, $val1, $val2, $truth ) = @$case;
	my $cmp_method = sprintf( '%s_%s', $attr, $cmp );
	my $desc = sprintf( '$object->%s("%s")->%s("%s")', $attr, $val1, $cmp_method, $val2 );
	
	$object->$attr( $val1 );
	if ( $truth ) {
		ok(
			$object->$cmp_method( $val2 ),
			"ok  $desc",
		);
	}
	else {
		ok(
			!$object->$cmp_method( $val2 ),
			"ok !$desc",
		);
	}
}

$object->my_str( 'Foo' );

is(
	$object->my_str_uc,
	'FOO',
	'$object->my_str_uc',
);

is(
	$object->my_str_lc,
	'foo',
	'$object->my_str_lc',
);

ok(
	!$object->my_str_match_i('BAR'),
	'!$object->my_str_match_i(Str)',
);

ok(
	$object->my_str_match_i('FOO'),
	'$object->my_str_match_i(Str)',
);

ok(
	$object->my_str_match_i(qr/FOO/i),
	'$object->my_str_match_i(RegexpRef)',
);

ok(
	$object->my_str_starts_with('F') &&
		!$object->my_str_starts_with('X') &&
		!$object->my_str_starts_with('f'),
	'$object->my_str_starts_with',
);

ok(
	$object->my_str_starts_with_i('F') &&
		!$object->my_str_starts_with_i('X') &&
		$object->my_str_starts_with_i('f'),
	'$object->my_str_starts_with_i',
);

ok(
	$object->my_str_ends_with('o') &&
		!$object->my_str_ends_with('X') &&
		!$object->my_str_ends_with('O'),
	'$object->my_str_ends_with',
);

ok(
	$object->my_str_ends_with_i('o') &&
		!$object->my_str_ends_with_i('X') &&
		$object->my_str_ends_with_i('O'),
	'$object->my_str_ends_with_i',
);

ok(
	$object->my_str_contains('F') &&
		$object->my_str_contains('o') &&
		$object->my_str_contains('Fo') &&
		$object->my_str_contains('oo') &&
		$object->my_str_contains('Foo') &&
		!$object->my_str_contains('f') &&
		!$object->my_str_contains('X'),
	'$object->my_str_contains',
);

ok(
	$object->my_str_contains_i('F') &&
		$object->my_str_contains_i('o') &&
		$object->my_str_contains_i('Fo') &&
		$object->my_str_contains_i('oo') &&
		$object->my_str_contains_i('Foo') &&
		$object->my_str_contains_i('f') &&
		$object->my_str_contains_i('Oo') &&
		$object->my_str_contains_i('oO') &&
		!$object->my_str_contains_i('X'),
	'$object->my_str_contains_i',
);

done_testing;
