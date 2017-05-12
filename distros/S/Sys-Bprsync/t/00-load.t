#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok( 'Sys::Bprsync::Cmd::Command::configcheck' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync::Cmd::Command::run' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync::Cmd::Command' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync::Cmd' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync::Job' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync::Worker' ) || print "Bail out!
";
    use_ok( 'Sys::Bprsync' ) || print "Bail out!
";
}

diag( "Testing Sys::Bprsync $Sys::Bprsync::VERSION, Perl $], $^X" );
