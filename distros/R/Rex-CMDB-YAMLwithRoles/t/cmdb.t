#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Rex::CMDB;
use Rex -feature => [qw/1.4/];
use Data::Dumper;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

BEGIN {
	use_ok('Rex::CMDB::YAMLwithRoles') || print "Bail out!\n";
}

my $worked = 0;
my $ncnetstat;
my $tb;
eval {
	set cmdb => {
		type           => 'YAMLwithRoles',
		path           => 't/cmdb',
		merge_behavior => 'LEFT_PRECEDENT',
		use_roles      => 1,
	};

	my $cmdb_vars = get cmdb( undef, 'test1' );

	if ( !defined( $cmdb_vars->{roles} ) ) {
		die( '.roles array not found for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( ref( $cmdb_vars->{roles} ) ne 'ARRAY' ) {
		die( '.roles not array for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( !defined( $cmdb_vars->{roles}[0] ) ) {
		die( '.roles[0] undef for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( !defined( $cmdb_vars->{foo} ) ) {
		die( '.foo is undef for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( $cmdb_vars->{foo} ne 'a test' ) {
		die( '.foo ne to "a test" for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( !defined( $cmdb_vars->{suricata_extract} ) ) {
		die( '.suricata_extract is undef for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( !defined( $cmdb_vars->{suricata_extract}{enable} ) ) {
		die( '.suricata_extract.enable is undef for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	if ( $cmdb_vars->{suricata_extract}{enable} ne '0' ) {
		die( '.suricata_extract.enable ne "0" undef for $cmdb_vars... ' . Dumper($cmdb_vars) );
	}

	$worked = 1;
};
ok( $worked eq '1', 'cmdb test' ) or diag( "cmdb test died with ... " . $@ );

done_testing(2);
