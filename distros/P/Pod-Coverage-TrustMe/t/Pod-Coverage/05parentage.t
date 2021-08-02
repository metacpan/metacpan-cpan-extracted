use strict;
use warnings;
use lib 't/Pod-Coverage/lib';

use Test::More;

use Pod::Coverage::TrustMe;

my $pc = Pod::Coverage::TrustMe->new(package => 'Child');

is( $pc->coverage, 1, 'picked up parent docs' );

$pc = Pod::Coverage::TrustMe->new(package => 'Sibling');

is( $pc->coverage, 1, 'picked up grandparent docs' );

done_testing;
