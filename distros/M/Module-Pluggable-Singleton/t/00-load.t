#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Pluggable::Singleton' ) || print "Bail out!
";
}

diag( "Testing Module::Pluggable::Singleton $Module::Pluggable::Singleton::VERSION, Perl $], $^X" );
