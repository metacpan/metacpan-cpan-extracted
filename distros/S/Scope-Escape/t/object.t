use warnings;
use strict;

use Test::More tests => 36;

BEGIN { use_ok "Scope::Escape", qw(
	current_escape_function current_escape_continuation
); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

is_deeply [sub{
	my $c = current_escape_function;
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = current_escape_continuation;
	$c->(22, 33);
	ok 0;
}->()], [22, 33];

sub{
	my $c = current_escape_function;
	is ref($c), "CODE";
}->();

sub{
	my $c = current_escape_continuation;
	is ref($c), "Scope::Escape::Continuation";
}->();

is_deeply [sub{
	my $c = current_escape_function;
	Scope::Escape::Continuation::go($c, 22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = current_escape_continuation;
	Scope::Escape::Continuation::go($c, 22, 33);
	ok 0;
}->()], [22, 33];

is_deeply [sub{
	my $c = current_escape_continuation;
	$c->go(22, 33);
	ok 0;
}->()], [22, 33];

eval { Scope::Escape::Continuation::go(sub{}, 22, 33); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

is_deeply [sub{
	my $c = current_escape_function;
	Scope::Escape::Continuation::wantarray($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	Scope::Escape::Continuation::wantarray($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	$c->wantarray();
}->()], [!!1];

eval { Scope::Escape::Continuation::wantarray(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

is_deeply [sub{
	my $c = current_escape_function;
	Scope::Escape::Continuation::is_accessible($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	Scope::Escape::Continuation::is_accessible($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	$c->is_accessible();
}->()], [!!1];

eval { Scope::Escape::Continuation::is_accessible(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

{
	my $c;
	sub {
		$c = current_escape_function;
		ok Scope::Escape::Continuation::may_be_valid($c);
	}->();
	ok !Scope::Escape::Continuation::may_be_valid($c);
}

{
	my $c;
	sub {
		$c = current_escape_continuation;
		ok Scope::Escape::Continuation::may_be_valid($c);
	}->();
	ok !Scope::Escape::Continuation::may_be_valid($c);
}

{
	my $c;
	sub {
		$c = current_escape_continuation;
		ok $c->may_be_valid;
	}->();
	ok !$c->may_be_valid;
}

eval { Scope::Escape::Continuation::may_be_valid(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

sub {
	my $c = current_escape_function;
	Scope::Escape::Continuation::invalidate($c);
	ok !Scope::Escape::Continuation::may_be_valid($c);
}->();

sub {
	my $c = current_escape_continuation;
	Scope::Escape::Continuation::invalidate($c);
	ok !Scope::Escape::Continuation::may_be_valid($c);
}->();

sub {
	my $c = current_escape_continuation;
	$c->invalidate;
	ok !Scope::Escape::Continuation::may_be_valid($c);
}->();

eval { Scope::Escape::Continuation::invalidate(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

is_deeply [sub{
	my $c = current_escape_function;
	!!Scope::Escape::Continuation::as_function($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	!!Scope::Escape::Continuation::as_function($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	!!$c->as_function();
}->()], [!!1];

eval { Scope::Escape::Continuation::as_function(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

is_deeply [sub{
	my $c = current_escape_function;
	!!Scope::Escape::Continuation::as_continuation($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	!!Scope::Escape::Continuation::as_continuation($c);
}->()], [!!1];

is_deeply [sub{
	my $c = current_escape_continuation;
	!!$c->as_continuation();
}->()], [!!1];

eval { Scope::Escape::Continuation::as_continuation(sub{}); };
like $@, qr/\AScope::Escape::Continuation method invoked on wrong type of /;

1;
