#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use POSIX ();
use FakeDNS;
use Monitoring::Sneck::Checks;

my $data = $FindBin::Bin . '/data';
my $run  = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# resolv
my $resolv = $data . '/resolv/resolv.conf';
my $return = $run->( 'resolv', '-f', $resolv );
is( $return->{code},   0,                                                                    'good resolv.conf' );
is( $return->{stdout}, 'RESOLV OK - ' . $resolv . ", nameservers 192.0.2.53, fe80::1%em0\n", 'output' );
$return = $run->( 'resolv', '-f', $data . '/resolv/bad.conf' );
is( $return->{code}, 1, 'bad resolv.conf is WARNING' );
like(
	$return->{stdout},
	qr/nameservers none, line 1 nameserver "bogus" is not a IP, line 2 search "bad_domain" is not a domain, line 3 has unknown keyword "frobnicate", line 4 has nothing after domain, no nameservers, so the local host is used\n\z/,
	'every problem'
);
like(
	$run->( 'resolv', '-f', $data . '/resolv/many.conf' )->{stdout},
	qr/4 nameservers, but only the first 3 are used/,
	'too many nameservers'
);
is( $run->( 'resolv', '-f', $data . '/resolv/nope' )->{code}, 2, 'missing is CRITICAL' );

%FakeDNS::ANSWERS = ( 'www.example.org a' => { answer => ['www.example.org. 300 IN A 192.0.2.10'] } );
is( $run->( 'resolv', '-f', $resolv, '-q', 'www.example.org' )->{code}, 0, 'both answer' );
is_deeply(
	[ map { $_->[0][0] } @FakeDNS::ASKED[ -2, -1 ] ],
	[ '192.0.2.53', 'fe80::1' ],
	'each asked, without the scope'
);
is( $run->( 'resolv', '-f', $resolv, '-q', 'nope.example.org' )->{code}, 0, 'NXDOMAIN is a answer' );
{
	local $FakeDNS::ANSWERS{'down.example.org a'} = undef;
	$return = $run->( 'resolv', '-f', $resolv, '-q', 'down.example.org' );
	is( $return->{code}, 2, 'none answering is CRITICAL' );
	like( $return->{stdout}, qr/no nameserver answered for down.example.org/, 'and says so' );
}

# hosts
my $hosts = $data . '/hosts/hosts';
$return = $run->( 'hosts', '-f', $hosts, '-e', 'db=192.0.2.20', '-e', 'DB.example.org=192.0.2.20' );
is( $return->{code},   0,                                        'good hosts' );
is( $return->{stdout}, 'HOSTS OK - ' . $hosts . ", 3 entries\n", 'output' );
$return = $run->( 'hosts', '-f', $hosts, '-e', 'db=192.0.2.21', '-e', 'web=192.0.2.30' );
is( $return->{code}, 2, 'expected mapping wrong is CRITICAL' );
like( $return->{stdout}, qr/, db is 192.0.2.20, not 192.0.2.21, web is not in it, not 192.0.2.30\n\z/, 'and says so' );
$return = $run->( 'hosts', '-f', $data . '/hosts/bad_hosts' );
is( $return->{code}, 1, 'bad hosts is WARNING' );
like(
	$return->{stdout},
	qr/0 entries, line 1 "localhost" is not a IP, line 2 has no names, line 3 "bad_name" is not a hostname, localhost is not in it\n\z/,
	'every problem'
);
is( $run->( 'hosts', '-f', $data . '/hosts/no_local', '--no-localhost' )->{code}, 0, '--no-localhost' );
is( $run->( 'hosts', '-f', $data . '/hosts/nope' )->{code}, 2, 'missing is CRITICAL' );
is( $run->( 'hosts', '-e', 'db' )->{code},                  3, 'bad --expect' );

# file_age, the ages set here as git does not keep them
my $file = $data . '/file_age/age';
utime( time - 300, time - 300, $file ) or die($!);
$return = $run->( 'file_age', '-f', $file );
is( $return->{code}, 1, 'over 240 seconds is WARNING' );
like( $return->{stdout},
	qr/\AFILE_AGE WARNING - \Q$file\E is 30\d seconds old and 100 bytes \| age=30\ds;240;600 size=100B;;;0\n\z/,
	'output' );
is( $run->( 'file_age', '-f', $file, '-w', 400, '-c', 500 )->{code},                0, 'OK' );
is( $run->( 'file_age', '-f', $file, '-c', 200 )->{code},                           2, 'CRITICAL' );
is( $run->( 'file_age', '-f', $file, '-w', 400, '-c', 500, '-W', '1024:' )->{code}, 1, 'too small' );
is( $run->( 'file_age', '-f', $file, '-w', 400, '-c', 500, '-C', '50' )->{code},    2, 'too big' );
is( $run->( 'file_age', '-f', $data . '/file_age/nope' )->{code},                   2, 'missing is CRITICAL' );
is( $run->( 'file_age', '-f', $data . '/file_age/nope', '-i' )->{code},             0, 'missing is OK with -i' );
is( $run->( 'file_age', '-f', $file, '-W', 'big' )->{code},                         3, 'bad range' );

# file_age, the newest of a glob
my $older = $data . '/file_age/db-2026-10-30.sql';
my $newer = $data . '/file_age/db-2026-10-31.sql';
utime( time - 7200, time - 7200, $older );
utime( time - 100,  time - 100,  $newer );
like( $run->( 'file_age', '-n', $data . '/file_age/db-*.sql' )->{stdout},
	qr/\AFILE_AGE OK - the newest of \S+db-\*.sql, \Q$newer\E is 10\d seconds old and 20 bytes \|/, '--newest' );
is(
	$run->( 'file_age', '-n', $data . '/file_age/backup-*' )->{stdout},
	"FILE_AGE CRITICAL - nothing matches $data/file_age/backup-*\n",
	'nothing matching'
);
is( $run->( 'file_age', '-n', $data . '/file_age/backup-*', '-i' )->{code},    0, 'nothing matching with -i' );
is( $run->( 'file_age', '-n', $data . '/file_age/db-*', '-f', $file )->{code}, 3, '--newest and --file' );
is( $run->('file_age')->{code},                                                3, 'neither' );

# file_content
my $logrotate = $data . '/file_content/logrotate';
$return = $run->( 'file_content', '-f', $logrotate, '-x', '-r', '/etc/logrotate\.conf' );
is( $return->{code},   0,                                                     'file_content OK' );
is( $return->{stdout}, 'FILE_CONTENT OK - ' . $logrotate . " looks good\n",   'file_content output' );
is( $run->( 'file_content', '-f', $logrotate, '-r', '/etc/nope' )->{code}, 2, 'commented lines are skipped' );
is( $run->( 'file_content', '-f', $logrotate, '-C', '^$', '-r', '/etc/nope' )->{code}, 0, '--comment' );
is( $run->( 'file_content', '-f', $logrotate, '-R', 'logrotate\.conf' )->{code},       2, '--not-regex' );
is( $run->( 'file_content', '-f', $data . '/file_content/nope' )->{code},              2, 'missing is CRITICAL' );
is( $run->( 'file_content', '-f', $data . '/file_content/nope', '-A' )->{code},        0, '--absent, missing' );
is( $run->( 'file_content', '-f', $logrotate, '-A' )->{code},                          2, '--absent, there' );
is( $run->( 'file_content', '-f', $logrotate, '-A', '-x' )->{code}, 3, '--absent with others is UNKNOWN' );
is( $run->( 'file_content', '-f', $logrotate, '-r', '(' )->{code},  3, 'bad regex is UNKNOWN' );
like(
	$run->( 'file_content', '-f', $data . '/file_content/logrotate_not_executable', '-x' )->{stdout},
	qr/\AFILE_CONTENT CRITICAL - .* is not executable\n\z/,
	'--executable'
);

# mtime, git not keeping mtimes, so they are set here
my $app = $data . '/mtime/app';
utime( 0, 1_000_000_000, $app );
$return = $run->( 'mtime', '-m', '2023-06-22T00:00', '-f', $app );
is( $return->{code},   2, 'mtime older is CRITICAL for le' );
is( $return->{stdout}, "MTIME CRITICAL - mtime at or before 2023-06-22T00:00: $app\n",   'mtime output' );
is( $run->( 'mtime', '-m', '2023-06-22T00:00', '-e', 'gt', '-f', $app )->{code},      0, 'mtime gt' );
is( $run->( 'mtime', '-m', '2023-06-22T00:00', '-f', $data . '/mtime/nope' )->{code}, 3, 'mtime missing file' );
is( $run->( 'mtime', '-m', 'nope', '-f', $app )->{code},                              3, 'mtime bad time' );
is( $run->( 'mtime', '-m', '2023-06-22T00:00', '-e', 'eq', '-f', $app )->{code},      3, 'mtime bad equality' );
is( $run->( 'mtime', '-m', '2023-06-22T00:00' )->{code},                              3, 'mtime without --file' );
{
	# a time without a zone is UTC, whatever the local zone is
	local $ENV{TZ} = 'America/Chicago';
	POSIX::tzset();
	utime( 0, 1687392000, $app );
	is( $run->( 'mtime', '-m', '2023-06-22T00:00', '-f', $app )->{code}, 2, 'mtime at the time, as UTC' );
	utime( 0, 1687392001, $app );
	is( $run->( 'mtime', '-m', '2023-06-22T00:00', '-f', $app )->{code}, 0, 'mtime a second after, as UTC' );
}
POSIX::tzset();

done_testing();
