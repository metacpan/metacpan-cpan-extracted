use Test::More 0.98;

use Data::Dumper;
my $class = 'Net::MAC::Vendor';

diag( "Some tests have to fetch data files and can take a long time" );

subtest setup => sub {
	use_ok( $class );
	ok( defined &{"${class}::fetch_oui_from_custom"}, "&fetch_oui_from_custom is defined" );
	};

subtest fetch => sub {
	SKIP: {
		my $ssl_version =  Net::SSLeay::SSLeay();
		my $ssl_version_string = Net::SSLeay::SSLeay_version();
		my $minimum_ssl = 0x10_00_00_00;

		skip "You need OpenSSL 1.x to fetch from IEEE", 2 if $ssl_version < $minimum_ssl;

		my $array = Net::MAC::Vendor::fetch_oui_from_ieee( '14:10:9F' );

		isa_ok( $array, ref [], "Got back array reference" );
		my $html = join "\n", @$array;
		like( $html, qr/Apple, Inc\./, "Fetched Apple's OUI entry" );
		}
	};

subtest fetch => sub {
	SKIP: {
		my $ssl_version =  Net::SSLeay::SSLeay();
		my $ssl_version_string = Net::SSLeay::SSLeay_version();
		my $minimum_ssl = 0x10_00_00_00;

		skip "You need OpenSSL 1.x to fetch from IEEE", 6 if $ssl_version < $minimum_ssl;

		my $i = 0;
		# undef, no env   - use hard coded default
		# defined, no env - use specified
		# undef, with env - use env
		for my $url (undef, 'http://standards.ieee.org/cgi-bin/ouisearch?14-10-9F', undef) {
			local $ENV{NET_MAC_VENDOR_OUI_SOURCE};

			if( $i > 1 ) {
				$ENV{NET_MAC_VENDOR_OUI_SOURCE} = 'http://standards.ieee.org/cgi-bin/ouisearch?14-10-9F'
				};
			my $array = Net::MAC::Vendor::fetch_oui_from_custom( '14:10:9F', $url );

			SKIP: {
				skip "Couldn't fetch data, which happens, so no big whoop", 2
					unless defined $array;
				isa_ok( $array, ref [], "Got back array reference" );
				my $html = join "\n", @$array;
				like( $html, qr/Apple, Inc\./, "Fetched Apple's OUI entry" );
				}
				$i++;
			}
		}
	};

done_testing();
