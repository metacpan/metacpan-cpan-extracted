use strict;
use warnings;

use Test::More 0.98;

my $class = 'Net::MAC::Vendor';

diag( "Some tests have to fetch data files and can take a long time" );

subtest status => sub {
	use_ok( $class );
	can_ok( $class, 'fetch_oui' );
	};

subtest cache_unlinked => sub {
	unlink( 'mac_oui.db' );
	ok( ! -e 'mac_oui.db', "Cache file has been unlinked" );
	};

my $connected = do {
	my $tx = $class->ua->head( Net::MAC::Vendor::oui_url() );
	$tx->success && $tx->res->code;
	};

diag 'Did', ( $connected ? '' : ' not' ),
	' connect to ' . Net::MAC::Vendor::oui_url();

SKIP: {
skip "Skipping network tests when not connected", 3 unless $connected;

my @ouis = qw(
	00-0D-93
	);

my $lines =
	[
	'Apple, Inc.',
	'1 Infinite Loop',
	'CUPERTINO  CA  95014',
	'US',
	];

subtest fetch_apple => sub {
	SKIP: {
		my $parsed = Net::MAC::Vendor::fetch_oui( $ouis[0] );
		skip "Can't connect to the IEEE web site for $ouis[0]", 4 unless defined $parsed;

		isa_ok( $parsed, ref [] );
		foreach my $i ( 0 .. $#$parsed ) {
			is( $parsed->[$i], $lines->[$i], "Line $i matches for $ouis[0]" );
			}
		}
	};

subtest fetch_all => sub {
	foreach my $oui ( @ouis ) {
		subtest $oui => sub {
			my $parsed = Net::MAC::Vendor::fetch_oui( $oui );
			SKIP:{
				skip "Can't connect to the IEEE web site for $oui. Sometimes that happens.", 4+1 unless defined $parsed;
				isa_ok( $parsed, ref [] );
				foreach my $i ( 0 .. $#$parsed ) {
					is( $parsed->[$i], $lines->[$i], "Line $i matches for $oui" );
					}
				}
			};
		}
	};


subtest load_from_cache => sub {
	require Cwd;
	require File::Spec;
	my $path = File::Spec->catfile( Cwd::cwd(), "extras/oui-20151113.txt" );
	diag( "File path is $path" );
	ok( -e $path, "Cached file exists" );

	SKIP: {
		skip "Can't get path to data file [$path]", 4 unless -e $path;

		diag( "...Loading cache..." );
		Net::MAC::Vendor::load_cache( $path );
		diag( "...Cache loaded..." );

		foreach my $oui ( @ouis ) {
			my $parsed = Net::MAC::Vendor::fetch_oui_from_cache( $oui );

			foreach my $i ( 1 .. $#$parsed ) {
				is( $parsed->[$i], $lines->[$i], "Line $i matches for $oui" );
				}
			}

		}

	};
} # end of big SKIP


done_testing();
