# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Config::ApacheFormat') };
BEGIN { use_ok('Backup::Snapback') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Cwd;
use File::Path;
my $curdir = cwd();

my @dirs = (
	"$curdir/b_source",
	"$curdir/b_source2",
	"$curdir/b_target",
);

for (@dirs) {
	next if -d $_;
	File::Path::mkpath $_
		or die "Couldn't make directory $_: $!\n";
}

open CFG, "> $curdir/b_source/test_snapback.cfg"
	or die "Couldn't create configuration file: $!\n";
print CFG <<EOF;
Hourlies 2
Dailies 2
Compress No
RsyncShell None
Destination $curdir/b_target
ChargeFile $curdir/b_target/snapback.charges
Logfile $curdir/b_target/snapback.log

<backup pseudo>
	Directory $curdir/b_source
	Hourlies 5
	Dailies 3
	<directory $curdir/b_source2>
		Hourlies 8
		Dailies 14
	</directory>
</backup>
<backup faux>
	Directory $curdir/b_source
	Hourlies 6
	Dailies 5
</backup>
EOF

close CFG;

open CFG, "> $curdir/b_source2/test_snapback.cfg"
	or die "Couldn't create configuration file: $!\n";
print CFG <<EOF;
Hourlies 2
Dailies 2
Compress No
RsyncShell None
Destination $curdir/b_target
ChargeFile $curdir/b_target/snapback.charges
Logfile $curdir/b_target/snapback.log

<backup pseudo>
	Directory $curdir/b_source
	Hourlies 5
	Dailies 3
	<directory $curdir/b_source2>
		Hourlies 8
		Dailies 14
	</directory>
</backup>
<backup faux>
	Directory $curdir/b_source
	Hourlies 6
	Dailies 5
</backup>
EOF
close CFG;

my $snap = new Backup::Snapback configfile => "$curdir/b_source/test_snapback.cfg";

ok($snap->config(-hourlies) == 2, 'basic directive');
ok( join(" ", $snap->backups()) eq "pseudo faux");
$snap->set_backup('pseudo', 'backup container');
ok($snap->config(-hourlies) == 5, 'backup container directive change');
ok( join(" ", $snap->directories()) eq "$curdir/b_source $curdir/b_source2");
$snap->set_directory("$curdir/b_source2");
ok($snap->config(-hourlies) == 8 , 'directory container');
$snap->set_backup('faux');
ok($snap->config(-hourlies) == 6, 'change backup');

SKIP: {
	my $clink = `cp --help`;

	skip "No gnu copy for linking", 2 unless $clink =~ /--link/;
	$snap->set_directory("$curdir/b_source");
	$snap->backup_directory();

	my $testfile = "$curdir/b_target/faux$curdir/b_source/hourly.0/test_snapback.cfg";
	my $status = -f $testfile;
	ok($status, 'backup_directory');

	$snap->backup_all();
	$testfile = "$curdir/b_target/faux$curdir/b_source/hourly.0/test_snapback.cfg";
	$status = -f $testfile;
	ok($status, 'backup_all');

}

#File::Path::rmtree([@dirs]);
