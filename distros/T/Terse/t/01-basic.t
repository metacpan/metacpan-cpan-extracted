use Test::More;
use Terse;

my $test = Terse->new();
$test->thing = "okay";
is($test->thing, "okay");
$test->other = { test => "okay" };
is($test->other->test, "okay");

done_testing();
