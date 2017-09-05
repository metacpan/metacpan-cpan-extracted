#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Spp' ) || print "Bail out!\n";
    use_ok( 'Spp::Builtin' ) || print "Bail out!\n";
    use_ok( 'Spp::Ast') || print "Bail out!\n";
    use_ok( 'Spp::Cursor' ) || print "Bail out!\n";
    use_ok( 'Spp::Grammar' ) || print "Bail out!\n";
    use_ok( 'Spp::IsAtom') || print "Bail out!\n";
    use_ok( 'Spp::IsChar' ) || print "Bail out!\n";
    use_ok( 'Spp::LintParser' ) || print "Bail out!\n";
    use_ok( 'Spp::Match' ) || print "Bail out!\n";
    use_ok( 'Spp::OptSppAst' ) || print "Bail out!\n";
    use_ok( 'Spp::ToSpp' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
