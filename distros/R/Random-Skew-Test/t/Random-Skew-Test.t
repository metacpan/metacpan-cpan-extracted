# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Random-Skew-Test.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Random::Skew::Test') };

#########################

my @test = Random::Skew::Test->sample(
    iter => 100,
    skew => { alpha => 40, beta => 32, gamma => 25, omega => 1 },
    grain => [ qw/10 99/ ],
    round => [ qw/.25 .75/ ],
);
ok(grep(/\.\.\.and smaller/,@test) == 2,'Recursive bucket-set ok');
ok(grep(/Grain=10/,@test) == 2,'Tested coarse grain');
ok(grep(/Grain=99/,@test) > 0 ,'Tested finer grain'); # grain>tot, rounding is moot
ok(grep(/Rounding=\+\.75/,@test) > 0 ,'Tested .75 round-up');
ok(grep(/Rounding=\+\.25/,@test) > 0 ,'Tested .25 round-up');

@test = Random::Skew::Test->sample(
    iter => 1, # one iteration guarantees an un-represented (null) bucket
    skew => { this => 7, that => 1 },
    grain => [ qw/10/ ],
    round => [ qw/0/ ],
);
ok(grep(/there is a bucket not represented/,@test) == 1,'Null bucket warning');
ok(grep(/ratio product:\s+0\n/,@test) == 1,'Zero product from null bucket');

done_testing();

