use Test::More tests => 1;

BEGIN {
    diag( "Beginning Statistics::Lite tests in $^O with Perl $], $^X" );
    use_ok( 'Statistics::Lite' ) || print "ERROR: Could not load module\n";
}

diag( "Testing Statistics::Lite $Statistics::Lite::VERSION" );
