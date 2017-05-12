use Perl6::Rules;
use Test::Simple 'no_plan';

$var = "a*b";
@var = qw(a b c);
%var = (a=>1, b=>2, c=>3);
$aref = \@var;
$href = \%var;


# SCALARS

ok( $var =~ m/$::var/, "Simple scalar interpolation");
ok( "zzzzzz${var}zzzzzz" =~ m/$::var/, "Nested scalar interpolation");
ok( "aaaaab" !~ m/$::var/, "Rulish scalar interpolation");

ok( 'a' =~ m/$::aref[0]/, "Array ref 0" );
ok( 'a' =~ m/$::aref.[0]/, "Array ref dot 0" );
ok( 'a' =~ m/@::var[0]/, "Array 0" );

ok( '1' =~ m/$::href.{a}/, "Hash ref dot A" );
ok( '1' =~ m/$::href{a}/, "Hash ref A" );
ok( '1' =~ m/%::var{a}/, "Hash A" );

ok( 'a' !~ m/$::aref[1]/, "Array ref 1" );
ok( 'a' !~ m/$::aref.[1]/, "Array ref dot 1" );
ok( 'a' !~ m/@::var[1]/, "Array 1" );
ok( '1' !~ m/$::href.{b}/, "Hash ref dot B" );
ok( '1' !~ m/$::href{b}/, "Hash ref B" );
ok( '1' !~ m/%::var{b}/, "Hash B" );


# ARRAYS

ok( "a" =~ m/@::var/, "Simple array interpolation (a)");
ok( "b" =~ m/@::var/, "Simple array interpolation (b)");
ok( "c" =~ m/@::var/, "Simple array interpolation (c)");
ok( "d" !~ m/@::var/, "Simple array interpolation (d)");
ok( "ddddaddddd" =~ m/@::var/, "Nested array interpolation (a)");

{
  no warnings 'regexp';

  ok( "abca" =~ m/^@::var+$/, "Multiple array matching");
  ok( "abcad" !~ m/^@::var+$/, "Multiple array non-matching");
}


# HASHES

ok( "a" =~ m/%::var/, "Simple hash interpolation (a)");
ok( "b" =~ m/%::var/, "Simple hash interpolation (b)");
ok( "c" =~ m/%::var/, "Simple hash interpolation (c)");
ok( "d" !~ m/%::var/, "Simple hash interpolation (d)");
ok( "====a=====" =~ m/%::var/, "Nested hash interpolation (a)");
ok( "abca" !~ m/^%::var$/, "Simple hash non-matching");

{
  no warnings 'regexp';

  ok( "a b c a" =~ m:w/^[ %::var]+$/, "Simple hash repeated matching");
}
