
# Test of pp2latex
# test of bullets

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_bullets.pp > t/d_bullets/ltx_bullets.tex";
my $ok = ok( cmp_files("t/d_bullets/ltx_bullets.tex"), 'Test bullets');
if(! $ENV{PP_DEBUG} and $ok){
  ltx_unlink("bullets");
}
