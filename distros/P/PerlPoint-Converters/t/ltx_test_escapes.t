
# Test of pp2latex
# test of escapes

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex  \@t/ltx.cfg --quiet  t/test_escapes.pp > t/d_escapes/ltx_escapes.tex";
my $ok = ok( cmp_files("t/d_escapes/ltx_escapes.tex"), 'Test escapes');
if( !$ENV{PP_DEBUG} and $ok){
   ltx_unlink("escapes");
}
