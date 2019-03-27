use Test::More 0.98;

my $class = 'Net::MAC::Vendor';

subtest setup => sub{
	use_ok( $class );
	ok( defined &{"${class}::run"}, "run() method is defined" );
	can_ok( $class, qw(run) );
	};

subtest run => sub {
	SKIP: {
		my $ssl_version =  Net::SSLeay::SSLeay();
		my $ssl_version_string = Net::SSLeay::SSLeay_version();
		my $minimum_ssl = 0x10_00_00_00;

		skip "You need OpenSSL 1.x to fetch from IEEE", 2, if $ssl_version < $minimum_ssl;

		local *STDOUT;
		open STDOUT, ">", \ my $output;

		my $rc = $class->run( '00:0d:93:84:49:ee' );
		SKIP: {
		skip 'Problem looking up data', 1 unless defined $rc;
			ok $rc, 'run returns a true value';
			like( $output, qr/Apple/, 'OUI belongs to Apple');
			}
		}
	};

done_testing();
