use Perl6::Rules;
use Test::Simple 'no_plan';

grammar Other {
	rule abc { a (<bee>) c }

	rule bee { b }

	rule def { d <?eh> f }

	rule eh  { e }
}

rule bee { B }

ok( 'abc' =~ m/^ (<Other.abc>) $/, "<Other.abc>" );
ok( $0 eq "abc", 'abc $0');
ok( $1 eq "abc", 'abc $1');

ok( 'abc' =~ m/ (<Other.bee>) /, "<Other.bee>" );
ok( $0 eq "b", 'bee $0');
ok( $1 eq "b", 'bee $1');

ok( 'def' =~ m/^ (<Other.def>) $/, "(<Other.def>)" );
ok( $0 eq "def", 'def $0');
ok( $1 eq "def", 'def $1');

ok( 'def' =~ m/^ <?Other.def> $/, "<?Other.def>" );
ok( $0 eq "def", '?def $0');
ok( $1 ne "def", '?def $1');
ok( $0->{def} eq "def", '?def $0{def}');
ok( $0->{def}{eh} eq "e", '?def $0{def}{eh}');

ok( 'abc' !~ m/ (<bee>) /, "<bee>" );

ok( !eval { 'abc' =~ m/ (<Other.sea>) / }, "<Other.sea>" );
ok( $@ eq "Cannot match unknown named rule: <Other.sea>\n", "Error msg");
