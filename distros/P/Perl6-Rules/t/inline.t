use Perl6::Rules;
use Test::Simple 'no_plan';

ok("abcDEFghi" =~ m/abc (:i def) ghi/, "Match" );
ok( "abcDEFGHI" !~ m/abc (:i def) ghi/, "Mismatch");
