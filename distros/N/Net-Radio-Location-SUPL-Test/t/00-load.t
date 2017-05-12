#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Net::Radio::Location::SUPL::XS' ) || print "Bail out on Net::Radio::Location::SUPL::XS!\n";
    use_ok( 'Net::Radio::Location::SUPL::Test' ) || print "Bail out on Net::Radio::Location::SUPL::Test!\n";
    use_ok( 'Net::Radio::Location::SUPL::DBusObject' ) || print "Bail out on Net::Radio::Location::SUPL::DBusObject!\n";
    use_ok( 'Net::Radio::Location::SUPL::DBusObject::RecvPushMsg' ) || print "Bail out on Net::Radio::Location::SUPL::DBusObject::RecvPushMsg!\n";
    use_ok( 'Net::Radio::Location::SUPL::DBusObject::Translator' ) || print "Bail out on Net::Radio::Location::SUPL::DBusObject::Translator!\n";
    use_ok( 'Net::Radio::Location::SUPL::MainLoop' ) || print "Bail out on Net::Radio::Location::SUPL::MainLoop!\n";
}

diag( "Testing Net::Radio::Location::SUPL::Test $Net::Radio::Location::SUPL::Test::VERSION, Perl $], $^X" );
