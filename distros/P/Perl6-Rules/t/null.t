use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "" =~ m/<null>/, "Simple null" );
ok( "a" =~ m/<null>/, "Simple null A" );

ok( "ab" =~ m{a<null>b}, "Compound null AB" );
