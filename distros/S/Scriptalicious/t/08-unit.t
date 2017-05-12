#!/usr/bin/perl -w
#

use Test::More no_plan;
BEGIN { use_ok( "Scriptalicious" ) };

open POD, "<blib/lib/Scriptalicious.pod" or die $!;
my @data = grep { /^ time_unit/..!/^ time_unit/ } <POD>;
close POD;

ok(@data, "sanity - found examples in the man page");

for (@data) {
   next unless /\S/;
   my ($input, $return) = m{\(([^)]+)\)\s*=>\s*"([^"]+)"} or die;
   is(time_unit(eval $input), $return, "time_unit($input)");
}
