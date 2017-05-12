use Test::More tests => 1;
{
    package TestUse;
    BEGIN {
        ::use_ok( 'MooseX::LogDispatch' );
    }
}

diag( "Testing MooseX::LogDispatch $MooseX::LogDispatch::VERSION" );
