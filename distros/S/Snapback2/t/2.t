# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Config::ApacheFormat') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Cwd;
use File::Path;
my $curdir = cwd();

my @dirs = (
	"$curdir/b_source",
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
</backup>
EOF


SKIP: {

	my $clink = `cp --help`;
	skip "No gnu copy for linking", 1 unless $clink =~ /--link/;

	system "$^X blib/script/snapback2 -c b_source/test_snapback.cfg";
	my $testfile = "$curdir/b_target/pseudo$curdir/b_source/hourly.0/test_snapback.cfg";
	my $status = -f $testfile;

	ok($status);
}

#File::Path::rmtree([@dirs]);
