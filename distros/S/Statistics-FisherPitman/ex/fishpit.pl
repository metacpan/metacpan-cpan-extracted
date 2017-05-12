
print "Example of Fisher-Pitman test from Berry & Mielke (2002)\n";

print "The following (real) data are lead values (in mg/kg) of soil samples from two districts in New Orleans,\none from school grounds, another from surrounding streets.\nWas there a significant difference in lead levels between the samples?\nThe variances were determined to be unequal, and the Fisher-Pitman test put to the question.\nAs there were over 100 billion possible permutations of the data, a large number of resamplings was used: 10 million.\n\nThe following shows how the test would be performed with Statistics::FisherPitman;\nusing a smaller number of resamplings produces much the same result.\nA test of equality of variances is also shown.\n";

print "\nThe data:\n";

my @dist1 = (qw/16.0 34.3 34.6 57.6 63.1 88.2 94.2 111.8 112.1 139.0 165.6 176.7 216.2 221.1 276.7 362.8 373.4 387.1 442.2 706.0/);
my @dist2 = (qw/4.7 10.8 35.7 53.1 75.6 105.5 200.4 212.8 212.9 215.2 257.6 347.4 461.9 566.0 984.0 1040.0 1306.0 1908.0 3559.0 21679.0/);

print "District 1: ", join(" ", @dist1), "\n";
print "District 2: ", join(" ", @dist2), "\n";

print "\n\trequire Statistics::ANOVA;\n\tmy \$anova = Statistics::ANOVA->new();\n\t\$anova->load_data({dist1 => [\@dist1], dist2 => [\@dist2]});\n\t\$anova->levene_test()->dump(title => \"Levene\'s test for equality of variances\");\n\n";
# First test equality of variances:
require Statistics::ANOVA;
my $anova = Statistics::ANOVA->new();
$anova->load_data({dist1 => \@dist1, dist2 => \@dist2});
$anova->levene_test()->dump(title => "Levene's test for equality of variances");
# This prints: F(1, 38) = 4.87100593921132, p = 0.0344251996755789
# Being significantly different by this test ...

print "\n\trequire Statistics::FisherPitman;\n\tmy \$fishpit = Statistics::FisherPitman->new();\n\t\$fishpit->load_data({dist1 => [\@dist1], dist2 => [\@dist2]});\n\t\$fishpit->test(resamplings => 10000)->dump(title => \"Fisher-Pitman test of difference:\", conf_int => 1, precision_p => 3);\n\n";
use Statistics::FisherPitman .02;
my $fishpit = Statistics::FisherPitman->new();
$fishpit->load_data({dist1 => \@dist1, dist2 => \@dist2});
$fishpit->test(resamplings => 10000)->dump(title => "Fisher-Pitman test of difference:", conf_int => 1, precision_p => 3);
# This prints, e.g: T = 56062045.0525, p = 0.0145
print "\n\nHow did the means differ?\n";
 
print "District 1 mean = ", $fishpit->{'data'}->{'dist1'}->mean(), "\n";
print "District 2 mean = ", $fishpit->{'data'}->{'dist2'}->mean(), "\n";
