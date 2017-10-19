#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Mylisp' ) || print "Bail out!\n";
    use_ok( 'Mylisp::LintAst' ) || print "Bail out!\n";
    use_ok( 'Mylisp::Grammar') || print "Bail out!\n";
    use_ok( 'Mylisp::Type') || print "Bail out!\n";
    use_ok( 'Mylisp::OptAst' ) || print "Bail out!\n";
    use_ok( 'Mylisp::ToPerl' ) || print "Bail out!\n";
    use_ok( 'Mylisp::ToGo' ) || print "Bail out!\n";
    use_ok( 'Mylisp::ToMy' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
