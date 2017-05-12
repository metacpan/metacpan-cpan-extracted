# fake tests for testing the testing of tests module... you're still following?
use Test::More tests => 10;

foreach (1..10) {
    $_ % 2 == 0 ?  pass("pass$_") : fail("fail$_");
}

