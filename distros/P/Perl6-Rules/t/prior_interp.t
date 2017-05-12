use Perl6::Rules;
use Test::Simple 'no_plan';

$main::x = 'x';
ok( "x" =~ m/ $main::x /, "Successful match against interpolated package variable" );
ok( "x" =~ m/<prior>/, "Can match prior rule containing package interpolation" );
