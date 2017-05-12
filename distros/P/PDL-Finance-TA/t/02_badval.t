use strict;
use warnings;

use PDL;
use PDL::Finance::TA;
use Test::More;

my $T  = pdl([0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30]);

my $MA1 = ta_ma($T, 3, 1);
is_deeply([$MA1->list], ['BAD', 'BAD', 3, 6, 9, 12, 15, 18, 21, 24, 27]);
my $MA2 = ta_ma($MA1, 3, 1);
is_deeply([$MA2->list], ['BAD', 'BAD', 'BAD', 'BAD', 6, 9, 12, 15, 18, 21, 24]);
my $MA3 = ta_ma($MA2, 3, 1);
is_deeply([$MA3->list], ['BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 9, 12, 15, 18, 21]);
my $MA4 = ta_ma($MA3, 3, 1);
is_deeply([$MA4->list], ['BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 12, 15, 18]);
my $MA5 = ta_ma($MA4, 3, 1);
is_deeply([$MA5->list], ['BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 15]);
my $MA6 = ta_ma($MA5, 3, 1);
is_deeply([$MA6->list], ['BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD']);
my $MA7 = ta_ma($MA6, 3, 1);
is_deeply([$MA7->list], ['BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD', 'BAD']);

done_testing;