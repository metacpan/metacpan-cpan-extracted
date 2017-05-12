#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Starter::Plugin::DebPackage' ) || print "Bail out!
";
}

diag( "Testing Module::Starter::Plugin::DebPackage $Module::Starter::Plugin::DebPackage::VERSION, Perl $], $^X" );
