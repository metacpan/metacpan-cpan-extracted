#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Mylisp' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Ast' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Grammar') || print "Bail out!\n";
    use_ok( 'Mylisp::Core') || print "Bail out!\n";
    use_ok( 'Mylisp::OptAstAtom' ) || print "Bail out!\n";
    use_ok( 'Mylisp::OptAstMacro' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Stable') || print "Bail out!\n";
    use_ok( 'Mylisp::ToPerl' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
