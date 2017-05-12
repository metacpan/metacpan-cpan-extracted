#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Statistics::Descriptive;

my @data=(
    601,449,424,568,569,447,425,621,616,573,584,635,480,437,724,711,
    717,576,724,585,458,752,753,709,584,748,628,483,739,747,694,601,
    758,653,487,720,750,660,588,719,631,492,584,647,548,585,649,532,
    492,598,653,524,567,570,506,475,640,725,688,567,634,520,488,718,
    769,739,576,718,527,497,698,736,785,581,733,540,537,683,691,785,
    588,733,531,564,581,554,765,580,626,510,533,495,470,713,571,573,
    476,526,441,431,686,563,496,447,518
);

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@data);
# I should get 20 partitions, shouldn't I?
my %freqs=$stat->frequency_distribution (20);

# TEST
is (scalar(keys(%freqs)),
    20,
    "We got 20 partitions"
);

my $sum = 0;
foreach my $v (values(%freqs))
{
    $sum += $v;
}

# TEST
is ($sum,
    scalar(@data),
    "The total number of elements in the bins"
);
