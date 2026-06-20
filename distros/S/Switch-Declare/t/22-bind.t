use strict;
use warnings;
use Test::More;
use Switch::Declare;

# `case PATTERN -> [..] { }` destructures the matched topic into lexicals that
# are visible inside (and private to) the arm block.

# array binding with a slurpy tail
{
	my $v = [1, 2, 3, 4];
	my $r = switch ($v) {
		case ref(ARRAY) -> [$head, @rest] { "$head:@rest" }
		default { 'no' }
	};
	is($r, '1:2 3 4', 'array binding + slurpy tail');
}

# hash binding with %rest
{
	my $v = { name => 'Ann', age => 30, role => 'dev' };
	my $r = switch ($v) {
		case ref(HASH) -> {name => $n, %meta} {
			"$n/" . join(',', map {"$_=$meta{$_}"} sort keys %meta)
		}
		default { 'no' }
	};
	is($r, 'Ann/age=30,role=dev', 'hash binding + %rest');
}

# nested pattern, default, and a hole
{
	my $rec = { pos => [10], tags => ['x', 'y'] };
	my @got;
	switch ($rec) {
		case ref(HASH) -> {pos => [$px, $py = -1], tags => [undef, $second]} {
			@got = ($px, $py, $second);
		}
		default { }
	};
	is_deeply(\@got, [10, -1, 'y'], 'nested + default + hole in a binding');
}

# the topic is evaluated/captured once even with many bindings
{
	my $calls = 0;
	my $obj   = { get => sub { $calls++; [1, 2, 3] } };
	switch ($obj->{get}->()) {
		case ref(ARRAY) -> [$a, $b, $c] {
			is("$a$b$c", '123', 'all three bound');
		}
		default { }
	};
	is($calls, 1, 'topic evaluated exactly once');
}

# bound names are private to the arm: no leak, no clobber of an outer lexical
{
	my $x = 'outer';
	switch ([99]) {
		case ref(ARRAY) -> [$x] { is($x, 99, 'inner $x is the bound value') }
		default { }
	};
	is($x, 'outer', 'outer $x untouched after the arm');
}

# the same variable name may be bound in several arms without collision
{
	for my $pair ([['A', 'B'], 'arr A/B'], [{k => 'Z'}, 'hash Z']) {
		my ($v, $want) = @$pair;
		my $r = switch ($v) {
			case ref(ARRAY) -> [$a, $b] { "arr $a/$b" }
			case ref(HASH)  -> {k => $a} { "hash $a" }
			default { '?' }
		};
		is($r, $want, "reused name across arms: $want");
	}
}

# a non-matching arm does not run its bindings; control falls through
{
	my $r = switch ('plain') {
		case ref(ARRAY) -> [$a] { "array $a" }
		default { 'fell through' }
	};
	is($r, 'fell through', 'binding arm skipped when it does not match');
}

# error: a list pattern is not allowed in a case binding
{
	local $@;
	my $ok = eval 'use Switch::Declare;
		sub { switch ($_[0]) { case 1 -> ($a) { } default { } } }; 1';
	ok(!$ok, 'list pattern rejected in case binding');
}

done_testing;
