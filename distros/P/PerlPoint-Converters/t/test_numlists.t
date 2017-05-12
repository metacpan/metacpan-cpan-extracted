# test of numbered lists

use strict;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_numlists.pp` + 1;
}
use Test::Simple tests => $n;

system " $^X -Iblib/lib ./pp2html -slide_prefix numlists_ -slide_dir t/d_numlists --quiet t/test_numlists.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_numlists/numlists_$nn.htm"), "numlists_$nn.htm");
  unlink "t/d_numlists/numlists_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_numlists/index.htm";

# vim:ft=perl
