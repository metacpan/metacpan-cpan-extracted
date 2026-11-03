#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::reboot_needed;

my $data = $FindBin::Bin . '/data/reboot_needed';
local $Monitoring::Sneck::Checks::base::OS                       = 'linux';
local $Monitoring::Sneck::Checks::base::PROC                     = $data . '/proc';
local $Monitoring::Sneck::Checks::reboot_needed::BOOT            = $data . '/boot';
local $Monitoring::Sneck::Checks::reboot_needed::MODULES         = $data . '/modules';
local $Monitoring::Sneck::Checks::reboot_needed::DPKG_STATUS     = $data . '/status';
local $Monitoring::Sneck::Checks::reboot_needed::REBOOT_REQUIRED = $data . '/nope';
local $Monitoring::Sneck::Checks::reboot_needed::RELEASE         = '6.12.48+deb13-amd64';
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'reboot_needed', args => [@_] ) };

my $return = $run->();
is( $return->{code},   0, 'nothing waiting, a old modules dir ignored' );
is( $return->{stdout}, "REBOOT_NEEDED OK - running 6.12.48+deb13-amd64, nothing is waiting on a reboot\n", 'output' );

{
	local $Monitoring::Sneck::Checks::reboot_needed::BOOT = $data . '/boot_newer';
	is(
		$run->()->{stdout},
		"REBOOT_NEEDED WARNING - kernel 6.12.57+deb13-amd64 is installed, but 6.12.48+deb13-amd64 is running\n",
		'newer kernel'
	);
}
{
	local $Monitoring::Sneck::Checks::reboot_needed::MODULES = $data . '/modules_newer';
	is( $run->('-c')->{code}, 2, 'newer kernel in /lib/modules, CRITICAL with -c' );
}
{
	local $Monitoring::Sneck::Checks::reboot_needed::DPKG_STATUS = $data . '/status_newer';
	is(
		$run->()->{stdout},
		"REBOOT_NEEDED WARNING - linux-image-6.12.48+deb13-amd64 6.12.48-2 is installed, but 6.12.48-1 is running\n",
		'same release, newer package'
	);
}
{
	local $Monitoring::Sneck::Checks::reboot_needed::REBOOT_REQUIRED = $data . '/reboot-required';
	is(
		$run->()->{stdout},
		qq{REBOOT_NEEDED WARNING - $data/reboot-required is there, "System restart required"\nfor libc6, linux-base\n},
		'reboot-required'
	);
}

# replaced libraries, through the fake /proc
is( $run->()->{code}, 0, 'replaced libraries only with -l' );
is(
	$run->('-l')->{stdout},
	"REBOOT_NEEDED WARNING - 2 processes using replaced libraries\nnginx[100] uses libssl.so.3\nsshd[300] uses libcrypto.so.3, libssl.so.3\n",
	'-l'
);
is( $run->( '-l', '-n', 1 )->{stdout},
	"REBOOT_NEEDED WARNING - 2 processes using replaced libraries\nnginx[100] uses libssl.so.3\nand 1 more\n",
	'-n' );

# FreeBSD
{
	local $Monitoring::Sneck::Checks::base::OS                       = 'freebsd';
	local $Monitoring::Sneck::Checks::reboot_needed::RELEASE         = '14.1-RELEASE-p5';
	local $Monitoring::Sneck::Checks::reboot_needed::FREEBSD_VERSION = $data . '/freebsd-version';
	is( $run->()->{code}, 0, 'FreeBSD running what is installed' );
	$Monitoring::Sneck::Checks::reboot_needed::FREEBSD_VERSION = $data . '/freebsd-version_newer';
	is(
		$run->()->{stdout},
		"REBOOT_NEEDED WARNING - kernel 14.1-RELEASE-p6 is installed, but 14.1-RELEASE-p5 is running\n",
		'FreeBSD newer kernel'
	);
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'solaris';
	like( $run->()->{stderr}, qr/not supported on solaris/, 'other OSes' );
}

# version ordering
my $cmp = \&Monitoring::Sneck::Checks::reboot_needed::_version_cmp;
is( $cmp->( '6.12.48+deb13-amd64', '6.1.0-38-amd64' ),  1, '6.12 after 6.1' );
is( $cmp->( '6.12.9-amd64',        '6.12.48-amd64' ),  -1, '9 before 48' );
is( $cmp->( '6.12.48-amd64',       '6.12.48-amd64' ),   0, 'same' );

done_testing();
