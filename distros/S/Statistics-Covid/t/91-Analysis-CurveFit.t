#!/usr/bin/perl
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use lib 'blib/lib';

use Statistics::Covid;
use Statistics::Covid::Datum::IO;
use Statistics::Covid::Analysis::Model::Simple;
use Math::Symbolic;
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

# now retrieve some real data
my $covid = Statistics::Covid->new({
	'config-hash' => $confighash,
	'debug' => 0,
});
ok(defined($covid), "Statistics::Covid->new() called"); $num_tests++;

# this selects the place(s) and also sorts wrt time
my $objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
#	{'like' => 'Ha%'}, # the location (wildcard)
	['Halton', 'Havering'],
#	{'like' => 'Halton'}, # the location (wildcard)
#	{'like' => 'Havering'}, # the location (wildcard)
	'UK', # the belongsto (could have been wildcarded)
);
ok(defined($objs), "db_select() called.") or BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir ($dbfullpath)"); $num_tests++;
ok(scalar(@$objs)>0, "db_select() returned objects.") or BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir ($dbfullpath)"); $num_tests++;

my $df = Statistics::Covid::Utils::datums2dataframe({
	'datum-objs' => $objs,
	'groupby' => ['name'],
	'content' => ['confirmed', 'datetimeUnixEpoch'],
});
ok(defined($df), "Statistics::Covid::Utils::datums2dataframe() called"); $num_tests++;

#print pp($df);

my @groupby_keys = sort keys %$df;
ok(scalar(@groupby_keys)>0, "dataframe has keys: '".join("','", @groupby_keys)."'."); $num_tests++;

# change all unix-epoch seconds of the x-axis to hours starting from zero (i.e. subtract the
# first element from all). Assumes that dataobjs are sorted wrt time of 'datetimeUnixEpoch' column

Statistics::Covid::Utils::discretise_increasing_sequence_of_seconds(
	$df->{$_}->{'datetimeUnixEpoch'},
	3600, # convert seconds to hours but the oldest timepoint will be at t=0
	0 # offset (i.e. the oldest time will be hour 0
) for @groupby_keys;

# fit this data!

my ($formula, $ret);
$Statistics::Covid::Analysis::Model::Simple::DEBUG=1;

# do an exponential fit
$ret = Statistics::Covid::Analysis::Model::Simple::fit({
	'dataframe' => $df,
	'X' => 'datetimeUnixEpoch',
	'Y' => 'confirmed',
	'initial-guess' => {a=>1, b=>1},
	'exponential-fit' => 1,
	'fit-params' => {
		'maximum_iterations' => 100000
	}
});
ok(defined($ret), "Statistics::Covid::Analysis::Model::Simple::fit() called"); $num_tests++;

# polynomial fit works great!
$ret = Statistics::Covid::Analysis::Model::Simple::fit({
	'dataframe' => $df,
	'X' => 'datetimeUnixEpoch',
	'Y' => 'confirmed',
	'initial-guess' => {a=>1, b=>1},
	'polynomial-fit' => 5,
	'fit-params' => {
		'maximum_iterations' => 100000
	}
});
ok(defined($ret), "Statistics::Covid::Analysis::Model::Simple::fit() called"); $num_tests++;

# adhoc formula (see L<Math::Symbolic::Operator> for supported operators)
# this exponential fails miserably: a+b*exp(c*x+d)
# because of Inf in the matrices.
#$formula = 'a+b*exp(c*x+d)';
#$formula = 'a + b*exp(x) + c*exp(-x)';
#$formula = 'a1 + a2*x + a3*x^2';
#$formula = 'a1 + a2*x';
$formula = 'c1*sin(x) + c2*cos(x)';
$ret = Statistics::Covid::Analysis::Model::Simple::fit({
	'dataframe' => $df,
	'X' => 'datetimeUnixEpoch',
	'Y' => 'confirmed',
	'formula' => $formula,
	'initial-guess' => {a=>1, b=>1},
	'fit-params' => {
		'maximum_iterations' => 100000
	}
});
ok(defined($ret), "Statistics::Covid::Analysis::Model::Simple::fit() called"); $num_tests++;
#print pp($df);

done_testing($num_tests);
