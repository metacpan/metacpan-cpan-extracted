#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PkgConfig' ) || print "Bail out!
";
}

#diag( "Testing PkgConfig $PkgConfig::VERSION, Perl $], $^X" );
