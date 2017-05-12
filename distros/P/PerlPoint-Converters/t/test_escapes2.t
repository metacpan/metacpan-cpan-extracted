

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

# use different options
system " $^X -Iblib/lib ./pp2html -contents_indent 2 --block_indent 3 -boxtext_bold OFF -slide_prefix escapes_ -slide_dir t/d_escapes2 --quiet t/test_escapes.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_escapes2/escapes_$nn.htm"), "escapes_$nn.htm");
  unlink "t/d_escapes2/escapes_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_escapes2/index.htm";

# vim:ft=perl
