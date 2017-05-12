

# Test of colored REFs

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_color_refs.pp` + 1;
  }

use strict;
use Test::More tests => $n;

use lib "./t";
use pptest;


system " $^X -Iblib/lib ./pp2html -slide_prefix color_refs -slide_dir t/d_color_refs --quiet t/test_color_refs.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  TODO:{
    local $TODO = 'does not yet work';
  ok( cmp_files("t/d_color_refs/color_refs$nn.htm"));
  }
  unlink "t/d_color_refs/color_refs$nn.htm" unless $ENV{PP_DEBUG};
}
unlink "t/d_color_refs/index.htm";

# vim:ft=perl
