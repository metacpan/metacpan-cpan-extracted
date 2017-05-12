use Test::More;
use Sub::Disable {
    sub => ['foo'],
};

my $test = 1;
sub foo {$test = 2}

foo();
is $test, 1;

main->foo;
is $test, 2;

done_testing;

