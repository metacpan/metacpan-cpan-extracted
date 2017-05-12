# 3_sense.t version 0.02
# (Updated 04/26/2006 -- Anagha)
#
# A script to run tests on the Statistics::Gap module.
# This test cases check for 3 sense input matrix.
# The following are among the tests run by this script:
# 1. Try loading the Statistics::Gap i.e. is it added to the @INC variable
# 2. Compare the answer returned by the Gap Statistics with the actual answer

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Statistics::Gap') };

# optimal number of clusters for the above input data
my $ans = 3;

my $result = 0;
$result = &gap("pre_3", "vec", "t/3_senses", "rbr", "h2", 5, 30, "rep", 80, 4);

is($result, $ans, "Comparing Gap Statistics' answer ($result) with the actual optimal number of clusters ($ans) for the input data");

if(-e "pre_3.gap.log")
{
	is("exists","exists");
}
else
{
	is("does not exist pre_3.gap.log","exist");
}

if(-e "pre_3.obs.dat")
{
	is("exists","exists");
}
else
{
	is("does not exist obs","exist");
}

if(-e "pre_3.exp.dat")
{
	is("exists","exists");
}
else
{
	is("does not exist exp","exist");
}

unlink "pre_3.gap.log", "pre_3.obs.dat","pre_3.exp.dat","pre_3.gap.dat";

__END__
