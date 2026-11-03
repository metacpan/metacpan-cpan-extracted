#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::kernel_modules;
use Monitoring::Sneck::Checks::packages;
use Monitoring::Sneck::Checks::accounts;

my $data = $FindBin::Bin . '/data';
local $Monitoring::Sneck::Checks::base::OS   = 'linux';
local $Monitoring::Sneck::Checks::base::PROC = $data . '/sysctl/proc';
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};
my %sysctl;
{
	no warnings 'once';
	$INC{'BSD/Sysctl.pm'} = __FILE__;
	*BSD::Sysctl::sysctl = sub { return $sysctl{ $_[0] } };
}

# sysctl
my $return = $run->(
	'sysctl', '-e', 'kernel.randomize_va_space=2', '-e',
	'net.ipv4.ip_forward=0|2', '-e', 'net.ipv4.ip_local_port_range=32768 60999'
);
is( $return->{code}, 0, 'as wanted' );
is(
	$return->{stdout},
	"SYSCTL OK - kernel.randomize_va_space 2, net.ipv4.ip_forward 0, net.ipv4.ip_local_port_range 32768 60999\n",
	'output, tabs squashed'
);
is(
	$run->(
		'sysctl',                 '-e', 'kernel.randomize_va_space!=2', '-e',
		'net.ipv4.ip_forward>=1', '-e', 'kernel.nope=1',                '-e',
		'net/ipv4/conf/eth0.100/forwarding=0'
	)->{stdout},
	"SYSCTL CRITICAL - kernel.randomize_va_space is 2, wanted anything but 2, net.ipv4.ip_forward is 0, wanted at least 1, kernel.nope is not there, net/ipv4/conf/eth0.100/forwarding is 1, wanted 0\n",
	'not as wanted, a / name'
);
is( $run->( 'sysctl', '-e', 'kernel.nope=1', '-m' )->{stdout}, "SYSCTL OK - none of them are there\n", '--missing-ok' );
is( $run->( 'sysctl', '-e', 'kernel.empty=' )->{stdout}, "SYSCTL OK - kernel.empty \"\"\n", 'a empty value wanted' );
is(
	$run->( 'sysctl', '-e', 'kernel.empty=x' )->{stdout},
	"SYSCTL CRITICAL - kernel.empty is \"\", wanted x\n",
	'a empty value not wanted'
);
is(
	$run->( 'sysctl', '-e', 'net/../../../etc/passwd=1' )->{stdout},
	"SYSCTL CRITICAL - net/../../../etc/passwd is not there\n",
	'.. not followed'
);

foreach my $bad ( ['-e'], [ '-e', 'kernel.x' ], [ '-e', 'kernel.x>=abc' ] ) {
	is( $run->( 'sysctl', @{$bad} )->{code}, 3, 'bad args, ' . join( ' ', @{$bad} ) );
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	%sysctl = ( 'kern.securelevel' => -1, 'vm.loadavg' => [ 1, 2, 3 ] );
	is( $run->( 'sysctl', '-e', 'kern.securelevel>=1' )->{stdout},
		"SYSCTL CRITICAL - kern.securelevel is -1, wanted at least 1\n", 'FreeBSD' );
	is( $run->( 'sysctl', '-e', 'vm.loadavg=1 2 3' )->{code}, 0, 'FreeBSD array values' );
}

# kernel_modules
$Monitoring::Sneck::Checks::base::PROC = $data . '/kernel_modules/proc';
local $Monitoring::Sneck::Checks::kernel_modules::MODULES = $data . '/kernel_modules/modules';
local $Monitoring::Sneck::Checks::kernel_modules::RELEASE = '6.12.48';
local @Monitoring::Sneck::Checks::kernel_modules::MODPROBE_DIRS
	= ( $data . '/kernel_modules/modprobe.d', $data . '/kernel_modules/nope.d' );
$return = $run->( 'kernel_modules', '-p', 'ext4', '-p', 'loop', '-a', 'firewire-core', '-n', 'cramfs', '-n', 'udf' );
is( $return->{code}, 0, 'as wanted' );
is(
	$return->{stdout},
	"KERNEL_MODULES OK - ext4 loaded, loop loaded, firewire-core not loaded, cramfs not loadable, udf not loadable\n",
	'output, built in counts'
);
is(
	$run->( 'kernel_modules', '-p', 'zfs', '-a', 'usb-storage', '-a', 'vfat', '-n', 'dccp' )->{stdout},
	"KERNEL_MODULES CRITICAL - zfs is not loaded, usb-storage is loaded, vfat is built in, dccp is loaded and is not kept from loading by a install line in modprobe.d\n",
	'not as wanted, - and _ the same'
);
is( $run->('kernel_modules')->{code}, 3, 'nothing to check' );
{
	local $Monitoring::Sneck::Checks::base::OS                = 'freebsd';
	local $Monitoring::Sneck::Checks::kernel_modules::KLDSTAT = $data . '/kernel_modules/kldstat';
	is( $run->( 'kernel_modules', '-p', 'zfs', '-a', 'ipfw' )->{stdout},
		"KERNEL_MODULES OK - zfs loaded, ipfw not loaded\n", 'FreeBSD' );
	like(
		$run->( 'kernel_modules', '-n', 'ipfw' )->{stderr},
		qr/--not-loadable is not supported on freebsd/,
		'FreeBSD --not-loadable'
	);
}

# packages
local $Monitoring::Sneck::Checks::packages::DPKG_STATUS = $data . '/packages/status';
is(
	$run->( 'packages', '-i', 'openssh-server', '-i', 'libc6', '-a', 'telnet', '-a', 'rsh-client' )->{stdout},
	"PACKAGES OK - openssh-server installed, libc6 installed, telnet not installed, rsh-client not installed\n",
	'dpkg, held counts, config files do not'
);
is(
	$run->( 'packages', '-i', 'auditd', '-a', 'openssh-server' )->{stdout},
	"PACKAGES CRITICAL - auditd is not installed, openssh-server is installed\n",
	'not as wanted'
);
like( $run->( 'packages', '-i', 'x', '-j', 'www' )->{stderr}, qr/--jail is only for freebsd/, '--jail on Linux' );
{
	local $Monitoring::Sneck::Checks::base::OS      = 'freebsd';
	local $Monitoring::Sneck::Checks::packages::PKG = $data . '/packages/pkg';
	is( $run->( 'packages', '-i', 'sudo', '-a', 'nginx' )->{code}, 0, 'FreeBSD' );
	is(
		$run->( 'packages', '-a', 'nginx', '-j', 'www' )->{stdout},
		"PACKAGES CRITICAL - nginx is installed in jail www\n",
		'FreeBSD jail'
	);
}
is( $run->('packages')->{code}, 3, 'nothing to check' );

# accounts
local $Monitoring::Sneck::Checks::accounts::PASSWD = $data . '/accounts/passwd';
local $Monitoring::Sneck::Checks::accounts::SHADOW = $data . '/accounts/shadow';
local $Monitoring::Sneck::Checks::accounts::SHELLS = $data . '/accounts/shells';
$return = $run->( 'accounts', '-s', '-p', 'alice', '-a', 'guest' );
is( $return->{code},   0,                            'fine' );
is( $return->{stdout}, "ACCOUNTS OK - 5 accounts\n", 'output' );
is_deeply( [ Monitoring::Sneck::Checks::accounts->new->shells ], [ '/bin/sh', '/bin/bash' ], 'shells as getusershell' );

# backup has a shell only named in a comment, and nopw a empty field in passwd that shadow does not override
$Monitoring::Sneck::Checks::accounts::PASSWD = $data . '/accounts/passwd_bad';
$Monitoring::Sneck::Checks::accounts::SHADOW = $data . '/accounts/shadow_bad';
is(
	$run->( 'accounts', '-s', '-p', 'alice', '-a', 'guest' )->{stdout},
	"ACCOUNTS CRITICAL - 7 accounts, UID 0 for toor, more than one account with the name guest, more than one account with the uid 1, no password for guest, nopw, toor, system accounts with a login shell, daemon, there but should not be, guest, missing alice\n",
	'every problem'
);
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	like(
		$run->( 'accounts', '-n' )->{stdout},
		qr/\AACCOUNTS CRITICAL - 7 accounts, more than one account/,
		'toor allowed on FreeBSD'
	);
	local $Monitoring::Sneck::Checks::accounts::MASTER_PASSWD = $data . '/accounts/nope';
	like(
		$run->('accounts')->{stdout},
		qr/\AACCOUNTS CRITICAL - .*, can not read the passwords, \S+nope\n\z/,
		'unreadable passwords noted'
	);
	is( $run->('accounts')->{code}, 2, 'CRITICAL is worse than the UNKNOWN for it' );
}
$Monitoring::Sneck::Checks::accounts::PASSWD = $data . '/accounts/passwd_root';
{
	local $Monitoring::Sneck::Checks::accounts::SHADOW = $data . '/accounts/nope';
	is( $run->('accounts')->{code},         3, 'only unreadable passwords is UNKNOWN' );
	is( $run->( 'accounts', '-n' )->{code}, 0, '--no-passwords' );
}

done_testing();
