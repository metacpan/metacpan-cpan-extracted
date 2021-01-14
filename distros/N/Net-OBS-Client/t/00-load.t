#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Net::OBS::Client' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::BuildResults' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::Project' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::Package' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::DTD' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::Roles::BuildStatus' ) || print "Bail out!\n";
    use_ok( 'Net::OBS::Client::Roles::Client' ) || print "Bail out!\n";
}

diag( "Testing Net::OBS::Client $Net::OBS::Client::VERSION, Perl $], $^X" );
