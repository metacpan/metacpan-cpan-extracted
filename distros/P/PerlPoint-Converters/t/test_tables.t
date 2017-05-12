
# Test of pp2html
# test of tables

use strict;
use Test;

use lib "./t";
use pptest;

my $n;
BEGIN{ 
  my $h = $^O =~ /win/i ? '"' : "'";
  $n = `$^X -e ${h}while(<>){\$i++ if /^=/}print \$i$h t/test_tables.pp` + 1;
  plan test => $n }

system " $^X -Iblib/lib ./pp2html -slide_prefix tables_ -slide_dir t/d_tables --quiet t/test_tables.pp";

for(my $i=1; $i <= $n; $i++){
  my $nn = sprintf "%04d", $i-1;
  my $ok = ok( cmp_files("t/d_tables/tables_$nn.htm"));
  unlink "t/d_tables/tables_$nn.htm" unless $ENV{PP_DEBUG} or !$ok;
}
unlink "t/d_tables/index.htm";

# vim:ft=perl
