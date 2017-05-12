use Test::More tests => 1;
BEGIN {
    use_ok( 'Statistics::Autocorrelation' ) || print "Bail out!";
}
diag( "Testing Statistics::Autocorrelation $Statistics::Autocorrelation::VERSION, Perl $], $^X" );
1;