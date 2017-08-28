#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Spp' ) || print "Bail out!\n";
    use_ok( 'Spp::Tools' ) || print "Bail out!\n";
    use_ok( 'Spp::ToSpp' ) || print "Bail out!\n";
    use_ok( 'Spp::Cursor')     || print "Bail out!\n";
    use_ok( 'Spp::IsAtom')     || print "Bail out!\n";
    use_ok( 'Spp::IsChar')     || print "Bail out!\n";
    use_ok( 'Spp::LintAst' ) || print "Bail out!\n";
    use_ok( 'Spp::OptSppAst' ) || print "Bail out!\n";
    use_ok( 'Spp::Ast::SppAst')   || print "Bail out!\n";
    use_ok( 'Spp::Rule::SppRule') || print "Bail out!\n";
    use_ok( 'Spp::MatchGrammar' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
