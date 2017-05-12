use warnings;
use strict;

use Test::More tests => 47;

BEGIN {
	use_ok "Scope::Escape",
		qw(current_escape_function current_escape_continuation);
}

BEGIN { Scope::Escape::_set_sanity_checking(1); }

foreach(0,1) {
	my $f;
	if($_ == 0) {
		$f = current_escape_function;
	} else {
		my $c = current_escape_continuation;
		ok $c->isa("Scope::Escape::Continuation");
		$f = Scope::Escape::Continuation::as_function($c);
		$c = undef;
	}
	ok ref($f) eq "CODE";
	my $f1 = Scope::Escape::Continuation::as_function($f);
	ok $f1 == $f;
	my $f2 = Scope::Escape::Continuation::as_function($f);
	ok $f2 == $f;
	my $c1 = Scope::Escape::Continuation::as_continuation($f);
	ok $c1 != $f;
	ok $c1->isa("Scope::Escape::Continuation");
	my $c2 = Scope::Escape::Continuation::as_continuation($f);
	ok $c2 == $c1;
	my $f3 = Scope::Escape::Continuation::as_function($c1);
	ok $f3 == $f;
	my $f4 = Scope::Escape::Continuation::as_function($c1);
	ok $f4 == $f;
	my $c3 = Scope::Escape::Continuation::as_continuation($c1);
	ok $c3 == $c1;
	my $c4 = Scope::Escape::Continuation::as_continuation($c1);
	ok $c4 == $c1;
}

foreach(0,1) {
	my $c;
	if($_ == 0) {
		$c = current_escape_continuation;
	} else {
		my $f = current_escape_function;
		ok ref($f) eq "CODE";
		$c = Scope::Escape::Continuation::as_continuation($f);
		$f = undef;
	}
	ok $c->isa("Scope::Escape::Continuation");
	my $c1 = Scope::Escape::Continuation::as_continuation($c);
	ok $c1 == $c;
	my $c2 = Scope::Escape::Continuation::as_continuation($c);
	ok $c2 == $c;
	my $f1 = Scope::Escape::Continuation::as_function($c);
	ok $f1 != $c;
	ok ref($f1) eq "CODE";
	my $f2 = Scope::Escape::Continuation::as_function($c);
	ok $f2 == $f1;
	my $c3 = Scope::Escape::Continuation::as_continuation($f1);
	ok $c3 == $c;
	my $c4 = Scope::Escape::Continuation::as_continuation($f1);
	ok $c4 == $c;
	my $f3 = Scope::Escape::Continuation::as_function($f1);
	ok $f3 == $f1;
	my $f4 = Scope::Escape::Continuation::as_function($f1);
	ok $f4 == $f1;
}

is_deeply [sub{
	my $c = Scope::Escape::Continuation::as_function(
			current_escape_function);
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = Scope::Escape::Continuation::as_function(
			current_escape_continuation);
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = Scope::Escape::Continuation::as_continuation(
			current_escape_function);
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = Scope::Escape::Continuation::as_continuation(
			current_escape_continuation);
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

1;
