use warnings;
use strict;

BEGIN {
	eval { require Lexical::Import };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Lexical::Import unavailable");
	}
}

use Test::More tests => 2;

use Lexical::Import "Scope::Escape",
	qw(current_escape_function current_escape_continuation);

is_deeply [sub{
	my $c = current_escape_function;
	$c->(ref($c), 22, 33);
	ok 0;
}->()], ["CODE", 22, 33];

is_deeply [sub{
	my $c = current_escape_continuation;
	$c->(!!$c->isa("Scope::Escape::Continuation"), 22, 33);
	ok 0;
}->()], [!!1, 22, 33];

1;
