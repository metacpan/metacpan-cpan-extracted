use strict;
use warnings;
use Test::More;
use lib 't/Pod-Coverage/lib';

use Pod::Coverage::TrustMe;

my $obj = Pod::Coverage::TrustMe->new(package => 'Empty', nonwhitespace => 1);
is($obj->coverage, 0.5, "Noticed empty pod section");

done_testing;
