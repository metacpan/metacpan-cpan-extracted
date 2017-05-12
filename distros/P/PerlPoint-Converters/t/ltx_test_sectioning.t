# Test of pp2latex
# test of --section-sequence

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx-sections.cfg --quiet  t/test_sections.pp > t/d_sections/ltx_sections.tex";
my $ok = ok( cmp_files("t/d_sections/ltx_sections.tex"), 'Test sectioning');
if(! $ENV{PP_DEBUG} and $ok){
  ltx_unlink("sections");
}
