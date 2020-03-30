#!/usr/bin/perl
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use lib 'blib/lib';

use Statistics::Covid::Datum::IO;
use Statistics::Covid::Analysis::Plot::Simple;
use Test::More;
use File::Basename;
use File::Spec;
use File::Temp;
use File::Path;

use Data::Dump qw/pp/;

my $dirname = dirname(__FILE__);

my $num_tests = 0;

my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
ok(-d $tmpdir, "output dir exists"); $num_tests++;
my $tmpdbfile = "adb.sqlite";
my $configfile = File::Spec->catfile($dirname, 'config-for-t.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($configfile);
ok(defined($confighash), "config json file parsed."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = File::Spec->catfile($tmpdir, 'files');
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
#$confighash->{'dbparams'}->{'dbdir'} = File::Spec->catfile($tmpdir, 'db');
#$confighash->{'dbparams'}->{'dbname'} = $tmpdbfile;
my $dbfullpath = File::Spec->catfile($confighash->{'dbparams'}->{'dbdir'}, $confighash->{'dbparams'}->{'dbname'});

ok(-f $dbfullpath, "found test db"); $num_tests++;

my $io = Statistics::Covid::Datum::IO->new({
	'config-hash' => $confighash,
	'debug' => 0,
});

ok(defined($io), "Statistics::Covid::Datum::IO->new() called"); $num_tests++;
ok($io->db_connect(), "connect to db: '$dbfullpath'."); $num_tests++;

my $objs = $io->db_select({
	conditions => {belongsto=>'UK', name=>{'like' => 'Ha%'}}
});
ok(defined($objs), "db_select() called.") || BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir"); $num_tests++;
ok(scalar(@$objs)>0, "db_select() returned objects.") || BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir"); $num_tests++;

my $df = Statistics::Covid::Utils::datums2dataframe({
	'datum-objs' => $objs,
	'groupby' => ['name','belongsto'],
	'content' => ['confirmed','unconfirmed','datetimeUnixEpoch'],
});
ok(defined($df), "Statistics::Covid::Utils::datums2dataframe() called."); $num_tests++;

my $outfile = 'chartclicker.png'; unlink $outfile;

my $ret;

# fail because no correct formatter-x
$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
	'dataframe' => $df,
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'date-format-x' => 123,
	'GroupBy' => ['name']
});
ok(!defined($ret), "Statistics::Covid::Analysis::Plot::Simple::plot() called"); $num_tests++;
# fail because no dataframe or datum-objs
$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'date-format-x' => {
		format => '%d/%m',
		position => 'bottom',
		orientation => 'horizontal'
	},
	'GroupBy' => ['name']
});
ok(!defined($ret), "Statistics::Covid::Analysis::Plot::Simple::plot() called"); $num_tests++;

# call with dataframe instead
$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
	'dataframe' => $df,
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'date-format-x' => {
		format => '%d/%m',
		position => 'bottom',
		orientation => 'horizontal'
	},
});
ok(defined($ret), "Statistics::Covid::Analysis::Plot::Simple::plot() called with dataframe"); $num_tests++;
ok((-f $outfile)&&(-s $outfile), "output image '$outfile'."); $num_tests++;
unlink $outfile;

# success, call with datum-objs
$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
	'datum-objs' => $objs,
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'X' => 'datetimeUnixEpoch',
	'date-format-x' => {
		format => '%d/%m',
		position => 'bottom',
		orientation => 'horizontal'
	},
	'GroupBy' => ['name']
});
ok(defined($ret), "Statistics::Covid::Analysis::Plot::Simple::plot() called with datum-objs"); $num_tests++;
ok((-f $outfile)&&(-s $outfile), "output image '$outfile'."); $num_tests++;
unlink $outfile;

# call with dataframe, X is not time
$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
	'dataframe' => $df,
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'X' => 'unconfirmed',
});
ok(defined($ret), "Statistics::Covid::Analysis::Plot::Simple::plot() called with dataframe"); $num_tests++;
ok((-f $outfile)&&(-s $outfile), "output image '$outfile'."); $num_tests++;
unlink $outfile;

done_testing($num_tests);
