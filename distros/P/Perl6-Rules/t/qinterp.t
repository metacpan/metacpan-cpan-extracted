use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "ab cd" =~ m/a <'b c'> d/, "ab cd 1" );
ok( "abcd" !~ m/a <'b c'> d/, "not abcd 1" );
ok( "ab cd" =~ m/ab <' '> c d/, "ab cd 2" );
ok( "ab/cd" =~ m/ab <'/'> c d/, "ab/cd" );

ok( "wx yz" =~ m/w \Q[x y] z/, "wx yz 1" );
ok( "wxyz" !~ m/w \Q[x y] z/, "not wxyz 1" );
ok( "wx yz" =~ m/wx \Q[ ] y z/, "wx yz 2" );
ok( "wx/yz" =~ m/wx \Q[/] y z/, "wx/yz" );
