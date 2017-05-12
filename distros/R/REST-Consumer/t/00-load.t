use Test::More tests => 1;

BEGIN {
    use_ok( 'REST::Consumer' ) || print "Bail out!\n";
}

diag( "Testing REST::Consumer $REST::Consumer::VERSION, Perl $], $^X" );
