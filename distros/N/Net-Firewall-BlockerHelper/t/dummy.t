#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

my $worked = 0;
eval {
	my $fw_helper = Net::Firewall::BlockerHelper->new(
		backend   => 'dummy',
		ports     => [ '22',  'ssh' ],
		protocols => [ 'tcp', 'udp' ],
		prefix    => 'derp',
		name      => 'ssh',
		options   => { foo => 'bar' },
		testing   => 1,
	);

	$fw_helper->init_backend;

	if ( !defined( $fw_helper->{backend_obj} ) ) {
		die('$fw_helper->{backend_obj} is undef');
	} elsif ( ref( $fw_helper->{backend_obj} ) ne 'Net::Firewall::BlockerHelper::backends::dummy' ) {
		die(      'ref($fw_helper->{backend_obj}) is '
				. ref( $fw_helper->{backend_obj} )
				. ' and not Net::Firewall::BlockerHelper::backends::dummy' );
	}

	my $backend_obj = $fw_helper->{backend_obj};

	if ( !defined( $backend_obj->{frontend_obj} ) ) {
		die('$backend_obj->{frontend_obj} is undef');
	} elsif ( ref( $backend_obj->{frontend_obj} ) ne 'Net::Firewall::BlockerHelper' ) {
		die(      'ref($backend_obj->{frontend_obj}) is '
				. ref( $backend_obj->{frontend_obj} )
				. ' and not Net::Firewall::BlockerHelper' );
	}

	if ( !defined( $backend_obj->{testing} ) ) {
		die('$backend_obj->{testing} is undef');
	} elsif ( $backend_obj->{testing} ne '1' ) {
		die('$backend_obj->{testing} ne "1"');
	}

	if ( !$backend_obj->{inited} ) {
		die('$backend_obj->{inited} not true');
	}elsif (!defined($fw_helper->{test_data})) {
		die('$fw_helper->{test_data} is undef');
	}elsif ($fw_helper->{test_data} ne 'inited') {
		die('$fw_helper->{test_data} ne "inited"');
	}

	$fw_helper->ban(ban=>'1.2.3.4');
	if (!defined($fw_helper->{test_data})) {
		die('Backend did not set $fw_helper->{test_data}');
	}elsif ($fw_helper->{test_data} ne 'banned 1.2.3.4') {
		die('($fw_helper->{test_data} ne "banned 1.2.3.4"');
	}

	$fw_helper->ban(ban=>'5.6.7.8');
	if (!defined($fw_helper->{test_data})) {
		die('Backend did not set $fw_helper->{test_data}');
	}elsif ($fw_helper->{test_data} ne 'banned 5.6.7.8') {
		die('($fw_helper->{test_data} ne "banned 1.2.3.4"');
	}

	my @banned=$fw_helper->list;
	if ($banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8") {
		die('$banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8"');
	}elsif ($banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8") {
		die('$banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8"');
	}

	$fw_helper->unban(ban=>'1.2.3.4');
	if (!defined($fw_helper->{test_data})) {
		die('Backend did not set $fw_helper->{test_data}');
	}elsif ($fw_helper->{test_data} ne 'unbanned 1.2.3.4') {
		die('($fw_helper->{test_data} ne "unbanned 1.2.3.4"');
	}

	@banned=$fw_helper->list;
	if ($banned[0] ne "5.6.7.8") {
		die('$banned[0] ne "5.6.7.8"');
	}elsif (defined($banned[1])) {
		die('$banned[1] not undef');
	}

	$fw_helper->re_init;
	if (!defined($fw_helper->{test_data})) {
		die('Backend did not set $fw_helper->{test_data}');
	}elsif ($fw_helper->{test_data} ne 're_inited') {
		die('($fw_helper->{test_data} ne "re_inited"');
	}

	$fw_helper->teardown;
	if (!defined($fw_helper->{test_data})) {
		die('Backend did not set $fw_helper->{test_data}');
	}elsif ($fw_helper->{test_data} ne 'toredown') {
		die('($fw_helper->{test_data} ne "toredown"');
	}elsif ($backend_obj->{inited}) {
		die('($backend_obj->{inited} true when it should not be');
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
