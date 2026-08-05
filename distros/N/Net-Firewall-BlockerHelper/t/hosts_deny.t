#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

sub slurp {
	my ($path) = @_;
	open( my $fh, '<', $path ) or return '';
	local $/ = undef;
	my $c = <$fh>;
	close($fh);
	return defined($c) ? $c : '';
}

# --- real file: unmanaged content is preserved, our region is managed --------
{
	my ( $fh, $path ) = tempfile();
	print( $fh "# hand written rule, must survive\nALL : 192.0.2.99\n" );
	close($fh);

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'hosts_deny',
		name    => 'sshd',
		prefix  => 'kur',
		options => { file => $path, daemon => 'sshd' },
	);
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => '5.6.7.8' );

	my $content = slurp($path);
	like( $content, qr/^# hand written rule, must survive$/m, 'unmanaged comment preserved' );
	like( $content, qr/^ALL : 192\.0\.2\.99$/m,               'unmanaged rule preserved' );
	like( $content, qr/^# BEGIN Net::Firewall::BlockerHelper kur_sshd$/m, 'begin marker present' );
	like( $content, qr/^sshd : 1\.2\.3\.4$/m,                 'ban rendered with the configured daemon' );
	like( $content, qr/^sshd : 5\.6\.7\.8$/m,                 'second ban rendered' );

	ok( $fw->check, 'check reports healthy with the region present' );

	$fw->unban( ban => '1.2.3.4' );
	unlike( slurp($path), qr/1\.2\.3\.4/, 'unban removes only that ip' );

	$fw->teardown;
	my $after = slurp($path);
	like( $after,   qr/^ALL : 192\.0\.2\.99$/m, 'teardown keeps the unmanaged rule' );
	unlike( $after, qr/BEGIN Net::Firewall/,    'teardown removes our region entirely' );

	unlink($path);
}

# --- testing mode: block format ---------------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'hosts_deny',
		name    => 'all',
		prefix  => 'derp',
		testing => 1,
		options => {},
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is(
		$fw->{test_data}{block},
		"# BEGIN Net::Firewall::BlockerHelper derp_all\nALL : 9.9.9.9\n# END Net::Firewall::BlockerHelper derp_all\n",
		'default daemon ALL and marker tag from prefix_name'
	);

	# libwrap only matches IPv6 in the bracketed form
	$fw->ban( ban => 'DEAD::1' );
	like( $fw->{test_data}{block}, qr/^ALL : \[dead::1\]$/m, 'IPv6 bans are lowercased and bracketed' );

	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( $fw->{error} == 29 ) { $cidr_blocked = 1; }
	ok( $cidr_blocked, 'ban_cidr sets error 29 cidrNotSupported' );
}

done_testing();
