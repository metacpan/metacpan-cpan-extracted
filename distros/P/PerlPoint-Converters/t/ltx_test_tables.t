
# Test of pp2latex
# test of tables

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::Simple tests => $n;

use lib "./t";
use pptest;

system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_tables.pp > t/d_tables/ltx_tables.tex";
my $ok = ok( cmp_files("t/d_tables/ltx_tables.tex"), 'Test tables');
if(! $ENV{PP_DEBUG} and $ok){
   ltx_unlink("tables");
}
