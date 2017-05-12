use Test::More 0.98;

my $class = 'Net::MAC::Vendor';

diag( "Some tests have to fetch data files and can take a long time" );

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, qw(oui_url oui_urls) );
	};

subtest oui_urls => sub {
	my @urls = $class->oui_urls;
	diag( "URLs are @urls" );
	ok( scalar @urls, 'oui_urls returns some URLs' );
	};

subtest oui_url => sub {
	my $url = $class->oui_url;
	diag( "URL is $url" );
	ok( $url, 'oui_url returns a URL' );
	};

subtest fetch_url => sub {
	my $tx = $class->ua->head( $class->oui_url );
	ok( $tx->success, "Fetching URL was a success" );
	};

done_testing();
