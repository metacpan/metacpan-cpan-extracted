#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::smart;

# the fake smartctl prints t/data/smart/$device.json, or the scan SMART_TEST_SCAN names
local $Monitoring::Sneck::Checks::smart::SMARTCTL = $FindBin::Bin . '/data/smart/smartctl';
local $ENV{SMART_TEST_SCAN};
my $run = sub {
	my (@args) = @_;
	return Monitoring::Sneck::Checks->run( check => 'smart', args => \@args );
};

my $sda = 'sda Samsung SSD 870 EVO 1TB, S/N S6PTNX0T100001, 31 C, 0 pending, 0 reallocated, 0 uncorrectable';
my $sdb = 'sdb WDC WD40EFRX-68N32N0, S/N WD-WCC7K0000001, 36 C, 8 pending, 2 reallocated, 0 uncorrectable';

# scanning
is(
	$run->()->{stdout},
	"SMART OK - 2 disks ok | sda_bad=0;0;;0 sda_temp=31 nvme0_bad=0;0;;0 nvme0_wear=3%;80;90;0 nvme0_temp=38\n"
		. $sda . "\n"
		. "nvme0 WD Blue SN570 1TB, S/N 22123A800001, 38 C, 3% worn, 0 media errors\n",
	'scan, SATA and NVMe ok'
);
is(
	$run->( '-e', 'nvme' )->{stdout},
	"SMART OK - 1 disk ok | sda_bad=0;0;;0 sda_temp=31\n" . $sda . "\n",
	'scan, excluding NVMe'
);
{
	local $ENV{SMART_TEST_SCAN} = 'scan_open_error.json';
	my $return = $run->();
	is( $return->{code}, 3, 'scan, a disk that can not be opened is UNKNOWN' );
	is(
		$return->{stdout},
		"SMART UNKNOWN - sdz can not be opened, Permission denied, 1 other ok | sda_bad=0;0;;0 sda_temp=31\n"
			. $sda . "\n",
		'scan, a disk that can not be opened is said'
	);
}
{
	local $ENV{SMART_TEST_SCAN} = 'scan_empty.json';
	is( $run->()->{stdout}, "SMART OK - no disks found\n", 'scan, no disks' );
}

# bad sectors
is(
	$run->( '-d', '/dev/sdb' )->{stdout},
	"SMART WARNING - sdb 8 pending, 2 reallocated | sdb_bad=10;0;;0 sdb_temp=36\n" . $sdb . "\n",
	'pending and reallocated'
);
is( $run->( '-d', '/dev/sdb', '-w', '10' )->{code}, 0, 'pending and reallocated, under --warning' );
is( $run->( '-d', '/dev/sdb', '-c', '5' )->{code},  2, 'pending and reallocated, over --critical' );
is(
	$run->( '-d', '/dev/sde' )->{stdout},
	"SMART WARNING - sde 12 grown defects | sde_bad=12;0;;0 sde_temp=29\n"
		. "sde SEAGATE ST4000NM0023, S/N Z1Z0AAAA, 29 C, 12 grown defects, 0 uncorrected errors\n",
	'SCSI grown defects'
);

# failing
my $return = $run->( '-d', '/dev/sdc' );
is( $return->{code}, 2, 'failing health check is CRITICAL' );
like(
	$return->{stdout},
	qr/\ASMART CRITICAL - sdc failing SMART health check, Reallocated_Sector_Ct failing, 16 pending, 3912 reallocated, 16 uncorrectable \|/,
	'failing health check and attribute'
);
is(
	$run->( '-d', '/dev/nvme2' )->{stdout},
	"SMART CRITICAL - nvme2 failing SMART health check, reliability degraded, 3 media errors"
		. " | nvme2_bad=3;0;;0 nvme2_wear=12%;80;90;0 nvme2_temp=41\n"
		. "nvme2 INTEL SSDPEKNW010T8, S/N BTNH000000011P0B, 41 C, 12% worn, 3 media errors\n",
	'NVMe critical warning and media errors'
);
like( $run->( '-d', '/dev/sdg' )->{stdout}, qr/\ASMART WARNING - sdg last self test failed \|/, 'self test failed' );

# wear and temperature
like( $run->( '-d', '/dev/nvme1' )->{stdout}, qr/\ASMART WARNING - nvme1 85% worn \|/, 'NVMe worn' );
is( $run->( '-d', '/dev/nvme1', '--wear-warning', '90' )->{code}, 0, 'NVMe worn, under --wear-warning' );
like(
	$run->( '-d', '/dev/sda', '--temp-warning', '30' )->{stdout},
	qr/\ASMART WARNING - sda 31 C \| sda_bad=0;0;;0 sda_temp=31;30\n/,
	'over --temp-warning'
);
is( $run->( '-d', '/dev/sda', '--temp-critical', '30' )->{code}, 2, 'over --temp-critical' );

# OK without being checked
is( $run->( '-d', '/dev/sdd' )->{stdout}, "SMART OK - sdd in standby\n",   'standby' );
is( $run->( '-d', '/dev/sdf' )->{stdout}, "SMART OK - sdf has no SMART\n", 'no SMART' );

# device types
is(
	$run->( '-d', '/dev/bus/0,megaraid,0' )->{stdout},
	"SMART OK - 1 disk ok | bus/0:megaraid,0_bad=0;0;;0 bus/0:megaraid,0_temp=27\n"
		. "bus/0:megaraid,0 INTEL SSDSC2KB480G8, S/N PHYF000000AA480BGN, 27 C, 0 reallocated\n",
	'MegaRAID disk'
);
is(
	$run->( '-d', '/dev/sda,sat', '-d', '/dev/sdb', '-d', '/dev/sdd' )->{stdout},
	"SMART WARNING - sdb 8 pending, 2 reallocated, sdd in standby, 1 other ok"
		. " | sda_bad=0;0;;0 sda_temp=31 sdb_bad=10;0;;0 sdb_temp=36\n"
		. $sda . "\n"
		. $sdb . "\n",
	'several disks'
);

# UNKNOWN
is(
	$run->( '-d', '/dev/sdh' )->{stdout},
	"SMART UNKNOWN - sdh smartctl exited 2, Smartctl open device: /dev/sdh failed: No such device\n",
	'open failing'
);
is( $run->( '-d', '/dev/sdi' )->{stdout}, "SMART UNKNOWN - sdi smartctl exited 0, without JSON\n",  'not JSON' );
is( $run->( '-e', '(' )->{combined},      "SMART UNKNOWN - --exclude \"(\" is not a valid regex\n", 'bad --exclude' );
{
	local $Monitoring::Sneck::Checks::smart::SMARTCTL = $FindBin::Bin . '/data/smart/nope';
	like( $run->()->{stdout}, qr/\ASMART UNKNOWN - \S+nope is not there\n\z/, 'smartctl not there' );
}

done_testing();
