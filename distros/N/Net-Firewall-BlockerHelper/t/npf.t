#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::npf') || print "Bail out!\n";
}

my $fw = Net::Firewall::BlockerHelper->new(
	backend => 'npf',
	name    => 'ssh',
	prefix  => 'derp',
	testing => 1,
);
$fw->init_backend;
is_deeply(
	$fw->{test_data},
	{ commands => ['npfctl table derp_ssh list'] },
	'init verifies the table is declared in npf.conf'
);

$fw->ban( ban => '1.2.3.4' );
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh add 1.2.3.4'], 'ban adds to the table' );

$fw->ban( ban => 'dead::1' );
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh add dead::1'], 'IPv6 ban adds to the table' );

$fw->ban( ban => '1.2.3.4' );
is( $fw->{test_data}, 'already banned', 'double ban short-circuits' );

$fw->unban( ban => 'dead::1' );
is( $fw->{test_data}, 'npfctl table derp_ssh rem dead::1', 'unban removes from the table' );

ok( $fw->{backend_obj}->{cidr_supported}, 'cidr supported' );
$fw->ban_cidr( ban => '1.2.3.0/24' );
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh add 1.2.3.0/24'], 'ban_cidr adds the range' );
is_deeply( [ $fw->list_cidr ], ['1.2.3.0/24'], 'list_cidr shows the range' );
$fw->unban_cidr( ban => '1.2.3.0/24' );
is( $fw->{test_data}, 'npfctl table derp_ssh rem 1.2.3.0/24', 'unban_cidr removes the range' );
is( scalar( $fw->list_cidr ), 0, 'list_cidr empty after unban' );

is( $fw->check, 1, 'check reports healthy in testing mode' );
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh list'], 'check probes the table' );

$fw->re_init;
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh add 1.2.3.4'], 're_init re-adds the remaining ban' );

$fw->flush;
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh flush'], 'flush flushes the table' );
is( scalar( $fw->list ), 0, 'flush empties the ban list' );

$fw->teardown;
is_deeply( $fw->{test_data}, ['npfctl table derp_ssh flush'], 'teardown flushes the table' );

# --- custom table option --------------------------------------------------------
{
	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'npf',
		name    => 'ssh',
		options => { table => 'fail2ban' },
		testing => 1,
	);
	$fw2->init_backend;
	$fw2->ban( ban => '1.2.3.4' );
	is_deeply( $fw2->{test_data}, ['npfctl table fail2ban add 1.2.3.4'], 'a custom table name is used' );
}

# --- validation, on the backend directly as that is where these are checked ------
{
	local $@;
	eval { Net::Firewall::BlockerHelper::backends::npf->new( name => 'ssh', ports => ['22'] ); };
	ok( $@, 'ports error as unsupported' );
	is( $Error::Helper::error, 26, 'ports raise error 26' );

	eval { Net::Firewall::BlockerHelper::backends::npf->new( name => 'ssh', protocols => ['tcp'] ); };
	ok( $@, 'protocols error as unsupported' );

	eval { Net::Firewall::BlockerHelper::backends::npf->new( name => 'ssh', options => { table => 'bad table' } ); };
	ok( $@, 'an invalid table name errors' );
}

done_testing();
