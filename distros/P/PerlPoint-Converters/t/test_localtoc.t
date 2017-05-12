
# Test localtoc

use strict;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_localtoc.pp` + 1;
  }
use Test::Simple tests => $n;

system " $^X -Iblib/lib ./pp2html -slide_prefix localtoc_ -slide_dir t/d_localtoc --quiet t/test_localtoc.pp";


for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  ok( cmp_files("t/d_localtoc/localtoc_$nn.htm"), "localtoc_$nn.htm");
  unlink "t/d_localtoc/localtoc_$nn.htm" unless $ENV{PP_DEBUG};
}
unlink "t/d_localtoc/index.htm";

# vim:ft=perl
