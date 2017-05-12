
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all);

plan tests => 16;

my $v = vector(1,2,3);
my $m = mean($v);
my $s = stddev($v);

ok($m,   mean(1,2,3));
ok($s, stddev(1,2,3));

$v->insert(4);
ok($m,   mean(2,3,4));
ok($s, stddev(2,3,4));

$m->insert(5);
ok($m,   mean(3,4,5));
ok($s, stddev(3,4,5));

$s->insert(6);
ok($m,   mean(4,5,6));
ok($s, stddev(4,5,6));

$v = vector(1,2,3);
$m = mean($v);
$s = stddev($v);

ok($m,   mean(1,2,3));
ok($s, stddev(1,2,3));                                                        
                                                                              
$v->ginsert(4);                                                               
ok($m,   mean(1,2,3,4));
ok($s, stddev(1,2,3,4));                                                      
                                                                              
$m->ginsert(5);                                                               
ok($m,   mean(1,2,3,4,5));
ok($s, stddev(1,2,3,4,5));                                                    
                                                                              
$s->ginsert(6);                                                               
ok($m,   mean(1,2,3,4,5,6));
ok($s, stddev(1,2,3,4,5,6));
