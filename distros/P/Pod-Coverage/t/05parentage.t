#!perl -w
use strict;
use lib 't/lib';

use Test::More tests => 5;

BEGIN {
    use_ok( 'Pod::Coverage::CountParents' );
}

my $pc = Pod::Coverage::CountParents->new(package => 'Child');
isa_ok( $pc, 'Pod::Coverage::CountParents' );

is( $pc->coverage, 1, 'picked up parent docs' );

$pc = Pod::Coverage::CountParents->new(package => 'Sibling');
isa_ok( $pc, 'Pod::Coverage::CountParents' );

is( $pc->coverage, 1, 'picked up grandparent docs' );
