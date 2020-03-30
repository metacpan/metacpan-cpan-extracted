#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.23';

use Statistics::Covid;

use Getopt::Long;
use Data::Dump qw/pp/;

my $configfile1 = undef;
my $configfile2 = undef;
my $tablename = 'Datum';
my $DEBUG = 0;
my $conditions = undef;
my $attributes = undef;
my $clear_db_before = 0;
# default values
my %providers = (
	'UK::BBC'=>1,
	'UK::GOVUK'=>1,
	'World::JHU'=>1
);

if( ! Getopt::Long::GetOptions(
	'config-file-source=s' => \$configfile1,
	'config-file-destination=s' => \$configfile2,
	'provider=s' => sub {
		# TODO: add a check for removing providers
		$providers{$_[1]} = 1;
	},
	'conditions=s' => \$conditions,
	'attributes=s' => \$attributes,
	'tablename=s' => \$tablename,
	'clear' => \$clear_db_before,
	'debug=i' => \$DEBUG,
) ){ die usage() . "\n\nerror in command line."; }

die usage() . "\n\nA configuration file (--config-file-source) is required." unless defined $configfile1;

my $ts = time;

my $package = 'Statistics::Covid::'.$tablename.'::IO';
my $packagefile = $package.'.pm'; $packagefile =~ s|\:\:|/|g;
my @providers = sort keys %providers;

eval { require $packagefile; 1; };
die "failed to load packagefile '$packagefile'. Most likely table '$tablename' is unknown or was wrongly capitalised, e.g. the 'Datum' table is correct : $@"
	if $@;

my $db_select_params = {};
if( defined $conditions ){
	my $pvc = eval $conditions;
	die "Syntax errors in the specified conditions '$conditions'"
		unless defined $pvc;
	$db_select_params->{'conditions'} = $pvc;
}
if( defined $attributes ){
	my $pva = eval $attributes;
	die "Syntax errors in the specified attributes '$attributes'"
		unless defined $pva;
	$db_select_params->{'attributes'} = $pva;
}

my $covid = Statistics::Covid->new({
	'config-file' => $configfile1,
	'debug' => $DEBUG,
	'providers' => \@providers,
	'save-to-file' => 0,
	'save-to-db' => 0,
});
die "call to Statistics::Covid->new() has failed (1)."
	unless defined $covid;
# read all data files from all the datadirs of each of our loaded providers
# we get a hashref key=providerstr, value=arrayref of datum objs
my $datumObjs = $covid->read_data_from_files();
die "call to read_data_from_files() has failed."
	unless defined $datumObjs;

if( defined $configfile2 ){
	# we are saving to a different data collection
	$covid = Statistics::Covid->new({
		'config-file' => $configfile2,
		'debug' => $DEBUG,
		'providers' => \@providers,
		'save-to-file' => 0,
		'save-to-db' => 0,
	});
	die "call to Statistics::Covid->new() has failed (2)."
		unless defined $covid;
}
my $count1 = $covid->db_datums_count();
# save to db
# we get back hash of {providerstr=>$datumobjsarrayref}
my ($count2, $count3);
for my $k (@providers){
	$count2 = $covid->db_datums_count();
#	print "$0 : provider '$k' has ".scalar(@{$datumObjs->{$k}})." items from file.\n";
	my $ret = $covid->db_datums_insert_bulk($datumObjs->{$k});
	die "call to db_datums_insert_bulk() has failed."
		unless defined $ret;
	$count3 = $covid->db_datums_count();
	print "$0 : success, destination database for '$k':\n" . pp($ret) . "\n";
	print "$0 : rows in '$tablename' before : $count2\n";
	print "$0 : rows in '$tablename' after  : $count3\n";
}
$count3 = $covid->db_datums_count();
print "$0 : rows in '$tablename' when started : $count1\n";
print "$0 : rows in '$tablename' at the end   : $count3\n";
print "$0 : succes, done in ".(time-$ts)." seconds.\n";
# db disconnects on $covid destruction

#### end

sub usage {
	return "Usage : $0 <options>\n"
	. " --conditions C : specify SELECT conditions as a string representing a Perl hashref adhering to the search-conditions expected by SQL::Abstract. For example, \"{'name' => {'like'=>'%ABC'}}\" See https://metacpan.org/pod/SQL::Abstract#WHERE-CLAUSES\n"
	. " --config-file-src C : specify a configuration file for doing IO with the source database.\n"
	. " --config-file-destination C : specify a configuration file for doing IO with the destination database.\n"
	. " --tablename T : specify the tablename for the SELECT, this corresponds to a package- name : Statistics::Covid::<tablename>::IO, so use the exact same capitalisation (e.g. 'Datum' and not 'datum').\n"
	. "[--clear : erase all contents of the destination database, if any and if it does indeed exist.]"
	. "[--attributes A : specify SELECT attributes as a string representing a Perl hashref adhering to the search-attributes expected by SQL::Abstract. In order to limit the number of rows selected use: '{rows=>10}', see https://metacpan.org/pod/DBIx::Class::ResultSet#ATTRIBUTES]\n"
	. "[--debug Level : specify a debug level, anything >0 is verbose.]\n"
	. "\n\nThis program will open the source database, extract objects from specified table using the specified conditions and then write them onto the same table of the destination database.\n"
	. "\nExample usage:\n"
. <<'EXA'
db-search-and-make-new-db.pl --config-file-source config/config.json --config-file-destination config/destination.json --tablename 'Datum' --conditions "{'name'=>'Hackney'}" --attributes "{'rows'=>3}"
EXA
	. "\nProgram by Andreas Hadjiprocopis (andreashad2\@gmail.com / bliako\@cpan.org)\n"
	;
}

