# fake tests for testing the testing of tests module... you're still following?
use Test::More tests => 10;

foreach (1..10) {
    pass("pass$_");
}

