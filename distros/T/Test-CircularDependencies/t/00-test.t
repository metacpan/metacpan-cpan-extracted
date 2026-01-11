use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::CircularDependencies qw(test_loops);

test_out('not ok 1 - circle');
my $err1 = q{#   Failed test 'circle'
#   at t/00-test.t line 13.
# Loop found: MyA MyB MyC MyA};
test_err($err1);

test_loops( ['t/circular_dependency/my_exe.pl'], ['t/circular_dependency'], 'circle' );
test_test('test_loops works');

test_out('not ok 1 - deep');
my $err2 = q{#   Failed test 'deep'
#   at t/00-test.t line 24.
# Loop found: ModuleA ModuleB ModuleA
# Loop found: ModuleA My::ModuleC ModuleD ModuleB ModuleA};

test_err($err2);

test_loops( ['t/deep/my_exe.pl'], [ 't/deep', 't/deep/My' ], 'deep' );
test_test('test_loops works');

