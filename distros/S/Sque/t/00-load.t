use Test::More tests => 1;

BEGIN {
    use_ok( 'Sque' );
}

diag( "Testing Resque $Sque::VERSION, Perl $], $^X" );
