use Test::More;
use Sub::Disable method => ['foo'];

my $test = 1;
sub foo {$test = 2}

main->foo;
is $test, 1;

foo();
is $test, 2;

done_testing;

