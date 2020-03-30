#!/usr/bin/env perl
use 5.006;

use lib 'blib/lib';

use strict;
use warnings;

our $VERSION = '0.21';

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
ok(defined($confighash), "config json file parsed."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = File::Spec->catfile($tmpdir, 'files');
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
$confighash->{'dbparams'}->{'dbdir'} = File::Spec->catfile($tmpdir, 'db');
$confighash->{'dbparams'}->{'dbname'} = $tmpdbfile;
my $dbfullpath = File::Spec->catfile($confighash->{'dbparams'}->{'dbdir'}, $confighash->{'dbparams'}->{'dbname'});

# WARNING: adding db's here will most likely add dependencies to
# their DBD driver modules! Be careful to add dependencies on Makefile.PL
my %db_types_to_test_against = (
	'SQLite' => 1,
	'MySQL' => 1,
	'PostgreSQL' => 1, # SQL::Translator wants 'PostgreSQL' and not 'Pg'
);

# check support for these databases
for my $adbname (keys %db_types_to_test_against){
	my $packagename = 'DBD::'.$adbname;
	my $packagefile = $packagename.'.pm'; $packagefile =~ s|\:\:|/|g;
	my $rc = eval { require $packagefile; 1 };
	if( ! $rc ){
		# module not found, try lowercase and forget it if that fails
		$adbname = lc $adbname;
		$packagename = 'DBD::'.$adbname;
		$packagefile = $packagename.'.pm'; $packagefile =~ s|\:\:|/|g; 
		$rc = eval { require $packagefile; 1 };
		if( ! $rc ){
			warn "module '$packagename' (for database '$adbname') is not install or can not be loaded, removing this DB from our list.";
			delete $db_types_to_test_against{$adbname};
		}
	}
}
my @dbtypes = sort keys %db_types_to_test_against;
warn "found installed drivers/modules for this databases: ".join(",", @dbtypes);

$io = Statistics::Covid::Datum::IO->new({
	# the params
	'config-hash' => $confighash,
	'debug' => 1,
});
ok(defined($io), "Statistics::Covid::Datum::IO->new() called"); $num_tests++;
ok($io->dbparams()->{'dbdir'} eq $confighash->{'dbparams'}->{'dbdir'}, "db dirs compared for equality: for config (".$confighash->{'dbparams'}->{'dbdir'}.") and object (".$io->dbparams()->{'dbdir'}.")."); $num_tests++;
ok($io->dbparams()->{'dbname'} eq $confighash->{'dbparams'}->{'dbname'}, "db dirs compared for equality: for config (".$confighash->{'dbparams'}->{'dbname'}.") and object (".$io->dbparams()->{'dbname'}.")."); $num_tests++;
ok($io->dbparams()->{'dbtype'} eq $confighash->{'dbparams'}->{'dbtype'}, "db dirs compared for equality: for config (".$confighash->{'dbparams'}->{'dbtype'}.") and object (".$io->dbparams()->{'dbtype'}.")."); $num_tests++;

ok(-d $confighash->{'fileparams'}->{'datafiles-dir'}, "output dir exists (".$confighash->{'fileparams'}->{'datafiles-dir'}.")"); $num_tests++;
ok($io->db_connect(), "db_connect() called"); $num_tests++;
# after connecting to db...
if( $io->dbparams()->{'dbtype'} eq 'SQLite' ){
	# only applies to SQLite , we are looking for db files on disk
	ok(-d $confighash->{'dbparams'}->{'dbdir'}, "db dir exists (".$confighash->{'dbparams'}->{'dbdir'}.")"); $num_tests++;
	ok(-f $dbfullpath, "db file exists (".$dbfullpath.")"); $num_tests++;
	ok(-s $dbfullpath, "db file not empty (".$dbfullpath.")"); $num_tests++;
}
# we can't check if deployed is 0 because we need to connect to db first and that deploys automatically
is($io->is_deployed(), 1, "db is already deployed"); $num_tests++;

my $tablenames = $io->db_get_all_tablenames();
ok(defined($tablenames), "io->db_get_all_tablenames() called"); $num_tests++;
ok(scalar(@$tablenames)>0, "there are tables in the database: ".join(",", @$tablenames)); $num_tests++;

# try to create another to see if deploy

my $io2 = Statistics::Covid::Datum::IO->new({
	# the params
	'config-hash' => $confighash,
	'debug' => 1,
});
ok(defined($io2), "Statistics::Covid::Datum::IO->new() called (2)"); $num_tests++;
ok($io->db_connect(), "db_connect() called"); $num_tests++;
is($io2->is_deployed(), 1, "db is already deployed"); $num_tests++;

# check the schema creator
my $schemadir = File::Spec->catfile($tmpdir, 'schemas');
my $schemafile = File::Spec->catfile($schemadir, 'all123.sql');
my $schemas = $io2->db_get_schema({
	'outdir' => $schemadir,
	'dbtypes' => \@dbtypes,
	'outfile' => $schemafile,
	'debug' => 1,
});
ok(defined($schemas), "db_get_schema() called"); $num_tests++;
ok(ref($schemas) eq 'HASH', "db_get_schema() return type: 'HASH'=".ref($schemas)); $num_tests++; # i just love tests
ok(-d $schemadir, "schema dir created: '$schemadir'."); $num_tests++;
ok(-f $schemafile, "total schema file created: '$schemafile'."); $num_tests++;
ok(-s $schemafile, "total schema file has content: '$schemafile'."); $num_tests++;
for my $adbname (@dbtypes){
	ok(exists $schemas->{$adbname}, "individual schema for '$adbname' in returned hash."); $num_tests++;
	my $aschemafile = File::Spec->catdir(
		$schemadir,
		'Statistics-Covid-Schema-'.$Statistics::Covid::Datum::IO::VERSION.'-'.$adbname.'.sql'
	);
	ok(-f $aschemafile, "individual schema file for '$adbname' created: '$aschemafile'."); $num_tests++;
	ok(-s $aschemafile, "individual schema file for '$adbname' has content: '$aschemafile'."); $num_tests++;
}

is($io->db_disconnect(), 1, "disconnect from DB"); $num_tests++;

done_testing($num_tests);
