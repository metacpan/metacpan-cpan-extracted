use strict;
use warnings;
use Test::More;
use Test::Fatal;

use MooX::Press ();
use Types::Standard -types;

my $code = MooX::Press->wrap_coderef({
	signature        => [ Int->plus_coercions(Num, q{int($_)}), Str ],
	invocant_count   => 2,
	code             => 'sub { [ __PACKAGE__, @_ ] }',
	optimize         => !!1,
	caller           => 'Foo',
});

is_deeply(
	$code->([], [], 1.1, "hi"),
	[ "Foo", [], [], 1, "hi" ],
);

isnt(
	exception { $code->(1.1, "hi") },
	undef,
);

done_testing;
