use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::AnyEvent::Time' ) || print "Bail out!
";
}

diag( "Testing Test::AnyEvent::Time $Test::AnyEvent::Time::VERSION, Perl $], $^X" );
