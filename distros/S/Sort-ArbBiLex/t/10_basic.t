
# Time-stamp: "2004-03-27 17:13:36 AST"

use strict;
use Test;
BEGIN { plan tests => 20 };
use Sort::ArbBiLex ();
BEGIN { ok 1; }

# $Sort::ArbBiLex::Debug = 2;

use Sort::ArbBiLex ('foosort' => 
 [
  [' '],
  ['A', 'a'],
  ['b'],
  ["h", "x'"],
  ['i'],
  ['u'],
 ]
);

my $out = join(' ~ ',
 foosort(
  "ax'ub", 'ahuba', 'ahub iki', 'ahubiki', "x'ub", 'aba', 'Aba', 'hub',
 )
);
my $expected = "Aba ~ aba ~ ax'ub ~ ahub iki ~ ahuba ~ ahubiki ~ hub ~ x'ub";
print " Output  : $out\n Expected: $expected\n";
ok($out eq $expected); # ? "ok 2\n" : "fail 2\n";

use Sort::ArbBiLex ('n_sort' => " a A  \n  b B  \n  c C ");
sub n_cmp { Sort::ArbBiLex::xcmp(\&n_sort, @_) };
sub n_lt  { Sort::ArbBiLex::xlt( \&n_sort, @_) };
sub n_gt  { Sort::ArbBiLex::xgt( \&n_sort, @_) };
sub n_le  { Sort::ArbBiLex::xle( \&n_sort, @_) };
sub n_ge  { Sort::ArbBiLex::xge( \&n_sort, @_) };

ok   n_lt( 'a'  , 'b');
ok ! n_gt( 'a'  , 'b');
ok ! n_le( 'b'  , 'a');
ok   n_le( 'a'  , 'b');
ok   n_le( 'a'  , 'a');

ok   n_gt( 'b'  , 'a');
ok ! n_lt( 'b'  , 'a');
ok ! n_ge( 'a'  , 'b');
ok   n_ge( 'b'  , 'a');
ok   n_ge( 'a'  , 'a');

ok -1 == n_cmp( 'a'  , 'b');
ok  1 == n_cmp( 'b'  , 'a');
ok  0 == n_cmp( 'a'  , 'a');


ok  0 == n_cmp( 'a'  , 'ax');
ok      ! n_lt( 'a'  , 'ax');
ok      ! n_gt( 'a'  , 'ax');
ok        n_le( 'a'  , 'ax');
ok        n_ge( 'a'  , 'ax');


