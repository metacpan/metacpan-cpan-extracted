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
		backend   => 'iptables',
		ports     => [ '22',  'ssh' ],
		protocols => [ 'tcp' ],
		prefix    => 'derp',
		name      => 'ssh',
		testing   => 1,
	);

	$fw_helper->init_backend;

	if ( !defined( $fw_helper->{backend_obj} ) ) {
		die('$fw_helper->{backend_obj} is undef');
	} elsif ( ref( $fw_helper->{backend_obj} ) ne 'Net::Firewall::BlockerHelper::backends::iptables' ) {
		die(      'ref($fw_helper->{backend_obj}) is '
				. ref( $fw_helper->{backend_obj} )
				. ' and not Net::Firewall::BlockerHelper::backends::iptables' );
	}

	my $backend_obj = $fw_helper->{backend_obj};

	if ( !defined( $backend_obj->{frontend_obj} ) ) {
		die('$backend_obj->{frontend_obj} is undef');
	} elsif ( ref( $backend_obj->{frontend_obj} ) ne 'Net::Firewall::BlockerHelper' ) {
		die(      'ref($backend_obj->{frontend_obj}) is '
				. ref( $backend_obj->{frontend_obj} )
				. ' and not Net::Firewall::BlockerHelper' );
	}

	if ( !$backend_obj->{inited} ) {
		die('$backend_obj->{inited} not true');
	} elsif ( !defined( $fw_helper->{test_data} ) ) {
		die('$fw_helper->{test_data} is undef');
	} elsif ( !defined( $fw_helper->{test_data}{fail_okay_commands} ) ) {
		die( '$fw_helper->{test_data}{fail_okay_commands} is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( !defined( $fw_helper->{test_data}{commands} ) ) {
		die( '$fw_helper->{test_data}{commands} is undef... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{fail_okay_commands}[0] ne 'iptables -D INPUT -j derp_ssh' ) {
		die( '$fw_helper->{test_data}{fail_okay_commands}[0] ne "iptables -D INPUT -j derp_ssh"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{commands}[0] ne 'ipset create derp_ssh_4 hash:ip family inet' ) {
		die( '$fw_helper->{test_data}{commands}[0] ne "ipset create derp_ssh_4 hash:ip family inet"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}{commands}[1] ne 'ipset create derp_ssh_6 hash:ip family inet6' ) {
		die( '$fw_helper->{test_data}{commands}[1] ne "ipset create derp_ssh_6 hash:ip family inet6"... '
				. Dumper( $fw_helper->{test_data} ) );
	} elsif (
		$fw_helper->{test_data}{commands}[4] ne
		'iptables -A derp_ssh -m set --match-set derp_ssh_4 src -p tcp -m multiport --dports 22 -j DROP' )
	{
		die( '$fw_helper->{test_data}{commands}[4] wrong... ' . Dumper( $fw_helper->{test_data} ) );
	}

	# ban an IPv4 address -> added to the inet set
	$fw_helper->ban( ban => '1.2.3.4' );
	if ( !defined( $fw_helper->{test_data} ) ) {
		die('Backend did not set $fw_helper->{test_data}');
	} elsif ( $fw_helper->{test_data}[0] ne 'ipset add derp_ssh_4 1.2.3.4' ) {
		die( '$fw_helper->{test_data}[0] ne "ipset add derp_ssh_4 1.2.3.4"... ' . Dumper( $fw_helper->{test_data} ) );
	}

	# ban an IPv6 address -> added to the inet6 set
	$fw_helper->ban( ban => 'dead::1' );
	if ( $fw_helper->{test_data}[0] ne 'ipset add derp_ssh_6 dead::1' ) {
		die( '$fw_helper->{test_data}[0] ne "ipset add derp_ssh_6 dead::1"... ' . Dumper( $fw_helper->{test_data} ) );
	}

	my @banned = $fw_helper->list;
	if ( $banned[0] ne '1.2.3.4' && $banned[0] ne 'dead::1' ) {
		die('$banned[0] ne "1.2.3.4" && $banned[0] ne "dead::1"');
	} elsif ( $banned[1] ne '1.2.3.4' && $banned[1] ne 'dead::1' ) {
		die('$banned[1] ne "1.2.3.4" && $banned[1] ne "dead::1"');
	}

	$fw_helper->unban( ban => '1.2.3.4' );
	if ( $fw_helper->{test_data} ne 'ipset del derp_ssh_4 1.2.3.4' ) {
		die( '$fw_helper->{test_data} ne "ipset del derp_ssh_4 1.2.3.4"... ' . Dumper( $fw_helper->{test_data} ) );
	}

	# unbanning something not banned reports 'not banned'
	$fw_helper->unban( ban => '1.2.3.4' );
	if ( $fw_helper->{test_data} ne 'not banned' ) {
		die( '$fw_helper->{test_data} ne "not banned"... ' . Dumper( $fw_helper->{test_data} ) );
	}

	@banned = $fw_helper->list;
	if ( $banned[0] ne 'dead::1' ) {
		die('$banned[0] ne "dead::1"');
	} elsif ( defined( $banned[1] ) ) {
		die('$banned[1] not undef');
	}

	# re_init re-adds the remaining ban (the v6 one) to the inet6 set
	$fw_helper->re_init;
	if ( $fw_helper->{test_data}[0] ne 'ipset add derp_ssh_6 dead::1' ) {
		die( '$fw_helper->{test_data}[0] ne "ipset add derp_ssh_6 dead::1"... ' . Dumper( $fw_helper->{test_data} ) );
	}

	$fw_helper->teardown;
	if ( $fw_helper->{test_data}[0] ne 'iptables -D INPUT -j derp_ssh' ) {
		die( '$fw_helper->{test_data}[0] ne "iptables -D INPUT -j derp_ssh"... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( $fw_helper->{test_data}[6] ne 'ipset destroy derp_ssh_4' ) {
		die( '$fw_helper->{test_data}[6] ne "ipset destroy derp_ssh_4"... ' . Dumper( $fw_helper->{test_data} ) );
	} elsif ( $backend_obj->{inited} ) {
		die('$backend_obj->{inited} true when it should not be');
	}

	my $cidr_blocked = 0;
	eval { $fw_helper->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( $fw_helper->{error} == 29 ) { $cidr_blocked = 1; }
	if ( !$cidr_blocked ) { die('ban_cidr did not set error 29 cidrNotSupported'); }

	$worked = 1;
};
ok( $worked eq '1', 'iptables test' ) or diag( "iptables test died with ... " . $@ );

done_testing(2);
