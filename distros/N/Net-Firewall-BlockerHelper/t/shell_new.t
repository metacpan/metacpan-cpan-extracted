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

	# options not passed at all
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts missing options');
	}

	# options is not a HASH ref
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => 'not_a_hash',
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts options as a non-HASH scalar');
	}

	# options{init} undef
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				teardown => 'echo teardown',
				ban      => 'echo ban %%%BAN%%%',
				unban    => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts undef options{init}');
	}

	# options{init} blank
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => '',
				teardown => 'echo teardown',
				ban      => 'echo ban %%%BAN%%%',
				unban    => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts blank options{init}');
	}

	# options{teardown} undef
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init  => 'echo init',
				ban   => 'echo ban %%%BAN%%%',
				unban => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts undef options{teardown}');
	}

	# options{teardown} blank
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => 'echo init',
				teardown => '',
				ban      => 'echo ban %%%BAN%%%',
				unban    => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts blank options{teardown}');
	}

	# options{ban} undef
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => 'echo init',
				teardown => 'echo teardown',
				unban    => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts undef options{ban}');
	}

	# options{ban} blank
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => 'echo init',
				teardown => 'echo teardown',
				ban      => '',
				unban    => 'echo unban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts blank options{ban}');
	}

	# options{unban} undef
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => 'echo init',
				teardown => 'echo teardown',
				ban      => 'echo ban %%%BAN%%%',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts undef options{unban}');
	}

	# options{unban} blank
	eval {
		my $fw_helper = Net::Firewall::BlockerHelper->new(
			backend => 'shell',
			name    => 'derp',
			options => {
				init     => 'echo init',
				teardown => 'echo teardown',
				ban      => 'echo ban %%%BAN%%%',
				unban    => '',
			},
			testing => 1,
		);
		$fw_helper->init_backend;
	};
	if ( !$@ ) {
		die('shell backend new() accepts blank options{unban}');
	}

	$worked = 1;
};
ok( $worked eq '1', 'shell_new test' ) or diag( "shell_new test died with ... " . $@ );

done_testing(2);
