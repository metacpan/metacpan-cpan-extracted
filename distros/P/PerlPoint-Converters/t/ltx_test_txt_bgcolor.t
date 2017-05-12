
# Test of pp2latex
# test of bg color for text (should have no effect)

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::More tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg -set latex -active --quiet  t/test_txt_bgcolor.pp > t/d_txt_bgcolor/ltx_txt_bgcolor.tex";
#TODO: {
#local $TODO = 'still buggy';
my $ok = ok( cmp_files("t/d_txt_bgcolor/ltx_txt_bgcolor.tex"), 'Test txt_bgcolor');

if(! $ENV{PP_DEBUG} and $ok){
   ltx_unlink("txt_bgcolor");
}
#}
