#!/usr/bin/perl -T
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use Statistics::Covid::Datum;
use Statistics::Covid::Datum::IO;
use File::Temp;
use File::Spec;
use File::Basename;

use Test::More;
use Benchmark qw/timethese cmpthese :hireswallclock/;

my $dirname = dirname(__FILE__);

my $large_num_objs_to_insert = 2000;
my $num_repeats = 5;

## nothing to change below...
my $num_tests = 0;
my ($ret, $count, $io, $schema, $da);

print "$0 : benchmarks...\n";

my $tmpdir = './tmp';File::Temp::tempdir(CLEANUP=>1);
my $tmpdbfile = "adb.sqlite";
my $configfile = File::Spec->catfile($dirname, 'example-config.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($configfile);
ok(defined($confighash), "config json file parsed."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = $tmpdir;
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
$confighash->{'dbparams'}->{'dbdir'} = $tmpdir;
$confighash->{'dbparams'}->{'dbname'} = $tmpdbfile;

unlink $tmpdbfile;

$io = Statistics::Covid::Datum::IO->new({
	'config-hash' => $confighash,
	'debug' => 0,
});
ok(defined($io), "Statistics::Covid::Datum::IO->new() called"); $num_tests++;
ok(-d $tmpdir, "output dir exists"); $num_tests++;
$schema = $io->db_connect();
ok(defined($schema), "connect to DB"); $num_tests++;

# insert same but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'only-better';
my $failed = 0;
my $anobj;
my $term = 20;
my $i = 0;
my @objs = ();

# shamelessly ripped off App::Benchmark
cmpthese(timethese($num_repeats, {
	"creating $large_num_objs_to_insert Datum objects in memory" => sub {
	  @objs = ();
	  for (1..$large_num_objs_to_insert){
		$anobj = Statistics::Covid::Datum::make_random_object(); # different seed, different records
		if( ! defined $anobj ){ $failed++ }
		$anobj->name("obj$i");
		push @objs, $anobj;
		$i++;
	  }
	} # end the codeblock to time
}));

is($failed, 0, "created $large_num_objs_to_insert datum objects in memory"); $num_tests++;
cmpthese(timethese($num_repeats, {
	"inserting $large_num_objs_to_insert Datum objects into DB" => sub {
		## now do inserts of unrelated records, all must succeed
		# but we do not check, we only check the count
		$io->db_delete_rows();
		$ret = $io->db_insert_bulk(\@objs);
		ok($ret->{'num-failed'}==0, "num-failed checked"); $num_tests++;
		$count = $io->db_count();
		ok($count==$large_num_objs_to_insert, "total count in db checked ($count)"); $num_tests++;
	} # end codeblock to time
}));

is($io->db_disconnect(), 1, "disconnect from DB"); $num_tests++;

done_testing($num_tests);
