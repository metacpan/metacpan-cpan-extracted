

# Test of escapes in
# * Headlines
# * Bullets
# * Examples
# * Verbatime Examples


use strict;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_escapes.pp` + 1;
}
use Test::Simple tests => $n;

system " $^X -Iblib/lib ./pp2html -slide_prefix escapes_ -slide_dir t/d_escapes --quiet t/test_escapes.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_escapes/escapes_$nn.htm"), "escapes_$nn.htm");
  unlink "t/d_escapes/escapes_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_escapes/index.htm";

# vim:ft=perl
