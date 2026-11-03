#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::debsecan;
use Monitoring::Sneck::Checks::pkg_audit;

plan( skip_all => 'needs fork' ) if $^O eq 'MSWin32';

my $dir = TestTmp::dir();

# writes a stand in for a command, saving its args to $name.args, printing output, and exiting with exit
my $command = sub {
	my ( $name, $exit, $output ) = @_;
	my $path = $dir . '/' . $name;
	open( my $fh, '>', $path ) or die($!);
	print $fh '#!'
		. $^X
		. "\n\$| = 1;\n"
		. 'open( my $args, ">", "'
		. $path
		. '.args" ); print $args join( " ", @ARGV ); close($args);' . "\n"
		. "print <<'END';\n"
		. $output . "END\n"
		. 'print STDERR "to stderr\n" if '
		. $exit . ' > 1;' . "\n" . 'exit '
		. $exit . ";\n";
	close($fh);
	chmod( 0755, $path );
	return $path;
}; ## end $command = sub
my $args_of = sub {
	open( my $fh, '<', $_[0] . '.args' ) or return undef;
	my $args = <$fh>;
	return $args;
};
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# debsecan
open( my $os_release, '>', $dir . '/os-release' ) or die($!);
print $os_release qq{PRETTY_NAME="Debian GNU/Linux 13 (trixie)"\nVERSION_CODENAME=trixie\nID=debian\n};
close($os_release);
local $Monitoring::Sneck::Checks::debsecan::OS_RELEASE = $dir . '/os-release';
local $Monitoring::Sneck::Checks::debsecan::DEBSECAN   = $command->( 'debsecan', 0, <<'END' );
CVE-2025-0001 libfoo1 (fixed)
CVE-2025-0001 libfoo-dev (fixed)
CVE-2025-0002 bar (fixed, high urgency)
CVE-2025-0003 baz (fixed, remotely exploitable, medium urgency)
CVE-2025-0004 old-thing (fixed, obsolete)
CVE-2025-0005 qux
END
my $return = $run->('debsecan');
is( $return->{code}, 2, 'high urgency and obsolete over 1 are CRITICAL' );
is(
	$return->{stdout},
	"DEBSECAN CRITICAL - fixed 5, obsolete 1, high 1, medium 1, low 0, in 6 packages, trixie, too many obsolete, high | fixed=5;20;30;0 obsolete=1;1;1;0 high=1;1;1;0 medium=1;5;10;0 low=0;10;20;0\n"
		. "CVE-2025-0001 libfoo1 (fixed)\nCVE-2025-0001 libfoo-dev (fixed)\nCVE-2025-0002 bar (fixed, high urgency)\nCVE-2025-0003 baz (fixed, remotely exploitable, medium urgency)\nCVE-2025-0004 old-thing (fixed, obsolete)\nCVE-2025-0005 qux\n",
	'output, with what it found'
);
is(
	$args_of->($Monitoring::Sneck::Checks::debsecan::DEBSECAN),
	'--suite trixie --only-fixed',
	'suite from os-release, only fixed'
);
like(
	$run->( 'debsecan', '-o', 5, '-O', 5, '-u', 5, '-U', 5, '-n', 2 )->{stdout},
	qr/\ADEBSECAN OK - [^\n]+\n\z/,
	'OK, nothing listed'
);
like(
	$run->( 'debsecan', '-o', 5, '-O', 5, '-U', 5, '-n', 2 )->{stdout},
	qr/\ADEBSECAN WARNING - .*, too many high \|[^\n]+\n[^\n]+\n[^\n]+\nand 4 more\n\z/,
	'WARNING, the list cut at --lines'
);
$run->( 'debsecan', '-a', '-s', 'bookworm' );
is( $args_of->($Monitoring::Sneck::Checks::debsecan::DEBSECAN), '--suite bookworm', '--suite and --all' );
{
	local $Monitoring::Sneck::Checks::debsecan::OS_RELEASE = $dir . '/nope';
	$run->('debsecan');
	is( $args_of->($Monitoring::Sneck::Checks::debsecan::DEBSECAN), '--only-fixed', 'no suite known, none given' );
}
{
	local $Monitoring::Sneck::Checks::debsecan::DEBSECAN
		= $command->( 'debsecan_fails', 3, "error: could not download\n" );
	is(
		$run->('debsecan')->{stdout},
		qq{DEBSECAN UNKNOWN - debsecan exited 3, "error: could not download"\n},
		'debsecan failing'
	);
	local $Monitoring::Sneck::Checks::debsecan::DEBSECAN = $dir . '/nope';
	like(
		$run->('debsecan')->{stderr},
		qr/\ADEBSECAN UNKNOWN - can not run \S+nope, No such file/,
		'debsecan not there'
	);
}
is( $run->( 'debsecan', '-s', 'Trixie;' )->{code}, 3, 'bad --suite' );

# pkg_audit
my $db = $dir . '/vuln.xml';
open( my $db_fh, '>', $db ) or die($!);
close($db_fh);
local $Monitoring::Sneck::Checks::pkg_audit::PKG = $command->( 'pkg', 1, <<'END' );
curl-8.4.0 is vulnerable:
  curl -- SOCKS5 heap buffer overflow
  CVE: CVE-2023-38545
  WWW: https://vuxml.FreeBSD.org/freebsd/d6c19e8c-6806-11ee-9464-b42e991fc52e.html

sudo-1.9.14 is vulnerable:
  sudo -- multiple vulnerabilities
  CVE: CVE-2023-42465
  WWW: https://vuxml.FreeBSD.org/freebsd/00000000-0000-0000-0000-000000000000.html

2 problem(s) in 2 installed package(s) found.
END
$return = $run->( 'pkg_audit', '-d', $db );
is( $return->{code}, 2, 'vulnerable is CRITICAL' );
is(
	$return->{stdout},
	"PKG_AUDIT CRITICAL - 2 vulnerable packages, curl-8.4.0, sudo-1.9.14 | vulnerable=2;;0;0\n"
		. "curl-8.4.0: curl -- SOCKS5 heap buffer overflow\nsudo-1.9.14: sudo -- multiple vulnerabilities\n",
	'output'
);
is( $args_of->($Monitoring::Sneck::Checks::pkg_audit::PKG),     'audit', 'pkg audit' );
is( $run->( 'pkg_audit', '-d', $db, '-w', 0, '-c', 5 )->{code}, 1,       'ranges' );
$run->( 'pkg_audit', '-j', 'www', '-F' );
is( $args_of->($Monitoring::Sneck::Checks::pkg_audit::PKG), '-j www audit -F', '--jail and --fetch' );
utime( time - 86400 * 5, time - 86400 * 5, $db );
like(
	$run->( 'pkg_audit', '-d', $db, '-c', 5 )->{stdout},
	qr/\APKG_AUDIT WARNING - .*, the vulnerability database is 5 days old \|/,
	'old database'
);
is( $run->( 'pkg_audit', '-d', $db, '-c', 5, '-a', 0 )->{code}, 0, '--max-age 0' );
is( $run->( 'pkg_audit', '-j', 'www', '-c', 5 )->{code}, 0, 'a jail without --db is not age checked' );
{
	local $Monitoring::Sneck::Checks::pkg_audit::PKG
		= $command->( 'pkg_ok', 0, "0 problem(s) in 0 installed package(s) found.\n" );
	utime( time, time, $db );
	is(
		$run->( 'pkg_audit', '-d', $db )->{stdout},
		"PKG_AUDIT OK - 0 vulnerable packages | vulnerable=0;;0;0\n",
		'nothing vulnerable'
	);
	local $Monitoring::Sneck::Checks::pkg_audit::PKG
		= $command->( 'pkg_nodb', 1, "pkg: vulnerability database does not exist, try -F\n" );
	like(
		$run->( 'pkg_audit', '-d', $db )->{stdout},
		qr/exited 1 without saying what is vulnerable, "pkg: vulnerability database does not exist, try -F"/,
		'no database'
	);
	local $Monitoring::Sneck::Checks::pkg_audit::PKG = $command->( 'pkg_fails', 70, "" );
	like(
		$run->( 'pkg_audit', '-d', $db )->{stdout},
		qr/\APKG_AUDIT UNKNOWN - pkg audit exited 70, "to stderr"/,
		'pkg failing, stderr caught'
	);
}
is( $run->( 'pkg_audit', '-j', 'w w' )->{code}, 3, 'bad --jail' );

done_testing();
