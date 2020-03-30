#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.21';

use Statistics::Covid::Datum;
use Statistics::Covid::Datum::IO;
use File::Temp;
use File::Spec;
use File::Basename;

my $dirname = dirname(__FILE__);

use Test::More;

my $num_tests = 0;

my ($ret, $count, $io, $schema, $da);

my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
ok(-d $tmpdir, "output dir exists"); $num_tests++;
my $tmpdbfile = "adb.sqlite";
my $configfile = File::Spec->catfile($dirname, 'config-for-t.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($configfile);
ok(defined($confighash), "config json file parsed.") or BAIL_OUT("can not continue."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = File::Spec->catfile($tmpdir, 'files');
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
$confighash->{'dbparams'}->{'dbdir'} = File::Spec->catfile($tmpdir, 'db');
$confighash->{'dbparams'}->{'dbname'} = $tmpdbfile;
my $dbfullpath = File::Spec->catfile($confighash->{'dbparams'}->{'dbdir'}, $confighash->{'dbparams'}->{'dbname'});

$io = Statistics::Covid::Datum::IO->new({
	# the params
	'config-hash' => $confighash,
	'debug' => 0,
});
ok(defined($io), "Statistics::Covid::Datum::IO->new() called"); $num_tests++;
ok(-d $tmpdir, "output dir exists"); $num_tests++;

$da = Statistics::Covid::Datum::make_random_object(123);
ok(defined $da, "created Datum"); $num_tests++;
$da->debug(1);
$da->date('2020-03-21T22:47:56Z'); # fix the date so that we have duplicates in DB
$da->terminal(1000); # because we subtract a lot below
$schema = $io->db_connect();
ok(defined($schema), "connect to DB"); $num_tests++;

$count = $io->db_count();
if( $count > 0 ){
	$ret=$io->db_delete_rows();
	ok($ret>0, "erased all table rows"); $num_tests++;
	ok(0==$io->db_count(), "no rows in table exist"); $num_tests++;
}

$ret = $io->db_insert($da);
ok($ret==1, "Datum object inserted, 1st time, ret=".$ret); $num_tests++;
$ret = $io->db_insert($da);
ok($ret==3, "Datum object not inserted, 2nd time - identical, ret=".$ret); $num_tests++;
$da->terminal($da->terminal()+1);
$ret = $io->db_insert($da);
ok($ret==2, "Datum object inserted, 3rd time - better markers now"); $num_tests++;
$da->terminal($da->terminal()-2);
$ret = $io->db_insert($da);
ok($ret==3, "Datum object inserted, 4th time - worst markers now"); $num_tests++;
$da->terminal($da->terminal()+3);
$ret = $io->db_insert($da);
ok($ret==2, "Datum object inserted, 5th time - better markers now"); $num_tests++;
# insert same but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'replace';
$ret = $io->db_insert($da);
ok($ret==2, "Datum object inserted, 6th time - identical but forced"); $num_tests++;
# insert worst but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'replace';
$da->terminal($da->terminal()-2);
$ret = $io->db_insert($da);
ok($ret==2, "Datum object inserted, 7th time - worst but forced"); $num_tests++;
# insert worst but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'ignore';
$ret = $io->db_insert($da);
ok($ret==4, "Datum object inserted, 8th time - identical but ignore"); $num_tests++;

### selects
my $results = $io->db_select({
	'conditions' => {
		'terminal' => {'>' => 0}
	}
});
ok(defined($results) && (scalar(@$results)>0), "db_select() called."); $num_tests++;

$results = $io->db_select({
	'conditions' => {
		'terminal' => {'<' => 0}
	}
});
ok(defined($results) && (scalar(@$results)==0), "db_select() called."); $num_tests++;

ok($io->db_delete_rows()>0, "erased all data from table"); $num_tests++;

# insert same but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'only-better';
my $num_objs_to_insert = 10;
my $failed = 0;
my $term = 10;
my $i = 0;
my @objs = ();
for (1..$num_objs_to_insert){
	my $anobj = Statistics::Covid::Datum::make_random_object(123);
	if( ! defined $anobj ){ $failed++ }
	if( $i > 5 ){
		# the first 5 objs will be duplicates
		$anobj->terminal($term++);
	} else {
		# only 1 of those must be inserted (first)
		$anobj->terminal(0);
	}
	push @objs, $anobj;
	$i++;
}
is($failed, 0, "created $num_objs_to_insert datum objects in memory"); $num_tests++;
$ret = $io->db_insert_bulk(\@objs);
ok($ret->{'num-failed'}==0, "num-failed checked"); $num_tests++;
ok($ret->{'num-replaced'}==4, "num-replaced checked"); $num_tests++;
ok($ret->{'num-not-replaced-because-ignore-was-set'}==0, "num-not-replaced-because-ignore-was-set checked"); $num_tests++;
ok($ret->{'num-total-records'}==10, "num-total-records checked"); $num_tests++;
ok($ret->{'num-not-replaced-because-better-exists'}==5, "num-not-replaced-because-better-exists checked"); $num_tests++;
ok($ret->{'num-virgin'}==1, "num-virgin checked"); $num_tests++;
$count = $io->db_count();
ok($count==1, "total count in db checked ($count)"); $num_tests++;

## now do inserts of unrelated records, all must succeed
ok($io->db_delete_rows()>0, "erased all data from table"); $num_tests++;

# insert same but modify the replacement strategy to force
$io->dbparams()->{'replace-existing-db-record'} = 'only-better';
$num_objs_to_insert = 10;
$failed = 0;
$term = 20;
$i = 0;
@objs = ();
for (1..$num_objs_to_insert){
	my $anobj = Statistics::Covid::Datum::make_random_object(); # different seed, different records
	if( ! defined $anobj ){ $failed++ }
	$anobj->name("obj$i");
	push @objs, $anobj;
	$i++;
}
is($failed, 0, "created $num_objs_to_insert datum objects in memory"); $num_tests++;
$ret = $io->db_insert_bulk(\@objs);
ok($ret->{'num-failed'}==0, "num-failed checked"); $num_tests++;
ok($ret->{'num-replaced'}==0, "num-replaced checked"); $num_tests++;
ok($ret->{'num-not-replaced-because-ignore-was-set'}==0, "num-not-replaced-because-ignore-was-set checked"); $num_tests++;
ok($ret->{'num-total-records'}==$num_objs_to_insert, "num-total-records checked"); $num_tests++;
ok($ret->{'num-not-replaced-because-better-exists'}==0, "num-not-replaced-because-better-exists checked"); $num_tests++;
ok($ret->{'num-virgin'}==$num_objs_to_insert, "num-virgin checked"); $num_tests++;
$count = $io->db_count();
ok($count==$num_objs_to_insert, "total count in db checked ($count)"); $num_tests++;


is($io->db_disconnect(), 1, "disconnect from DB"); $num_tests++;

done_testing($num_tests);
