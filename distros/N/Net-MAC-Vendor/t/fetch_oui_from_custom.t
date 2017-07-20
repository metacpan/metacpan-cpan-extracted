use Test::More 0.98;

use Data::Dumper;
my $class = 'Net::MAC::Vendor';

diag( "Some tests have to fetch data files and can take a long time" );

subtest setup => sub {
	use_ok( $class );
	ok( defined &{"${class}::fetch_oui_from_custom"}, "&fetch_oui_from_custom is defined" );
	};

subtest fetch => sub {
	my $i = 0;
	for my $url (undef, 'http://standards.ieee.org/cgi-bin/ouisearch?14-10-9F', undef) {
		if ($i > 1) { $ENV{NET_MAC_VENDOR_OUI_SOURCE} = 
			'http://standards.ieee.org/cgi-bin/ouisearch?14-10-9F' };
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
	};

done_testing();
