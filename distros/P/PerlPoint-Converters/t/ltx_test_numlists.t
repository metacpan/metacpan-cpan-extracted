
# Test of pp2latex
# test of numbered lists

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_numlists.pp > t/d_numlists/ltx_numlists.tex";
my $ok = ok( cmp_files("t/d_numlists/ltx_numlists.tex"), 'Test numlists');
if(! $ENV{PP_DEBUG} and $ok){
  ltx_unlink("numlists");
}
