#!perl

use strict;                                                                                       
use warnings;                                                                                     
                                                                                                  
use Set::IntervalTree;                                                                            
use Test::More;
                                                                                                  
# see also RT#123410
my @data = (                                                                                      
    [6235991, 6293602, {'id' => 1}],                                                              
    [6208764, 6210365, {'id' => 2}],                                                              
    [6203827, 6208791, {'id' => 3}],                                                              
    [6208764, 6210365, {'id' => 4}],                                                              
    [6328122, 6334496, {'id' => 5}],                                                              
    [6321748, 6325478, {'id' => 6}],                                                              
    [6325542, 6332708, {'id' => 7}],                                                              
);                                                                                                
                                                                                                  
my $tree = Set::IntervalTree->new;                                                                
foreach my $a (@data) {                                                                           
    $tree->insert($a->[2], $a->[0], $a->[1]);                                                     
}                                                                                                 
#diag $tree->str;                                                                             

my $rslt = $tree->fetch_window(6208764, 6332708+1);                                              

#diag explain($rslt);
is(join(',', sort map { $_->{id} } @$rslt), "1,2,4,6,7", "fetch_window()");

done_testing;
