#!perl -T

use Test::More tests => 14;

BEGIN {
    use_ok( 'Monitoring::Reporter::Backend::NagiosLivestatus' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Backend::ZabbixDBI' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Cmd::Command::actions' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Cmd::Command::list' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Cmd::Command' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web::Plugin::Demo' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web::Plugin::History' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web::Plugin::List' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web::Plugin::Selftest' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web::Plugin' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Backend' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Cmd' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter::Web' ) || print "Bail out!
";
    use_ok( 'Monitoring::Reporter' ) || print "Bail out!
";
}

diag( "Testing Monitoring::Reporter $Monitoring::Reporter::VERSION, Perl $], $^X" );

