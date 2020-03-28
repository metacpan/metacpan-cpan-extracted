#!/usr/bin/perl
use 5.006;

use strict;
use warnings;

use lib 'blib/lib';

use Statistics::Covid::Datum::IO;
use Statistics::Covid::Analysis::Plot;
use Test::More;
use File::Basename;
use File::Spec;
use File::Temp;
use File::Path;

my $dirname = dirname(__FILE__);

my $num_tests = 0;

my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
# .data.pl and .data.json will be the 2 files created for this specific data provider
my $tmpbasename = File::Spec->catfile($tmpdir, "afile");
my $configfile = File::Spec->catfile($dirname, 'example-config.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($configfile);
ok(defined($confighash), "config json file parsed."); $num_tests++;

$confighash->{'fileparams'}->{'datafiles-dir'} = $tmpdir;
$confighash->{'dbparams'}->{'dbdir'} = File::Spec->catfile('t', 'data', 'db');
$confighash->{'dbparams'}->{'dbtype'} = 'SQLite';
my $dbfilename = File::Spec->catfile($confighash->{'dbparams'}->{'dbdir'}, $confighash->{'dbparams'}->{'dbname'});
my $io = Statistics::Covid::Datum::IO->new({
	'config-hash' => $confighash,
	'debug' => 0,
});

ok(defined($io), "Statistics::Covid::Datum::IO->new() called"); $num_tests++;
ok($io->db_connect(), "connect to db: '$dbfilename'."); $num_tests++;

my $objs = $io->db_select({
	conditions => {belongsto=>'UK', name=>{'like' => 'Ha%'}}
});
ok(defined($objs)&&(scalar(@$objs)>0), "db_select() called.") || BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir"); $num_tests++;

my $outfile = 'chartclicker.png'; unlink $outfile;
my $ret = Statistics::Covid::Analysis::Plot::plot_with_chartclicker({
	'datum-objs' => $objs,
	'outfile' => $outfile,
	'Y' => 'confirmed',
	'GroupBy' => ['name']
});
ok(defined($ret), "Statistics::Covid::Analysis::Plot::plot_with_chartclicker() called"); $num_tests++;
ok((-f $outfile)&&(-s $outfile), "output image '$outfile'."); $num_tests++;

$outfile = 'gd.png'; unlink $outfile;
$ret = Statistics::Covid::Analysis::Plot::plot_with_gd({
	'datum-objs' => $objs,
	'outfile' => $outfile,
});
ok(defined($ret), "Statistics::Covid::Analysis::Plot::plot_with_gd() called"); $num_tests++;
ok((-f $outfile)&&(-s $outfile), "output image '$outfile'."); $num_tests++;

#Statistics::Covid::Analysis::Plot::testplot(); exit(0);
#my $plot = Statistics::Covid::Analysis::Plot::plot({
#	'datum-objs' => $objs,
#	'outfile' => 'aa.jpg'
#});
#ok(defined($plot), "Statistics::Covid::Analysis::Plot::plot() called"); $num_tests++;

done_testing($num_tests);
