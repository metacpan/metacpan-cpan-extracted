use Test::More;
use Sub::Disable 'foo';

my $test = 1;
sub foo {$test = 2}
sub bar {$test = 3}

foo(bar());

is $test, 1;

main->foo(bar());

is $test, 1;

done_testing;

