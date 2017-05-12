use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "abc" =~ m/a(bc){$?caught = $1}/, "Inner match");
ok( $0->{caught} eq "bc", "Inner caught");

$caught = "oops!";
ok( "abc" =~ m/a(bc){$::caught = $1}/, "Outer match");
ok( $caught eq "bc", "Outer caught");

ok( "abc" =~ m/a(bc){$1 = uc $1}/, "Numeric match");
ok( $0 eq "abc", "Numeric matched" );
ok( $1 eq "BC", "Numeric caught");

ok( "abc" =~ m/a(bc){$0 = uc $1}/, "Zero match");
ok( $0 eq "BC", "Zero matched" );
ok( $1 eq "bc", "One matched" );
