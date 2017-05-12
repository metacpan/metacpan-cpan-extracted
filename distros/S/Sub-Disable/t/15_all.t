use Test::More;
use Sub::Disable 'foo', 'bar';

my $test = 1;
sub foo {$test = 2}
sub bar {$test = 3}

main->foo;
is $test, 1;

foo();
is $test, 1;

bar();
is $test, 1;

main->bar;
is $test, 1;

done_testing;

