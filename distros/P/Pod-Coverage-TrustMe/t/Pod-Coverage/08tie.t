use strict;
use warnings;
use Test::More;
use lib 't/Pod-Coverage/lib';

use Pod::Coverage::TrustMe;

my $obj = Pod::Coverage::TrustMe->new(package => 'Tie');
is($obj->coverage, 1, "yay, skipped TIE* and friends")
  or diag explain [ [ $obj->covered ], [ $obj->uncovered ] ];

done_testing;
