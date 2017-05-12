# 2_sense_sim.t version 0.02
# (Updated 04/29/2006 -- Anagha)
#
# A script to run tests on the Statistics::Gap module.
# This test cases check for 2 sense input matrix.
# The following are among the tests run by this script:
# 1. Try loading the Statistics::Gap i.e. is it added to the @INC variable
# 2. Compare the answer returned by the Gap Statistics with the actual andwer

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Statistics::Gap') };

# optimal number of clusters for the above input data
my $ans = 2;

my $result = 0;
$result = &gap("pre_2_sim", "sim", "t/2_senses_sim", "rb", "e1", 10, 15, "rep", 80, 4);

is($result, $ans, "Comparing Gap Statistics' answer ($result) with the actual optimal number of clusters ($ans) for the input data");

if(-e "pre_2_sim.gap.log")
{
	is("exists","exists");
}
else
{
	is("does not exist pre_2_sim_sim.gap.log","exist");
}

if(-e "pre_2_sim.obs.dat")
{
	is("exists","exists");
}
else
{
	is("does not exist obs","exist");
}

if(-e "pre_2_sim.exp.dat")
{
	is("exists","exists");
}
else
{
	is("does not exist exp","exist");
}

unlink "pre_2_sim.gap.log", "pre_2_sim.obs.dat","pre_2_sim.exp.dat","pre_2_sim.gap.dat";

__END__
