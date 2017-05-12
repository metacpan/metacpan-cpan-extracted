
# Test of pp2latex
# test of tags

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_tags.pp > t/d_tags/ltx_tags.tex";
my $ok = ok( cmp_files("t/d_tags/ltx_tags.tex"), 'Test tags');
if(! $ENV{PP_DEBUG} and $ok){
   ltx_unlink("tags");
}
