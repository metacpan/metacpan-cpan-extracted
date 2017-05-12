#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Sys::CmdMod::Plugin::Eatmydata' ) || print "Bail out!
";
    use_ok( 'Sys::CmdMod::Plugin::Ionice' ) || print "Bail out!
";
    use_ok( 'Sys::CmdMod::Plugin::Nice' ) || print "Bail out!
";
    use_ok( 'Sys::CmdMod::Plugin' ) || print "Bail out!
";
    use_ok( 'Sys::CmdMod' ) || print "Bail out!
";
}

diag( "Testing Sys::CmdMod $Sys::CmdMod::VERSION, Perl $], $^X" );
