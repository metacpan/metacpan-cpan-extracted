
# Time-stamp: "2004-03-27 17:13:33 AST"

use strict;
use Test;
BEGIN { plan tests => 8 };
use Sort::ArbBiLex ();
BEGIN { ok 1; }

# $Sort::ArbBiLex::Debug = 2;

use Sort::ArbBiLex;
my $source;

$source = Sort::ArbBiLex::source_maker(
 [ [' '], ['A', 'a'], ['b'], ["h", "x'"], ['i'], ['u'], ]
);
$source =~ s/^/#: /mg;
print "#: -- two-level multichar: --\n$source#:----\n";
ok 1;


$source = Sort::ArbBiLex::source_maker(
 [ [' '], ['A', 'a'], ['b'], ["h", "x"], ['i'], ['u'], ]
);
$source =~ s/^/#: /mg;
print "#: -- two-level singlechar: --\n$source#:----\n";
ok 1;



$source = Sort::ArbBiLex::source_maker( 
  [ map [$_], ' ', 'A', 'a', 'b', "h", "x", 'i', 'u', ]
);
$source =~ s/^/#: /mg;
print "#: -- one-level singlechar: --\n$source#:----\n";
ok 1;


$source = Sort::ArbBiLex::source_maker( 
  [ [ ' ', 'A', 'a', 'b', "h", "x", 'i', 'u', ] ]
);
$source =~ s/^/#: /mg;
print "#: -- one-level singlechar: --\n$source#:----\n";
ok 1;
{
  my $source2 = Sort::ArbBiLex::source_maker( 
    [ [ ' ', 'A', 'a', 'b', "h", "x", 'i', 'u', ] ]
  );
  $source2 =~ s/^/#: /mg;
  print "#: -- variant one-level singlechar: --\n$source2#:----\n";
  ok $source eq $source2;
}


$source = Sort::ArbBiLex::source_maker(
 [ map [$_], ' ', 'A', 'a', 'b', "h", "xh", 'i', 'u', ]
);
$source =~ s/^/#: /mg;
print "#: -- one-level multichar: --\n$source#:----\n";
ok 1;
{
  my $source2 = Sort::ArbBiLex::source_maker(
   [ [ ' ', 'A', 'a', 'b', "h", "xh", 'i', 'u', ] ]
  );
  $source2 =~ s/^/#: /mg;
  print "#: -- variant one-level multichar: --\n$source2#:----\n";
  ok $source eq $source2;
}


print "# Bye!\n";

