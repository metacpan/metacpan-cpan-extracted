#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::mount;

my $data = $FindBin::Bin . '/data/mount';
local $Monitoring::Sneck::Checks::base::OS     = 'linux';
local $Monitoring::Sneck::Checks::base::PROC   = $data . '/proc';
local $Monitoring::Sneck::Checks::mount::FSTAB = $data . '/fstab';
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'mount', args => [@_] ) };

my $return = $run->();
is( $return->{code},   0,                        'all mounted, lazy ones not needed' );
is( $return->{stdout}, "MOUNT OK - 3 mounted\n", 'output' );

# / read only and /srv/my data not mounted
$Monitoring::Sneck::Checks::base::PROC = $data . '/proc_ro';
is(
	$run->()->{stdout},
	"MOUNT CRITICAL - 3 mounted, / is read only, /srv/my data is not mounted\n",
	'read only and not mounted, ro in fstab is fine'
);
is( $run->( '-i', '/srv/my data', '-i', '/' )->{stdout}, "MOUNT OK - 2 mounted\n", '--ignore' );
like( $run->( '-p', '/data/', '-i', '/srv/my data', '-i', '/' )->{stdout},
	qr/\AMOUNT CRITICAL - 2 mounted, \/data is not mounted\n\z/, '--path' );
is( $run->( '-n', '-p', '/boot' )->{stdout}, "MOUNT OK - 1 mounted\n", '--no-fstab' );
is( $run->('-n')->{code},                    3,                        '--no-fstab without --path' );
{
	local $Monitoring::Sneck::Checks::mount::FSTAB = $data . '/nope';
	like( $run->()->{stdout}, qr/\AMOUNT UNKNOWN - can not read \S+nope/, 'fstab missing' );
}

# FreeBSD, through a stand in for mount -p
{
	local $Monitoring::Sneck::Checks::base::OS     = 'freebsd';
	local $Monitoring::Sneck::Checks::mount::MOUNT = $data . '/mount';
	local $Monitoring::Sneck::Checks::mount::FSTAB = $data . '/fstab.freebsd';
	is( $run->( '-p', '/var' )->{stdout}, "MOUNT OK - 2 mounted\n", 'FreeBSD' );
}

done_testing();
