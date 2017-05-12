#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'POE::Component::IRC::Plugin::WubWubWub' ) || print "Bail out!
";
}

diag( "Testing POE::Component::IRC::Plugin::WubWubWub $POE::Component::IRC::Plugin::WubWubWub::VERSION, Perl $], $^X" );
