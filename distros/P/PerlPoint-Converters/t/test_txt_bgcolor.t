
# test of bg color for text (with macros)

use strict;
use Test;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_txt_bgcolor.pp` + 1;
  plan test => $n }

system " $^X -Iblib/lib ./pp2html -set html -slide_prefix txt_bgcolor_ -slide_dir t/d_txt_bgcolor --quiet t/test_txt_bgcolor.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_txt_bgcolor/txt_bgcolor_$nn.htm"));
  unlink "t/d_txt_bgcolor/txt_bgcolor_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_txt_bgcolor/index.htm";

# vim:ft=perl
