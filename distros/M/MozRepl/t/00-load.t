use Test::More tests => 3;

BEGIN {
    use_ok('MozRepl');
    use_ok('MozRepl::Log');
    use_ok('MozRepl::Client');
}

diag( "Testing MozRepl $MozRepl::VERSION" );
