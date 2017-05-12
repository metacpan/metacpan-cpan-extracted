use Test::More tests => 1;

BEGIN {
    use_ok( 'Parallel::Simple::Dynamic' ) || print "Bail out!
";
}

diag( "Testing Parallel::Simple::Dynamic $Parallel::Simple::Dynamic::VERSION, Perl $], $^X" );
