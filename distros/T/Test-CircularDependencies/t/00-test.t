use strict;
use warnings;

use Test::Builder::Tester tests => 1;
use Test::CircularDependencies qw(test_loops);

test_out("not ok 1 - circle");
my $err = q{#   Failed test 'circle'
#   at t/00-test.t line 13.
# Loop found: MyA MyB MyC MyA};
test_err($err);

test_loops(['t/circular_dependency/my_exe.pl'], ['t/circular_dependency'], 'circle');
test_test("test_loops works");
