
# Test image

use strict;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_ref.pp` + 2;
}

use Test::Simple tests => $n;

system " $^X -Iblib/lib ./pp2html -slide_prefix ref_ -slide_dir t/d_refs --quiet t/test_ref.pp";

for(my $i=1; $i < $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_refs/ref_$nn.htm"), "ref_$nn.htm");
  unlink "t/d_refs/ref_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
ok( cmp_files("t/d_refs/ref__idx.htm"), "ref__idx.htm");
unlink "t/d_refs/index.htm", "t/d_refs/ref__idx.htm" unless $ENV{PP_DEBUG};

# vim:ft=perl
