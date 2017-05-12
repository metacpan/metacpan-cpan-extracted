package Test::Test::Able::Runner::Hickory;
use Test::Able;
use Test::Simple;

test plan => 1, a_test => sub {
    ok(1, 'a passing test!');
};

1;
