#!perl -T

use Test::More tests => 12;

BEGIN {
    use_ok( 'Sys::RevoBackup::Cmd::Command::backupcheck' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Cmd::Command::cleanup' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Cmd::Command::configcheck' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Cmd::Command::run' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Cmd::Command' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Plugin::Zabbix' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Cmd' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Job' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Plugin' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Utils' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup::Worker' ) || print "Bail out!
";
    use_ok( 'Sys::RevoBackup' ) || print "Bail out!
";
}

diag( "Testing Sys::RevoBackup $Sys::RevoBackup::VERSION, Perl $], $^X" );
