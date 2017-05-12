# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Parallel-parallel_map.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('Parallel::parallel_map') };

#########################

test2x2();

# if parallel_map is called in scalar or void context it does not bother to return results
# so you avoid IPC data exchange and temporary files
my $result = parallel_map {$_} 1..32;
is($result,undef,'parallel_map does not want result context');

sub test2x2 {
    print "***Testing school 2x2\n";
    for my $n (4,16,64,256,1024) {
    my @data = 1..$n;
    my @result = parallel_map {$_*2} @data;
    ok(@result == $n,"n*2[$n] length");
    my $expected = join(",",map $_*2,1..$n);
    my $got = join(",",@result);
    is($got,$expected,"n*2[$n] values");
	}
}
