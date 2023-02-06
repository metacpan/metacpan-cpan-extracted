use Test::More;
use lib 't/lib';
use TestAppController;

my $test = TestAppController->new();
$test->thing = "okay";
is($test->thing, "okay");
$test->other = { test => "okay" };
is($test->other->test, "okay");

done_testing();
