use warnings;
use strict;

use Test::More tests => 15;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my($cont, @value, $mbv);

$cont = undef; @value = (); $mbv = undef;
@value = eval {
	is_deeply [sub {
		$cont = current_escape_function;
		("b0", "b1");
	}->()], ["b0", "b1"];
	$mbv = Scope::Escape::Continuation::may_be_valid($cont);
	$cont->("c0", "c1");
	("d0", "d1");
};
like $@, qr/\Aattempt to use invalid continuation/;
is $mbv, !!0;
is_deeply [@value], [];

$cont = undef; @value = (); $mbv = undef;
@value = eval {
	is_deeply [sub {
		$cont = current_escape_function;
		$cont->("a0", "a1");
		("b0", "b1");
	}->()], ["a0", "a1"];
	$mbv = Scope::Escape::Continuation::may_be_valid($cont);
	$cont->("c0", "c1");
	("d0", "d1");
};
like $@, qr/\Aattempt to use invalid continuation/;
is $mbv, !!0;
is_deeply [@value], [];

$cont = undef; @value = (); $mbv = undef;
@value = eval {
	sub {
		$cont = current_escape_function;
		Scope::Escape::Continuation::invalidate($cont);
		$mbv = Scope::Escape::Continuation::may_be_valid($cont);
		$cont->("a0", "a1");
		("b0", "b1");
	}->();
	ok 0;
};
like $@, qr/\Aattempt to use invalid continuation/;
is $mbv, !!0;
is_deeply [@value], [];

$cont = undef; @value = (); $mbv = undef;
@value = eval {
	sub {
		$cont = current_escape_function;
		Scope::Escape::Continuation::invalidate($cont);
		Scope::Escape::Continuation::invalidate($cont);
		$mbv = Scope::Escape::Continuation::may_be_valid($cont);
		$cont->("a0", "a1");
		("b0", "b1");
	}->();
	ok 0;
};
like $@, qr/\Aattempt to use invalid continuation/;
is $mbv, !!0;
is_deeply [@value], [];

1;
