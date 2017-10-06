#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok( 'Spp' ) || print "Bail out!\n";
    use_ok( 'Spp::Builtin' ) || print "Bail out!\n";
    use_ok( 'Spp::Core' ) || "Bail out!\n";
    use_ok( 'Spp::Ast') || print "Bail out!\n";
    use_ok( 'Spp::Cursor' ) || print "Bail out!\n";
    use_ok( 'Spp::Estr' )   || print "Bail out!\n";
    use_ok( 'Spp::Grammar' ) || print "Bail out!\n";
    use_ok( 'Spp::MatchRule' ) || print "Bail out!\n";
    use_ok( 'Spp::OptAst' ) || print "Bail out!\n";
    use_ok( 'Spp::ToSpp' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
