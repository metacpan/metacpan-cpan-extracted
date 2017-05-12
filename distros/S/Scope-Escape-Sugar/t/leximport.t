use warnings;
use strict;

BEGIN {
	eval { require Lexical::Import };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Lexical::Import unavailable");
	}
}

use Test::More tests => 4;

use Lexical::Import "Scope::Escape::Sugar", qw(
	with_escape_function with_escape_continuation
	block return_from
	catch throw
);

is_deeply [sub{
	with_escape_function $c;
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	with_escape_continuation $c;
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	block c;
	return_from c 22, 33;
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	catch "c";
	throw "c", 22, 33;
	ok 0;
}->()], [22, 33];

1;
