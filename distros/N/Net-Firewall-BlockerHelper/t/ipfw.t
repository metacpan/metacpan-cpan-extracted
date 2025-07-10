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
		backend   => 'ipfw',
		ports     => [ '22',  'ssh' ],
		protocols => [ 'tcp', 'udp' ],
		prefix    => 'derp',
		name      => 'ssh',
		options   => { rule => '150', kill => 1 },
		testing   => 1,
	);

	$fw_helper->init_backend;

	if ( !defined( $fw_helper->{backend_obj} ) ) {
		die('$fw_helper->{backend_obj} is undef');
	} elsif ( ref( $fw_helper->{backend_obj} ) ne 'Net::Firewall::BlockerHelper::backends::ipfw' ) {
		die(      'ref($fw_helper->{backend_obj}) is '
				. ref( $fw_helper->{backend_obj} )
				. ' and not Net::Firewall::BlockerHelper::backends::ipfw' );
	}

	my $backend_obj = $fw_helper->{backend_obj};

	if ( !defined( $backend_obj->{options} ) ) {
		die('$backend_obj->{options} is undef');
	} elsif ( ref( $backend_obj->{options} ) ne 'HASH' ) {
		die( 'ref($backend_obj->{options}) ne "HASH", but "' . ref( $backend_obj->{options} ) . '",' );
	} elsif ( !defined( $backend_obj->{options}{rule} ) ) {
		die('$backend_obj->{options}{rule} is undef');
	}

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
	} elsif ( !defined( $fw_helper->{test_data}{fail_okay_commands} ) ) {
		die( '$fw_helper->{test_data}{fail_okay_commands} is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( !defined( $fw_helper->{test_data}{commands} ) ) {
		die( '$fw_helper->{test_data}{commands} is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( !defined( $fw_helper->{test_data}{commands}[2] ) ) {
		die( '$fw_helper->{test_data}{commands}[2] is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( !defined( $fw_helper->{test_data}{fail_okay_commands}[1] ) ) {
		die( '$fw_helper->{test_data}{fail_okay_commands}[1] is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{fail_okay_commands}[0] ne 'ipfw table derp_ssh destroy' ) {
		die( '$fw_helper->{test_data}{fail_okay_commands}[0] ne "ipfw table derp_ssh destroy"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{fail_okay_commands}[1] ne 'ipfw delete 150' ) {
		die( '$fw_helper->{test_data}{fail_okay_commands}[1] ne "ipfw delete 150"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{commands}[0] ne 'ipfw table derp_ssh create' ) {
		die( '$fw_helper->{test_data}{commands}[0] ne "ipfw table derp_ssh create"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{commands}[1] ne 'ipfw add 150 deny tcp from "table(derp_ssh)" to me 22' ) {
		die( '$fw_helper->{test_data}{commands}[1] ne "ipfw add 150 deny tcp from \"table(derp_ssh)\" to me 22"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{commands}[2] ne 'ipfw add 150 deny udp from "table(derp_ssh)" to me 22' ) {
		die( '$fw_helper->{test_data}{commands}[2] ne "ipfw add 150 deny udp from \"table(derp_ssh)\" to me 22"... '
				. Dumper( $fw_helper->{test_data} ) );
	}

	$fw_helper->ban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data}[0] ne 'ipfw table derp_ssh add 1.2.3.4' ) {
		die( '($fw_helper->{test_data}[0] ne "ipfw table derp_ssh add 1.2.3.4"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}[1] ne
		'sockstat -nc4 -P tcp |sed "s/.*tcp[46]  *//" | sed "s/:/ /g" | grep -i 1.2.3.4 | xargs -n 4 tcpdrop' )
	{
		die(
			'($fw_helper->{test_data}[1] ne \'sockstat -nc4 -P tcp |sed "s/.*tcp[46]  *//" | sed "s/:/ /g" | grep -i 1.2.3.4 | xargs -n 4 tcpdrop\'... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}[2] ne
		'sockstat -n6 -P udp | grep -i 1.2.3.4 | perl -lpe \'$_=~s/.*udp[46]  *//; $_=~s/:([0-9]+) / $1 /; $_=~s/:([0-9]+)$/ $1/; $_=~s/\\%[a-zA-Z0-9]+/ /g ; print $_\''
		)
	{
		die(
			'($fw_helper->{test_data}[2] ne \'sockstat -n6 -P udp | grep -i 1.2.3.4 | perl -lpe \'$_=~s/.*udp[46]  *//; $_=~s/:([0-9]+) / $1 /; $_=~s/:([0-9]+)$/ $1/; $_=~s/\\%[a-zA-Z0-9]+/ /g ; print $_\'\'... '
				. Dumper( $fw_helper->{test_data} ) );
	}

	$fw_helper->ban( ban => '5.6.7.8' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data}[0] ne 'ipfw table derp_ssh add 5.6.7.8' ) {
		die( '($fw_helper->{test_data}[0] ne "ipfw table derp_ssh add 5.6.7.8"... '
				. Dumper( $fw_helper->{test_data} ) );
	}

	my @banned = $fw_helper->list;
	if ( $banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8" ) {
		die('$banned[0] ne "1.2.3.4" && $banned[0] ne "5.6.7.8"');
	} elsif ( $banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8" ) {
		die('$banned[1] ne "1.2.3.4" && $banned[1] ne "5.6.7.8"');
	}

	$fw_helper->unban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'ipfw table derp_ssh delete 1.2.3.4' ) {
		die( '($fw_helper->{test_data} ne "ipfw table derp_ssh delete 1.2.3.4"... '
				. Dumper( $fw_helper->{test_data} ) );
	}

	$fw_helper->unban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data} ne 'not banned' ) {
		die( '($fw_helper->{test_data} ne "not banned"... ' . Dumper( $fw_helper->{test_data} ) );
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
	} elsif ( $fw_helper->{test_data}[0] ne 'ipfw table derp_ssh add 5.6.7.8' ) {
		die( '($fw_helper->{test_data}[0] ne "ipfw table derp_ssh add 5.6.7.8"... '
				. Dumper( $fw_helper->{test_data} ) );
	}

	$fw_helper->teardown;
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data}[0] ne 'ipfw table derp_ssh destroy' ) {
		die( '($fw_helper->{test_data}[0] ne "ipfw table derp_ssh destroy"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}[1] ne 'ipfw delete 150' ) {
		die( '($fw_helper->{test_data}[1] ne "ipfw delete 150"... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( $backend_obj->{inited} ) {
		die('($backend_obj->{inited} true when it should not be');
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
