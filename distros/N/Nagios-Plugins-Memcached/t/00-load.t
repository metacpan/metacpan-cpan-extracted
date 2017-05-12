use Test::More tests => 1;

BEGIN {
    use_ok('Nagios::Plugins::Memcached');
}

diag( "Testing Nagios::Plugins::Memcached $Nagios::Plugins::Memcached::VERSION" );
