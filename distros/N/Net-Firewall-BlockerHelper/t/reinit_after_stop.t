#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# re_init must not require the backend to be inited. stop and teardown both
# clear the inited flag while keeping the ban list, and the frontend exposes
# no init of its own, so a re_init that refused when not inited left the
# object with no way back: the bans were still tracked but could never be
# re-applied. Regression test for that.

# every backend that keeps its ban list in memory and can be driven in
# testing mode without any required options. shell is left out as it requires
# its command options to be set at new. npf and shorewall block whole IPs and
# reject ports, so they are exercised without them.
my @backends = (
	{ backend => 'dummy',     ports => ['22'], protocols => ['tcp'] },
	{ backend => 'ipfw',      ports => ['22'], protocols => ['tcp'] },
	{ backend => 'pf',        ports => ['22'], protocols => ['tcp'] },
	{ backend => 'iptables',  ports => ['22'], protocols => ['tcp'] },
	{ backend => 'nftables',  ports => ['22'], protocols => ['tcp'] },
	{ backend => 'firewalld', ports => ['22'], protocols => ['tcp'] },
	{ backend => 'ufw',       ports => ['22'], protocols => ['tcp'] },
	{ backend => 'npf' },
	{ backend => 'shorewall' },
);

foreach my $spec (@backends) {
	my $backend = $spec->{backend};
	foreach my $stopper (qw( stop teardown )) {
		my $fw = Net::Firewall::BlockerHelper->new(
			%{$spec},
			name    => 'ssh',
			testing => 1,
		);
		$fw->init_backend;
		$fw->ban( ban => '10.0.0.1' );
		$fw->ban( ban => '2001:db8::1' );

		ok( $fw->{backend_obj}{inited}, "$backend: inited after init_backend" );

		$fw->$stopper;
		ok( !$fw->{backend_obj}{inited}, "$backend: $stopper clears inited" );

		# the bans have to survive, otherwise there is nothing to restore
		is_deeply(
			[ sort( $fw->list ) ],
			[ '10.0.0.1', '2001:db8::1' ],
			"$backend: ban list survives $stopper"
		);

		my $lived = eval { $fw->re_init; 1 };
		ok( $lived, "$backend: re_init works after $stopper" )
			or diag("re_init died: $@");

		ok( $fw->{backend_obj}{inited}, "$backend: inited again after re_init" );

		is_deeply(
			[ sort( $fw->list ) ],
			[ '10.0.0.1', '2001:db8::1' ],
			"$backend: bans still present after re_init"
		);
	} ## end foreach my $stopper (qw( stop teardown ))
} ## end foreach my $backend (@backends)

# CIDR ranges have to come back too, not just single IPs
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		testing => 1,
	);
	$fw->init_backend;
	$fw->ban( ban => '10.0.0.1' );
	$fw->ban_cidr( ban => '10.0.0.0/8' );

	$fw->stop;
	ok( eval { $fw->re_init; 1 }, 'ipfw: re_init after stop with a CIDR ban' )
		or diag("re_init died: $@");

	# grab this before calling list, which overwrites test_data
	my @commands = sort @{ $fw->{test_data} };

	is_deeply(
		\@commands,
		[ 'ipfw table kur_ssh add 10.0.0.0/8', 'ipfw table kur_ssh add 10.0.0.1' ],
		'ipfw: re_init re-adds both the IP and the CIDR range'
	);

	is_deeply( [ $fw->list ],      ['10.0.0.1'],   'ipfw: single IP restored' );
	is_deeply( [ $fw->list_cidr ], ['10.0.0.0/8'], 'ipfw: CIDR range restored' );
}

# ipfw will not destroy a table that is still in use by a rule, so the rule
# has to be deleted first. With the old destroy-then-delete ordering the
# destroy failed, the table was left behind, and the following create failed
# with "Table creation failed: File exists" -- which made re_init fail on
# every other run, since the run that failed left things in the state the
# next run could cope with.
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		testing => 1,
	);
	$fw->init_backend;

	is_deeply(
		$fw->{test_data}{fail_okay_commands},
		[ 'ipfw delete 150', 'ipfw table kur_ssh destroy' ],
		'ipfw: init cleanup deletes the rule before destroying the table'
	);

	$fw->teardown;
	is_deeply(
		$fw->{test_data},
		[ 'ipfw delete 150', 'ipfw table kur_ssh destroy' ],
		'ipfw: teardown deletes the rule before destroying the table'
	);
}

# re_init on a backend that was never inited at all also has to work, since
# that is the same "make the setup exist" operation
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'ipfw',
		name    => 'ssh',
		testing => 1,
	);
	$fw->init_backend;
	$fw->{backend_obj}{inited} = 0;

	ok( eval { $fw->re_init; 1 }, 'ipfw: re_init on a never inited backend' )
		or diag("re_init died: $@");
	ok( $fw->{backend_obj}{inited}, 'ipfw: inited after that re_init' );
}

done_testing;
