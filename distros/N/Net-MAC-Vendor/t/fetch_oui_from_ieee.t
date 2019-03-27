use Test::More 0.98;

use Data::Dumper;
my $class = 'Net::MAC::Vendor';

diag( "Some tests have to fetch data files and can take a long time" );

subtest setup => sub {
	use_ok( $class );
	ok( defined &{"${class}::fetch_oui_from_ieee"}, "&fetch_oui_from_ieee is defined" );
	};

subtest fetch => sub {
	SKIP: {
		my $ssl_version =  Net::SSLeay::SSLeay();
		my $ssl_version_string = Net::SSLeay::SSLeay_version();
		my $minimum_ssl = 0x10_00_00_00;

		skip "You need OpenSSL 1.x to fetch from IEEE", 2 if $ssl_version < $minimum_ssl;

		my $array = Net::MAC::Vendor::fetch_oui_from_ieee( '14:10:9F' );
		skip "Couldn't fetch data, which happens, so no big whoop", 2
			unless defined $array;
		isa_ok( $array, ref [], "Got back array reference" );
		my $html = join "\n", @$array;
		like( $html, qr/Apple, Inc\./, "Fetched Apple's OUI entry" );
		}
	};

done_testing();
