#!perl -T
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use Statistics::Covid::Version;
use Statistics::Covid::Version::IO;
use File::Temp;
use File::Spec;
use File::Basename;

my $dirname = dirname(__FILE__);

use Test::More;

my $num_tests = 0;

my ($ret, $count, $io, $schema, $versionObj);

my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
ok(-d $tmpdir, "output dir exists"); $num_tests++;
my $tmpdbfile = "adb.sqlite";
my $configfile = File::Spec->catfile($dirname, 'config-for-t.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($configfile);
ok(defined($confighash), "config json file parsed."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = File::Spec->catfile($tmpdir, 'files');
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
$confighash->{'dbparams'}->{'dbdir'} = File::Spec->catfile($tmpdir, 'db');
$confighash->{'dbparams'}->{'dbname'} = $tmpdbfile;
my $dbfullpath = File::Spec->catfile($confighash->{'dbparams'}->{'dbdir'}, $confighash->{'dbparams'}->{'dbname'});

$io = Statistics::Covid::Version::IO->new({
	# the params
	'config-hash' => $confighash,
	'debug' => 1,
});
ok(defined($io), "Statistics::Covid::Version::IO->new() called"); $num_tests++;
ok(-d $tmpdir, "output dir exists"); $num_tests++;

$versionObj = Statistics::Covid::Version::make_random_object(123);
ok(defined $versionObj, "created Version"); $num_tests++;
$versionObj->debug(1);

my $version = $versionObj->version();

$schema = $io->db_connect();
ok(defined($schema), "connect to DB"); $num_tests++;

$count = $io->db_count();
if( $count > 0 ){
	$ret=$io->db_delete_rows();
	ok($ret>0, "erased all table rows"); $num_tests++;
	ok(0==$io->db_count(), "no rows in table exist"); $num_tests++;
}

$ret = $io->db_insert($versionObj);
ok($ret==1, "Version object inserted, 1st time"); $num_tests++;

# now read it back
my $versions = $io->db_select(); # only 1 row
ok(defined($versions), "Version table has content."); $num_tests++;
ok(1==scalar(@$versions), "Version table has exactly 1 row."); $num_tests++;
ok($versions->[0]->equals($versionObj), "exact same version objects in memory and DB."); $num_tests++;

is($io->db_disconnect(), 1, "disconnect from DB"); $num_tests++;

done_testing($num_tests);
