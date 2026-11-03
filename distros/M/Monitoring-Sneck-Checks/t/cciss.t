#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use File::Path qw(make_path);
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::cciss;

my $dir   = TestTmp::dir();
my $write = sub {
	my ( $name, $content ) = @_;
	my $path = $dir . '/' . $name;
	make_path( $path =~ s{/[^/]+\z}{}r );
	open( my $fh, '>', $path ) or die($!);
	print $fh $content;
	close($fh);
	return $path;
};
local $Monitoring::Sneck::Checks::base::OS            = 'linux';
local $Monitoring::Sneck::Checks::cciss::SYS_VENDOR   = $write->( 'sys_vendor', "HP\n" );
local $Monitoring::Sneck::Checks::cciss::SCSI_GENERIC = $dir . '/scsi_generic';
local $Monitoring::Sneck::Checks::cciss::DEV          = $dir . '/dev';

# prints what was saved for the device it is given, and exits 1 if that is not all OK, as it does
local $Monitoring::Sneck::Checks::cciss::CCISS_VOL_STATUS = $write->( 'cciss_vol_status', '#!' . $^X . "\n" . <<'END' );
my $file = $0 . '.' . ( $ARGV[-1] =~ s{\A.*/dev/}{}r =~ s{/}{_}gr );
print STDERR "args @ARGV[0 .. $#ARGV - 1]\n" if "@ARGV[0 .. $#ARGV - 1]" ne '-u -s -V';
open( my $fh, '<', $file ) or exit 0;
print while <$fh>;
exit( -e $file . '.exit' ? 1 : 0 );
END
chmod( 0755, $Monitoring::Sneck::Checks::cciss::CCISS_VOL_STATUS );
my $output = sub {
	my ( $device, $content, $exit ) = @_;
	my $name = 'cciss_vol_status.' . ( $device =~ s{/}{_}gr );
	$write->( $name, $content );
	$exit ? $write->( $name . '.exit', '' ) : unlink( $dir . '/' . $name . '.exit' );
};
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# sg0 is the controller, sg1 a plain disk
$write->( 'scsi_generic/sg0/device/type', "12\n" );
$write->( 'scsi_generic/sg1/device/type', "0\n" );

# as from a real H240
my $h240 = <<'END';
Controller: Smart HBA H240
  Board ID: 0x21c7103c
  Logical drives: 1
  Running firmware: 7.00
  ROM firmware: 7.00
/dev/sda: (Smart HBA H240) RAID 5 Volume 0 status: OK.
  Physical drives: 4
         connector 1I box 1 bay 1                  ATA     MB4000GCWLV                          P4G6GHEB             HPG4     OK
         connector 1I box 1 bay 2                  ATA     MB4000GCWLV                          PEHT2WHS             HPG3     OK
         connector 1I box 1 bay 3                  ATA     MB4000GDUPB                          36C5K1LFF17A         HPG4     OK
         connector 1I box 1 bay 4                  ATA     MB4000GCWLV                          P4G6THZB             HPG3     OK
/dev/sg0(Smart HBA H240:0): Non-Volatile Cache status:
                   Cache configured: No
END
$h240 =~ s/(status: OK\.)$/$1 /m;    # it ends the volume line with a space
my $bay2
	= '         connector 1I box 1 bay 2                  ATA     MB4000GCWLV                          PEHT2WHS             HPG3';
$output->( 'sg0', $h240 );
is( $run->('cciss')->{stdout}, "CCISS OK - /dev/sda RAID 5 ok, 4 drives ok\n", 'H240, RAID 5 ok' );

# as from a real one it does not know, with a flash backed cache
$output->( 'sg0', <<'END' );
Controller: Unknown Smart Array
  Board ID: 0x0602103c
  Logical drives: 1
  Running firmware: 5.32
  ROM firmware: 5.32
/dev/sda: (Unknown Smart Array) RAID 1(1+0) Volume 0 status: OK.
  Physical drives: 6
         connector 1I box 3 bay 1                  HPE     MB006000JWWQN                                    WSE0BBLZ     HPD8 OK
         connector 1I box 3 bay 2                  HPE     MB006000JWWQN                                    WSE0EZX6     HPD8 OK
         connector 1I box 3 bay 3                  HPE     MB006000JWWQN                                    WSE0E9S2     HPD8 OK
         connector 1I box 3 bay 4                  HPE     MB006000JWWQN                                    WNB0PETM     HPD8 OK
         connector 2I box 2 bay 1                  HPE     MB006000JWWQN                                    WSE0E9WZ     HPD8 OK
         connector 2I box 2 bay 2                  HPE     MB006000JWWQN                                    WNB0PD4C     HPD8 OK
/dev/sg0(Unknown Smart Array:0): Non-Volatile Cache status:
                   Cache configured: Yes
                 Total cache memory: 1808 MiB
                        Cache Ratio: 10% Read / 90% Write
                  Read cache memory: 181 MiB
                 Write cache memory: 1627 MiB
                Write cache enabled: Yes
   Flash backed cache present
END
is( $run->('cciss')->{stdout}, "CCISS OK - /dev/sda RAID 1(1+0) ok, 6 drives ok\n", 'RAID 1+0 with cache ok' );

# degraded, laid out as print_volume_status and show_disk_map do
my $degraded = $h240
	=~ s/status: OK\. \n/status: Using interim recovery mode. \n  Failed drives:\n$bay2\n\n    Total of 1 failed physical drives detected on this logical drive.\n/r;
$output->( 'sg0', $degraded, 1 );
is( $run->('cciss')->{stdout},
	"CCISS CRITICAL - /dev/sda RAID 5 using interim recovery mode, failed connector 1I box 1 bay 2\n", 'degraded' );

# rebuilding onto a new drive
$output->( 'sg0', $h240 =~ s/status: OK\. \n/status: Currently recovering. \n  'Replacement' drives:\n$bay2\n\n/r, 1 );
my $result = $run->('cciss');
is( $result->{code}, 1, 'recovering is WARNING' );
is( $result->{stdout},
	"CCISS WARNING - /dev/sda RAID 5 currently recovering, replacing connector 1I box 1 bay 2, 4 drives ok\n",
	'recovering' );

# a spare took over, so the volume is OK, but a drive still failed
$output->(
	'sg0',
	$h240
		=~ s/status: OK\. \n/status: OK.   At least one spare drive activated.  At least one activated on-line spare drive is completely rebuilt on this logical drive.\n  Failed drives:\n$bay2\n  Drives currently substituted for by spares:\n$bay2\n\n    Total of 1 failed physical drives detected on this logical drive.\n/r,
	1
);
is(
	$run->('cciss')->{stdout},
	"CCISS CRITICAL - /dev/sda RAID 5 ok, failed connector 1I box 1 bay 2\n",
	'spare took over'
);
$output->(
	'sg0',
	$h240 =~ s/status: OK\. /status: OK.   At least one spare drive designated.  At least one spare drive has failed./r,
	1
);
is( $run->('cciss')->{stdout}, "CCISS CRITICAL - /dev/sda RAID 5 ok, a spare failed, 4 drives ok\n", 'spare failed' );

# volume fine, a drive in predictive failure and the cache with trouble
$output->(
	'sg0',
	( $h240 =~ s/(bay 4 .*HPG3)     OK$/$1     S.M.A.R.T. predictive failure./mr )
		. "                Write cache enabled: No\n   Write cache temporarily disabled\n           Temporary disable condition. Posted write operations have\n           been disabled due to the fact that less than 75% of the\n           battery packs are at the sufficient voltage level.\n",
	1
);
is(
	$run->('cciss')->{stdout},
	"CCISS WARNING - /dev/sda RAID 5 ok, connector 1I box 1 bay 4 predictive failure, $dir/dev/sg0 write cache temporarily disabled\n",
	'predictive failure and cache'
);

# a enclosure
$output->(
	'sg0',
	$h240
		. "/dev/sg0: (Smart HBA H240) Enclosure MSA60 (S/N: USP6340B3F) on Bus 2, Physical Port 1E status: Fan failed, Power Supply Unit failed.\n"
		. "/dev/sg0: (Smart HBA H240) Enclosure MSA60 (S/N: USP6340B3G) on Bus 3, Physical Port 2E status: OK.\n",
	1
);
is(
	$run->('cciss')->{stdout},
	"CCISS CRITICAL - /dev/sda RAID 5 ok, 4 drives ok, enclosure MSA60 port 1E fan failed, power supply unit failed\n",
	'enclosure'
);

# overheated in the past, failed, and a status it does not know
$output->( 'sg0', $h240 =~ s/status: OK\./status: Hardware was overheated./r, 1 );
is( $run->('cciss')->{code}, 1, 'was overheated is WARNING' );
$output->( 'sg0', $h240 =~ s/status: OK\. /status: FAILED. /r, 1 );
is( $run->('cciss')->{stdout}, "CCISS CRITICAL - /dev/sda RAID 5 failed, 4 drives ok\n", 'FAILED' );
$output->( 'sg0', $h240 =~ s/status: OK\. /status: Unknown status 42./r, 1 );
is( $run->('cciss')->{code}, 2, 'unknown status is CRITICAL' );

# used only as a HBA, no logical drives
$output->( 'sg0', ( $h240 =~ s/Logical drives: 1/Logical drives: 0/r ) =~ s/^\/dev\/sda: .*\n//mr );
is( $run->('cciss')->{stdout}, "CCISS OK - $dir/dev/sg0 no logical drives, 4 drives ok\n", 'no logical drives' );

# two controllers, by --device, the second not answering, as it says nothing about devices it can not open
$output->( 'sg0', $h240 );
$result = $run->( 'cciss', '-d', $dir . '/dev/sg0', '-d', $dir . '/dev/sg2' );
is( $result->{code}, 3, 'one not answering is UNKNOWN' );
is(
	$result->{stdout},
	"CCISS UNKNOWN - /dev/sda RAID 5 ok, 4 drives ok, $dir/dev/sg2 said nothing, exited 0, \"\"\n",
	'not answering'
);

# the old cciss driver
{
	local $Monitoring::Sneck::Checks::cciss::SCSI_GENERIC = $dir . '/nope';
	$write->( 'dev/cciss/c0d0',   '' );
	$write->( 'dev/cciss/c0d0p1', '' );
	$output->( 'cciss/c0d0', "/dev/cciss/c0d0: (Smart Array P800) RAID 1 Volume 0 status: OK. \n" );
	is( $run->('cciss')->{stdout}, "CCISS OK - /dev/cciss/c0d0 RAID 1 ok\n", 'cciss driver, without -V output' );
}

# not a HP, no controllers, no cciss_vol_status
{
	local $Monitoring::Sneck::Checks::cciss::SYS_VENDOR = $write->( 'sys_vendor_dell', "Dell Inc.\n" );
	is( $run->('cciss')->{stdout}, "CCISS OK - not a HP\n", 'not a HP' );
}
{
	local $Monitoring::Sneck::Checks::cciss::SYS_VENDOR   = $write->( 'sys_vendor_hpe', "HPE\n" );
	local $Monitoring::Sneck::Checks::cciss::SCSI_GENERIC = $dir . '/nope';
	local $Monitoring::Sneck::Checks::cciss::DEV          = $dir . '/nope';
	is( $run->('cciss')->{stdout}, "CCISS OK - no Smart Array controllers\n", 'HPE, no controllers' );
}
{
	local $Monitoring::Sneck::Checks::cciss::CCISS_VOL_STATUS = $dir . '/nope';
	is( $run->('cciss')->{stdout}, "CCISS UNKNOWN - $dir/nope is not there\n", 'cciss_vol_status not there' );
	local $Monitoring::Sneck::Checks::cciss::CCISS_VOL_STATUS;
	local @Monitoring::Sneck::Checks::cciss::CCISS_VOL_STATUS_PATHS = ( $dir . '/nope' );
	is( $run->('cciss')->{stdout}, "CCISS UNKNOWN - cciss_vol_status is not there\n", 'none of the paths there' );
}

# FreeBSD, ciss devices, the vendor not looked at
{
	local $Monitoring::Sneck::Checks::base::OS          = 'freebsd';
	local $Monitoring::Sneck::Checks::cciss::SYS_VENDOR = $dir . '/nope';
	$write->( 'dev/ciss0', '' );
	$write->( 'dev/ciss1', '' );
	$output->( 'ciss0', $h240 =~ s{/dev/sda:}{/dev/ciss0:}r =~ s{/dev/sg0}{/dev/ciss0}r );
	$output->( 'ciss1', $degraded =~ s{/dev/sda:}{/dev/ciss1:}r =~ s{/dev/sg0}{/dev/ciss1}r, 1 );
	is(
		$run->('cciss')->{stdout},
		"CCISS CRITICAL - /dev/ciss0 RAID 5 ok, 4 drives ok, /dev/ciss1 RAID 5 using interim recovery mode, failed connector 1I box 1 bay 2\n",
		'FreeBSD'
	);
	local $Monitoring::Sneck::Checks::cciss::DEV = $dir . '/nope';
	is( $run->('cciss')->{stdout}, "CCISS OK - no Smart Array controllers\n", 'FreeBSD, no ciss' );
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'openbsd';
	like( $run->('cciss')->{stderr}, qr/not supported on openbsd/, 'not on OpenBSD' );
}

done_testing();
