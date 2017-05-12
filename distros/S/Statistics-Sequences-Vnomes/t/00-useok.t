use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Sequences::Vnomes', 0.20 ) || print "Bail out!\n";
}
diag( "Testing Statistics::Sequences::Vnomes $Statistics::Sequences::Vnomes::VERSION, Perl $], $^X" );
1;
