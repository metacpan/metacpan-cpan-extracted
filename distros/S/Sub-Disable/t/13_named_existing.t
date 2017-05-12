use Test::More;

my $test = 1;
sub foo {$test = 2}

use Sub::Disable {
    sub => ['foo'],
};

foo();
is $test, 1;

main->foo;
is $test, 2;

done_testing;

