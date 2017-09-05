#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Mylisp' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Ast' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Builtin' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Grammar') || print "Bail out!\n";
    use_ok( 'Mylisp::IsAtom') || print "Bail out!\n";
    use_ok( 'Mylisp::OptAst' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
