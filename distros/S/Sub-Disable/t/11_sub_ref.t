use Test::More;
use Sub::Disable;

my $test = 1;
sub foo {$test = 2}

BEGIN{
    Sub::Disable::disable_cv_call(\&foo);
}

foo();
is $test, 1;

main->foo;
is $test, 2;

done_testing;

