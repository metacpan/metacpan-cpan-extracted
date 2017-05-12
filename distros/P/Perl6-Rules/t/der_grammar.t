use Perl6::Rules;
use Test::Simple 'no_plan';

grammar Other {
	rule abc { a (<bee>) c }

	rule bee { b }

	rule def { d <?eh> f }

	rule eh  { e }
}

grammar Another is Other {
}

grammar Yet::Another is Another {

	rule bee { B }

	rule def { D <?eh> F }
}

# Test derivation and Liskov substitutability...

ok( 'abc' =~ m/^ (<Another.abc>) $/, "<Another.abc>" );
ok( $0 eq "abc", 'abc $0');
ok( $1 eq "abc", 'abc $1');

ok( 'abc' =~ m/ (<Another.bee>) /, "<Another.bee>" );
ok( $0 eq "b", 'bee $0');
ok( $1 eq "b", 'bee $1');

ok( 'b' =~ m/ (<Another.bee>) /, "<Another.bee>" );

ok( 'def' =~ m/^ (<Another.def>) $/, "(<Another.def>)" );
ok( $0 eq "def", 'def $0');
ok( $1 eq "def", 'def $1');

ok( 'def' =~ m/^ <?Another.def> $/, "<?Another.def>" );
ok( $0 eq "def", '?def $0');
ok( $1 ne "def", '?def $1');
ok( $0->{def} eq "def", '?def $0{def}');
ok( $0->{def}{eh} eq "e", '?def $0{def}{eh}');


ok( !eval { 'abc' =~ m/ (<Another.sea>) / }, "<Another.sea>" );
ok( $@ eq "Cannot match unknown named rule: <Another.sea>\n", "Error msg");

# Test rederivation and polymorphism...

ok( 'abc' =~ m/^ (<Yet::Another.abc>) $/, "<Yet::Another.abc>" );
ok( $0 eq "abc", 'abc $0');
ok( $1 eq "abc", 'abc $1');

ok( 'abc' !~ m/ (<Yet::Another.bee>) /, "abc <Yet::Another.bee>" );
ok( 'aBc' =~ m/ (<Yet::Another.bee>) /, "aBc <Yet::Another.bee>" );
ok( $0 eq "B", 'Yet::Another::bee $0');
ok( $1 eq "B", 'Yet::Another::bee $1');

ok( 'def' !~ m/^ (<Yet::Another.def>) $/, "def (<Yet::Another.def>)" );
ok( 'DeF' =~ m/^ (<Yet::Another.def>) $/, "DeF (<Yet::Another.def>)" );
ok( $0 eq "DeF", 'DeF $0');
ok( $1 eq "DeF", 'DeF $1');

ok( 'DeF' =~ m/^ <?Yet::Another.def> $/, "<?Yet::Another.def>" );
ok( $0 eq "DeF", '?Yet::Another.def $0');
ok( $1 ne "DeF", '?Yet::Another.def $1');
ok( $0->{def} eq "DeF", '?def $0{def}');
ok( $0->{def}{eh} eq "e", '?def $0{def}{eh}');


# Non-existent rules...

ok( !eval { 'abc' =~ m/ (<Another.sea>) / }, "<Another.sea>" );
ok( $@ eq "Cannot match unknown named rule: <Another.sea>\n", "Error msg");
