
# Time-stamp: "2004-03-27 17:13:17 AST"

use strict;
use Test;
BEGIN { plan tests => 8 };
use Sort::ArbBiLex ();

BEGIN {
if( &Sort::ArbBiLex::UNICODE ) {
  ok 1;
} else {
  print "# You're not running a Unicode-aware version of Perl.\n";
  ok 0;
  die "Aborting " . __FILE__ . "\n";
}
}

# $Sort::ArbBiLex::Debug = 2;

my $euro;
BEGIN { $euro = "\x{20ac}"; }
binmode(STDOUT, ":utf8");


# $Sort::ArbBiLex::Debug = 2;

use Sort::ArbBiLex;
my $source;

$source = Sort::ArbBiLex::source_maker(
 [ [' '], ['A', 'a'], ['b'], ["h", "${euro}"], ['i'], ['u'], ]
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
 [ map [$_], ' ', 'A', 'a', 'b', "h", "${euro}", 'i', 'u', ]
);
$source =~ s/^/#: /mg;
print "#: -- one-level multichar: --\n$source#:----\n";
ok 1;
{
  my $source2 = Sort::ArbBiLex::source_maker(
   [ [ ' ', 'A', 'a', 'b', "h", "${euro}", 'i', 'u', ] ]
  );
  $source2 =~ s/^/#: /mg;
  print "#: -- variant one-level multichar: --\n$source2#:----\n";
  ok $source eq $source2;
}


print "# Bye!\n";

