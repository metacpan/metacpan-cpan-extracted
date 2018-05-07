#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Mylisp' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Builtin' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Estr') || print "Bail out!\n";
    use_ok( 'Mylisp::LintMyAst' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Match') || print "Bail out!\n";
    use_ok( 'Mylisp::MyGrammar') || print "Bail out!\n";
    use_ok( 'Mylisp::OptMyAst' ) || print "Bail out!\n";
    use_ok( 'Mylisp::OptSppAst')|| print "Bail out!\n";
    use_ok( 'Mylisp::SppAst')     || print "Bail out!\n";
    use_ok( 'Mylisp::SppGrammar') || print "Bail out!\n";
    use_ok( 'Mylisp::ToPerl' ) || print "Bail out!\n";
}

diag( "Testing Spp $Mylisp::VERSION, Perl $], $^X" );
