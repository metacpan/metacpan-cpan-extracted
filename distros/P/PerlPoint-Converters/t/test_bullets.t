
# Test of pp2html
# test of bullets

use strict;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_bullets.pp` + 1;
  }
use Test::Simple tests => $n;

system " $^X -Iblib/lib ./pp2html -slide_prefix bullets_ -slide_dir t/d_bullets --quiet -bullet ./images/dot2.jpg -bullet ./images/dot01.gif t/test_bullets.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_bullets/bullets_$nn.htm"), "bullets_$nn.htm");
  unlink "t/d_bullets/bullets_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_bullets/dot01.gif", "t/d_bullets/dot2.jpg" unless $ENV{PP_DEBUG};
unlink "t/d_bullets/index.htm";

# vim:ft=perl
