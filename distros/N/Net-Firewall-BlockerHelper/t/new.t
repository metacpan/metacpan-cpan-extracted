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
		ports     => [ '22',  'ssh', '153'],
		protocols => [ 'tcp', 'udp' ],
		prefix    => 'derp',
		name      => 'ssh',
		options   => { foo => 'bar' },
		testing   => 33,
	);

	if ( ref($fw_helper) ne 'Net::Firewall::BlockerHelper' ) {
		die( 'ref($fw_helper) is ' . ref($fw_helper) . ' instead of Net::Firewall::BlockerHelper' );
	}

	if ( !defined( $fw_helper->{testing} ) ) {
		die('$fw_helper->{testing} is undef');
	} elsif ( $fw_helper->{testing} ne '33' ) {
		die( '$fw_helper->{testing} ne "33"... ' . Dumper($fw_helper) );
	}

	if ( !defined( $fw_helper->{options} ) ) {
		die('$fw_helper->{options} is undef');
	} elsif ( $fw_helper->{options}{foo} ne 'bar' ) {
		die( '$fw_helper->{options}{foo} ne "bar"... ' . Dumper($fw_helper) );
	}

	if ( !defined( $fw_helper->{prefix} ) ) {
		die('$fw_helper->{prefix} is undef');
	} elsif ( $fw_helper->{prefix} ne 'derp' ) {
		die('$fw_helper->{prefix} ne "derp"');
	}

	if ( !defined( $fw_helper->{name} ) ) {
		die('$fw_helper->{name} is undef');
	} elsif ( $fw_helper->{name} ne 'ssh' ) {
		die('$fw_helper->{name} ne "ssh"');
	}

	if ( !defined( $fw_helper->{backend} ) ) {
		die('$fw_helper->{backend} is undef');
	} elsif ( $fw_helper->{backend} ne 'ipfw' ) {
		die('$fw_helper->{backend} ne "ipfw"');
	}

	if ( !defined( $fw_helper->{protocols}[0] ) ) {
		die('$fw_helper->{protocols}[0] is undef');
	} elsif ( !defined( $fw_helper->{protocols}[1] ) ) {
		die('$fw_helper->{protocols}[1] is undef');
	} elsif ( $fw_helper->{protocols}[0] ne 'tcp' ) {
		die('$fw_helper->{protocols}[0] ne tcp');
	} elsif ( $fw_helper->{protocols}[1] ne 'udp' ) {
		die('$fw_helper->{protocols}[1] ne udp');
	}

	if ( !defined( $fw_helper->{ports}[0] ) ) {
		die('$fw_helper->{ports}[0] is undef');
	} elsif ( !defined( $fw_helper->{ports}[1] ) ) {
		die('$fw_helper->{ports}[1] is undef');
	} elsif ( $fw_helper->{ports}[0] ne '22' ) {
		die('$fw_helper->{ports}[0] ne 22');
	} elsif ( $fw_helper->{ports}[1] ne '153' ) {
		die('$fw_helper->{ports}[1] ne 153');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => [ 'tcp', 'thisisinvalid_derp' ],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts invalid protocols names');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => [ 'tcp', '' ],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts blank names');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => [ '22', 'thisisinvalid' ],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts invalid ports names');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => [ '22', '' ],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts empty port names');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => undef,
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts undef backend');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => '',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts prefix as being blank');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => ' derp',
			name      => 'ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts prefix as being invalid');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => '',
		);
	};
	if ( !$@ ) {
		die('new accepts name as being blank');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => ' ssh',
		);
	};
	if ( !$@ ) {
		die('new accepts name as being invalid');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => [],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ($@) {
		die( 'new dies with empty array for ports... ' . $@ );
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => [],
			prefix    => 'derp',
			name      => 'ssh',
		);
	};
	if ($@) {
		die( 'new dies with empty array for protocols... ' . $@ );
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => undef,
			name      => 'ssh',
		);
	};
	if ($@) {
		die( 'new dies when prefix is undef... ' . $@ );
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => 'derp',
			name      => undef,
		);
	};
	if ( !$@ ) {
		die('new does not die when name is undef');
	}

	eval {
		$fw_helper = Net::Firewall::BlockerHelper->new(
			backend   => 'ipfw',
			ports     => ['22'],
			protocols => ['tcp'],
			prefix    => 'derp',
			options   => 'foo',
		);
	};
	if ( !$@ ) {
		die('new does not die options is not a HASH');
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
