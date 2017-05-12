
use strict;
use warnings;
use Test::More tests => 4;

use Set::Infinite qw($inf);

my $neg_inf = -$inf;

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

my $a = 1998; 
my $b = 2002; 
my $c = 2004; 
my $d = 2005; 
my $e = 1994; 

my $span1 = Set::Infinite->new(
    {
        a => $a, open_begin => 0,
        b => $b, open_end => 1,
    } 
);
my $span2 = Set::Infinite->new(
    {
        a => $c, open_begin => 0,
        b => $d, open_end => 1,
    } 
);
my $span3 = Set::Infinite->new(
    {
        a => $e, open_begin => 0,
        b => $c, open_end => 1,
    } 
);

my $set1 = $span1->union( $span2 );
is( "$set1", "[1998..2002),[2004..2005)", "set 1");
my $set2 = $span3;
is( "$set2", "[1994..2004)", "set 2");
my $set3 = $set1->union($set2);
is( "$set3", "[1994..2005)", "set 3");
my $set4 = $set2->union($set1);
is( "$set4", "[1994..2005)", "set 4");

