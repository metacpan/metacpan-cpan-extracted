#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Temp qw(tempdir);

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                         || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::file_reload') || print "Bail out!\n";
}

sub slurp {
	my ($path) = @_;
	open( my $fh, '<', $path ) or return undef;
	local $/ = undef;
	my $c = <$fh>;
	close($fh);
	return $c;
}

# --- testing mode: inspect the rendered file + reload without touching disk ---
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		testing => 1,
		options => {
			file   => '/etc/nginx/blocklist.conf',
			format => 'deny %%%BAN%%%;',
			reload => 'nginx -s reload',
		},
	);
	$fw->init_backend;

	is( $fw->{test_data}{file},    '/etc/nginx/blocklist.conf', 'init records the target file' );
	is( $fw->{test_data}{reload},  'nginx -s reload',           'init records the reload command' );
	is( $fw->{test_data}{content}, "\n", 'init renders an empty file' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}{content}, "deny 1.2.3.4;\n", 'ban renders the formatted line' );

	$fw->ban( ban => '5.6.7.8' );
	is( $fw->{test_data}{content}, "deny 1.2.3.4;\ndeny 5.6.7.8;\n", 'second ban renders both, sorted' );

	# re-banning is a no-op
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'already banned', 're-banning reports already banned' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}{content}, "deny 5.6.7.8;\n", 'unban removes the line' );

	my @banned = $fw->list;
	is_deeply( [ sort @banned ], ['5.6.7.8'], 'list returns the remaining ban' );

	$fw->teardown;
	is( $fw->{test_data}{content}, undef, 'teardown signals file removal (content undef)' );
}

# --- CIDR ban/unban rendered into the same file ---
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		testing => 1,
		options => {
			file   => '/etc/nginx/blocklist.conf',
			format => 'deny %%%BAN%%%;',
			reload => 'nginx -s reload',
		},
	);
	$fw->init_backend;

	ok( $fw->{backend_obj}->{cidr_supported}, 'the backend reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}{content}, "deny 1.2.3.0/24;\n", 'ban_cidr renders the formatted CIDR line' );

	my @banned_cidr = $fw->list_cidr;
	is_deeply( [ sort @banned_cidr ], ['1.2.3.0/24'], 'list_cidr returns the banned CIDR' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}{content}, "\n", 'unban_cidr removes the CIDR line' );

	@banned_cidr = $fw->list_cidr;
	is_deeply( [ sort @banned_cidr ], [], 'list_cidr is empty after unban_cidr' );
}

# --- header/footer wrapping ---
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		testing => 1,
		options => { file => '/tmp/x', header => '# managed', footer => '# end' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}{content}, "# managed\n9.9.9.9\n# end\n", 'header/footer wrap the ip list' );
}

# --- missing file option is fatal ---
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'file_reload',
			name    => 'bl',
			testing => 1,
			options => {},
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'a missing file option is fatal' );
}

# --- live: the file is really written and the reload hook really runs --------
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/blocklist.conf";
	my $log  = "$dir/reloads";

	my $reloads = sub {
		my $c = slurp($log);
		return defined($c) ? scalar( () = $c =~ /ran/g ) : 0;
	};

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		options => {
			file   => $file,
			format => 'deny %%%BAN%%%;',
			header => '# managed',
			# tee rather than a plain redirect so the reload also produces
			# output, as blank_reload_error defaults to true
			reload => "echo ran | tee -a '$log'",
		},
	);
	$fw->init_backend;
	is( slurp($file), "# managed\n", 'init really writes the header-only file' );
	is( $reloads->(), 1,             'init runs the reload hook' );

	$fw->ban( ban => 'DEAD::BEEF' );
	is( slurp($file), "# managed\ndeny dead::beef;\n", 'ban writes the lowercased formatted line to disk' );
	is( $reloads->(), 2, 'ban runs the reload hook' );

	$fw->ban_cidr( ban => '198.51.100.0/24' );
	like( slurp($file), qr{^deny 198\.51\.100\.0/24;$}m, 'ban_cidr lands in the same file' );

	is( $fw->check, 1, 'default check is healthy while the file exists' );
	unlink($file);
	is( $fw->check, 0, 'default check goes unhealthy when the file is removed externally' );

	$fw->re_init;
	is( $fw->check, 1, 're_init is healthy again' );
	my $c = slurp($file);
	like( $c, qr/^deny dead::beef;$/m,            're_init restored the single IP' );
	like( $c, qr{^deny 198\.51\.100\.0/24;$}m,    're_init restored the CIDR' );

	$fw->unban( ban => 'dead::beef' );
	unlike( slurp($file), qr/dead::beef/, 'unban removes the line on disk' );

	$fw->flush;
	is( slurp($file), "# managed\n", 'flush renders the file back to header only' );

	$fw->ban( ban => '192.0.2.9' );
	my $before = $reloads->();
	$fw->teardown;
	ok( !-e $file, 'teardown with remove_on_teardown=1 unlinks the file' );
	is( $reloads->(), $before + 1, 'teardown runs the reload hook after unlinking' );
}

# --- live: remove_on_teardown=0 and the check command mode -------------------
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/blocklist.conf";

	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		options => {
			file               => $file,
			header             => '# managed',
			footer             => '# end',
			remove_on_teardown => 0,
			# always true even with the file gone, proving the command is what
			# is being used rather than the default file existence test
			check              => 'true',
		},
	);
	$fw->init_backend;
	$fw->ban( ban => '192.0.2.9' );
	unlink($file);
	is( $fw->check, 1, 'a configured check command overrides the file existence test' );
	$fw->teardown;
	is( slurp($file), "# managed\n# end\n", 'teardown with remove_on_teardown=0 leaves a header/footer-only file' );

	my $fw2 = Net::Firewall::BlockerHelper->new(
		backend => 'file_reload',
		name    => 'bl',
		options => { file => "$dir/other.conf", check => 'false' },
	);
	$fw2->init_backend;
	is( $fw2->check, 0, 'a failing check command reports unhealthy even with the file present' );
}

# --- live: reload failures raise the calling operation's error code ----------
# done on the backend directly as that is where the codes are defined
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/blocklist.conf";

	{
		local $@;
		eval {
			my $b = Net::Firewall::BlockerHelper::backends::file_reload->new(
				name    => 'bl',
				options => { file => $file, reload => 'false' },
			);
			$b->init;
		};
		ok( $@, 'a failing reload at init dies' );
		is( $Error::Helper::error, 12, 'init reload failure raises 12 backendInitError' );
	}

	my $b = Net::Firewall::BlockerHelper::backends::file_reload->new(
		name    => 'bl',
		options => { file => $file },
	);
	$b->init;
	$b->{options}{reload} = 'false';
	{
		local $@;
		eval { $b->ban( ban => '192.0.2.9' ); };
		ok( $@, 'a failing reload at ban dies' );
		is( $Error::Helper::error, 13, 'ban reload failure raises 13 banFailed' );
	}
	{
		local $@;
		eval { $b->unban( ban => '192.0.2.9' ); };
		ok( $@, 'a failing reload at unban dies' );
		is( $Error::Helper::error, 14, 'unban reload failure raises 14 unbanFailed' );
	}

	# a reload command that can not be executed at all must die with a
	# meaningful message rather than warning about undef output
	$b->{options}{reload} = '/no/such/binary/anywhere';
	{
		local $@;
		my @warnings;
		local $SIG{__WARN__} = sub { push( @warnings, $_[0] ) };
		eval { $b->ban( ban => '192.0.2.10' ); };
		ok( $@, 'an unexecutable reload command dies' );
		is( scalar( grep { /uninitialized/ } @warnings ),
			0, 'an unexecutable reload command does not warn about undef output' );
	}
}

# --- live: blank_reload_error ------------------------------------------------
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/blocklist.conf";

	# default: a reload that exits zero but outputs nothing is an error
	{
		local $@;
		eval {
			my $b = Net::Firewall::BlockerHelper::backends::file_reload->new(
				name    => 'bl',
				options => { file => $file, reload => 'true' },
			);
			$b->init;
		};
		ok( $@, 'a silent reload dies with blank_reload_error at its default of 1' );
		is( $Error::Helper::error, 12, 'the silent reload raises the calling operation error code' );
		like(
			$Error::Helper::errorString,
			qr/produced no output and blank_reload_error is true/,
			'the error string says the output was blank rather than claiming the command failed'
		);
	}

	# blank_reload_error=0: silent success is fine, non-zero exit still fatal
	{
		my $b = Net::Firewall::BlockerHelper::backends::file_reload->new(
			name    => 'bl',
			options => { file => $file, reload => 'true', blank_reload_error => 0 },
		);
		local $@;
		eval {
			$b->init;
			$b->ban( ban => '192.0.2.11' );
		};
		ok( !$@, 'a silent reload is fine with blank_reload_error=0' ) or diag($@);
		eval { $b->{options}{reload} = 'false'; $b->ban( ban => '192.0.2.12' ); };
		ok( $@, 'a failing reload still dies with blank_reload_error=0' );
	}
}

done_testing();
