use Test::More;

{
	package Testing;

	sub new {
		bless {}, $_[0];
	}

	1;
}

use Sub::Conveyor;
use Types::Standard qw/Int StrMatch Any/;

my $conveyor = Sub::Conveyor->new();

$conveyor->add(Int, sub { return $_[0] });

$conveyor->add(StrMatch[qr{^[a-zA-Z]+$}], sub { return $_[0] . ' World' });

$conveyor->add(Int, sub { return $_[0] / 2 });

is($conveyor->call(100), 50);

is($conveyor->call('Hello'), 'Hello World');

is_deeply($conveyor->call({ one => 1 }), { one => 1 });

$conveyor->install('Testing', 'test');

is(Testing->test(100), 50);

my $test = Testing->new();

is($test->test(100), 50);

done_testing();
