use Test::More tests => 1;

BEGIN {
	use_ok( 'Mojo::InfluxDB' );
}

diag( "Testing Mojo::InfluxDB $Mojo::InfluxDB::VERSION, Perl $], $^X" );
