use Perl6::Rules;
use Test::Simple 'no_plan';

$str = "abrAcadAbbra";

ok( $str =~ m/ a .+ A /, "Match from start" );
ok( $0->pos == 0, "Match pos is 0" );

ok( $str =~ m/ A .+ a /, "Match from 3" );
ok( $0->pos == 3, "Match pos is 3" );

ok( $str !~ m/ Z .+ a /, "No match" );
ok( !defined $0->pos, "Match pos is undef" );

rule Aa { A .* a }
ok( $str =~ m/ .*? <?Aa> /, "Subrule match from 3" );
ok( $0->pos == 0, "Full match pos is 0" );
ok( $0->{Aa}->pos == 3, "Subrule match pos is 3" );

