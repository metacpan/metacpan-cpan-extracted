#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.21';

use Statistics::Covid;
use Statistics::Covid::Datum;
use Statistics::Covid::Datum::IO;
use File::Temp;
use File::Spec;
use File::Basename;

use Data::Dump qw/pp/;

my $dirname = dirname(__FILE__);

use Test::More;

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

my ($da);

my @das;
my $N = 3; my $M = 10;
for my $i (1..$N){ for my $j (1..$M){
	$da = Statistics::Covid::Datum::make_random_object(123);
	ok(defined $da, "created Datum"); $num_tests++;
	$da->name($i);
	$da->belongsto(10*$i-1);
	$da->confirmed(($i)*(10*$j-1));
	$da->unconfirmed(10*(($i)*(10*$j-1)));
	push @das, $da
} }

my $df;

$df = Statistics::Covid::Utils::datums2dataframe({
	'datum-objs' => \@das,
	'groupby' => ['name', 'belongsto'],
	'content' => ['confirmed', 'unconfirmed']
});
ok(defined $df, "Statistics::Covid::Utils::datums2dataframe() called"); $num_tests++;

my (%counts, $v);
for my $i (1..$N){
	my $k = $i.'|'.(10*$i-1);
	ok(exists $df->{$k}, "key $k exists"); $num_tests++;
	ok(exists $df->{$k}->{'confirmed'}, "key confirmed exists for $k"); $num_tests++;
	ok(exists $df->{$k}->{'unconfirmed'}, "key unconfirmed exists for $k"); $num_tests++;
	for my $j (1..$M){
		$v = ($i)*(10*$j-1);
		ok($df->{$k}->{'confirmed'}->[$j-1]==$v, "key confirmed ($k) for j=$j has value $v == ".$df->{$k}->{'confirmed'}->[$j-1]); $num_tests++;
		$v = 10*(($i)*(10*$j-1));
		ok($df->{$k}->{'unconfirmed'}->[$j-1]==$v, "key unconfirmed ($k) for j=$j has value $v == ".$df->{$k}->{'confirmed'}->[$j-1]); $num_tests++;
	}
}

# now retrieve some real data
my $covid = Statistics::Covid->new({
	'config-hash' => $confighash,
	'debug' => 0,
});
ok(defined($covid), "Statistics::Covid->new() called"); $num_tests++;

my $objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
	{'like' => 'Ha%'}, # the location (wildcard)
	'UK', # the belongsto (could have been wildcarded)
);
ok(defined($objs), "db_select() called.") or BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir ($dbfullpath)"); $num_tests++;
ok(scalar(@$objs)>0, "db_select() returned objects.") or BAIL_OUT("can not continue, something wrong with the test db which should have been present in t dir ($dbfullpath)"); $num_tests++;

$df = Statistics::Covid::Utils::datums2dataframe({
	'datum-objs' => $objs,
	'groupby' => ['name'],
	'content' => ['confirmed', 'datetimeUnixEpoch'],
});
ok(defined($df), "Statistics::Covid::Utils::datums2dataframe() called"); $num_tests++;

my @groupby_keys = sort keys %$df;
ok(scalar(@groupby_keys)>0, "dataframe has keys: '".join("','", @groupby_keys)."'."); $num_tests++;

# change all unix-epoch seconds of the x-axis to hours starting from zero (i.e. subtract the
# first element from all). Assumes that dataobjs are sorted wrt time of 'datetimeUnixEpoch' column
for (@groupby_keys){
	my $dat = $df->{$_}->{'datetimeUnixEpoch'};
	my @acopy = (@$dat);
	Statistics::Covid::Utils::discretise_increasing_sequence_of_seconds($dat, 3600);
	ok($dat->[0]==0, "first element is ".$dat->[0]." and not ".$acopy[0]); $num_tests++;
}

done_testing($num_tests);
