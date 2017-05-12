#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Ruby::VersionManager' ) || print "Bail out!\n";
    use_ok( 'Ruby::VersionManager::Gem' ) || print "Bail out!\n";
}

