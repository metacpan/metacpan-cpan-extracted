use Test::More tests => 3;

BEGIN {
    use_ok( 'Net::Telnet::Gearman' );
    use_ok( 'Net::Telnet::Gearman::Function' );
    use_ok( 'Net::Telnet::Gearman::Worker' );
}

diag( "Testing Net::Telnet::Gearman $Net::Telnet::Gearman::VERSION" );