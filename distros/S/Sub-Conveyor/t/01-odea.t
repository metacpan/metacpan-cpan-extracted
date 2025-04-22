use Test::More;

use Sub::Conveyor;
use Types::Standard qw/Str Int StrMatch Any/;

my $conveyor = Sub::Conveyor->new();

$conveyor->add(Int, sub { return $_[0] });

$conveyor->add(StrMatch[qr{^[a-zA-Z]+$}], sub { return $_[0] . ' World' });

$conveyor->add(Int, sub { return $_[0] / 2 });

is($conveyor->call(100), 50);

is($conveyor->call('Hello'), 'Hello World');

is_deeply($conveyor->call({ one => 1 }), { one => 1 });

my $conveyor2 = Sub::Conveyor->new(
	[ Int ] => sub { return $_[0] },
	[ Str, Int ] => sub { return length($_[0]) + $_[1] },
	[ StrMatch[qr{^[a-zA-Z]+$}] ] => sub { return length $_[0] },
	[ Int ] => sub { return $_[0] / 2 },
	[ Any ] => sub { return $_[0] . ' World' }
);

is($conveyor2->call(100), '50 World');
is($conveyor2->call('ABC', 7), '5 World');
is($conveyor2->call('Hello'), '2.5 World');

done_testing();
