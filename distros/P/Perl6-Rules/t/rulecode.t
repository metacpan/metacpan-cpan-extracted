use Perl6::Rules;
use Test::Simple 'no_plan';

rule abc { a b c }

$var = "";
ok( "aaabccc" =~ m/aa <{ $var ? $var : rx{abc} }> cc/, "Rule block second" );

$var = rx/<abc>/;
ok( "aaabccc" =~ m/aa <{ $var ? $var : rx{<null>} }> cc/, "Rule block first" );

$var = rx/xyz/;
ok( "aaabccc" !~ m/aa <{ $var ? $var : rx{abc} }> cc/, "Rule block fail" );

$var = rx/<abc>/;
ok( "aaabccc" =~ m/aa <{ $var ? $var : rx{abc} }> cc/, "Rule block interp" );
