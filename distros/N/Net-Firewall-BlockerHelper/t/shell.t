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
		backend => 'shell',
		name    => 'derp',
		options => {
			init     => 'echo init',
			teardown => 'echo teardown',
			unban    => 'echo unban %%%BAN%%%',
			ban      => 'echo ban %%%BAN%%%',
		},
		testing => 1,
	);

	$fw_helper->init_backend;

	if ( !defined( $fw_helper->{backend_obj} ) ) {
		die('$fw_helper->{backend_obj} is undef');
	} elsif ( ref( $fw_helper->{backend_obj} ) ne 'Net::Firewall::BlockerHelper::backends::shell' ) {
		die(      'ref($fw_helper->{backend_obj}) is '
				. ref( $fw_helper->{backend_obj} )
				. ' and not Net::Firewall::BlockerHelper::backends::shell' );
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
	} elsif ( !defined( $fw_helper->{test_data} ) ) {
		die('$fw_helper->{test_data} is undef');
	} elsif ( $fw_helper->{test_data} ne 'echo init' ) {
		die('$fw_helper->{test_data} ne "echo init"... '.Dumper($fw_helper->{test_data}));
	}

	$fw_helper->ban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'echo ban 1.2.3.4' ) {
		die('($fw_helper->{test_data} ne "echo ban 1.2.3.4"... '.Dumper($fw_helper->{test_data}));
	}

	$fw_helper->ban( ban => '5.6.7.8' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'echo ban 5.6.7.8' ) {
		die('($fw_helper->{test_data} ne "echo ban 5.6.7.8"... '.Dumper($fw_helper->{test_data}));
	}

	my @banned = $fw_helper->list;
	if ( $banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8" ) {
		die('$banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8"... '.Dumper($fw_helper->{test_data}));
	} elsif ( $banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8" ) {
		die('$banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8"... '.Dumper($fw_helper->{test_data}));
	}

	$fw_helper->unban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'echo unban 1.2.3.4' ) {
		die('($fw_helper->{test_data} ne "echo unban 1.2.3.4"... '.Dumper($fw_helper->{test_data}));
	}

	@banned = $fw_helper->list;
	if ( $banned[0] ne "5.6.7.8" ) {
		die('$banned[0] ne "5.6.7.8"');
	} elsif ( defined( $banned[1] ) ) {
		die('$banned[1] not undef');
	}

	$fw_helper->re_init;
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 're-inited' ) {
		die('($fw_helper->{test_data} ne "re-inited"... '.Dumper($fw_helper->{test_data}));
	}

	$fw_helper->teardown;
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'echo teardown' ) {
		die('($fw_helper->{test_data} ne "echo teardown"... '.Dumper($fw_helper->{test_data}));
	} elsif ( $backend_obj->{inited} ) {
		die('($backend_obj->{inited} true when it should not be');
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
