#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::Log::Smbd' ) || print "Bail out!
";
}

diag( "Testing Parse::Log::Smbd $Parse::Log::Smbd::VERSION, Perl $], $^X" );
