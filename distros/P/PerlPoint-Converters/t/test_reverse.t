
# Creation of Changelog

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h Changes` + 1;
}

use strict;
use Test::Simple tests => $n;
use File::Copy;

use lib "./t";
use pptest;

system " $^X -Iblib/lib ./pp2html -reverse_order -slide_prefix changes -slide_dir t/d_changes --quiet Changes";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_changes/changes$nn.htm"), "Create changes$nn.htm");
  copy("t/d_changes/changes$nn.htm", "doc/changes$nn.htm");
  if (! $ENV{PP_DEBUG} and $ok) {
    unlink "t/d_changes/changes$nn.htm";
  }
}
rename "t/d_changes/index.htm", "doc/Changes.htm";

# vim:ft=perl
