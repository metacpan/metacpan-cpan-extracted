
# Test of pp2latex
# test of refs

my $n;
BEGIN{ 
  $n = 1;
}

use strict;
use Test::More tests => $n;

use lib "./t";
use pptest;
# TODO check:
# ACHTUNG: unter Windows: Endlos Loop
# ACHTUNG: mit Parser 4058 auch unter Linux: Endlos Loop

open(X, ">t/d_refs/ltx_ref.tex"); # create the file;
close X;

if ($^O =~ /win/i){
  #system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_ref.pp > t/d_refs/ltx_ref.tex";
  TODO: {
   local $TODO = "ACHTUNG: unter Windows: Endlos Loop";
    my $ok = ok( cmp_files("t/d_refs/ltx_ref.tex"), 'Test references');
    if(! $ENV{PP_DEBUG} and $ok){
       ltx_unlink("refs");
    }
  }
} else { # Linux/Unix
 #system "$^X -Iblib/lib ./pp2latex \@t/ltx.cfg --quiet  t/test_ref.pp > t/d_refs/ltx_ref.tex";
  TODO: {
   local $TODO = "ACHTUNG: unter Linux: Endlos Loop";
  my $ok = ok( cmp_files("t/d_refs/ltx_ref.tex"), 'Test references');
  if(! $ENV{PP_DEBUG} and $ok){
     ltx_unlink("refs");
  }
  }
}
