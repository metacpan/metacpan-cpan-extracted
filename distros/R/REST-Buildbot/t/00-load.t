#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 9;

BEGIN {
    use_ok( 'REST::Buildbot' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::Builder' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::Build' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::BuildRequest' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::BuildSet' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::Change' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::Log' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::SourceStamp' ) || print "Bail out!\n";
    use_ok( 'REST::Buildbot::Step' ) || print "Bail out!\n";
}

diag( "Testing REST::Buildbot $REST::Buildbot::VERSION, Perl $], $^X" );
