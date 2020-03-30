#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.23';

use Getopt::Long;

use Data::Dump qw/pp/;

my $configfile1 = undef;
my $configfile2 = undef;
my $tablename = undef;
my $DEBUG = 0;
my $conditions = undef;
my $attributes = undef;
my $clear_db_before = 0;

if( ! Getopt::Long::GetOptions(
	'config-file-source=s' => \$configfile1,
	'config-file-destination=s' => \$configfile2,
	'conditions=s' => \$conditions,
	'attributes=s' => \$attributes,
	'tablename=s' => \$tablename,
	'clear' => \$clear_db_before,
	'debug=i' => \$DEBUG,
) ){ die usage() . "\n\nerror in command line."; }

die usage() . "\n\nA 'source' configuration file (--config-file-src) is required." unless defined $configfile1;
die usage() . "\n\nA 'destination' configuration file (--config-file-destination) is required." unless defined $configfile2;

my $package = 'Statistics::Covid::'.$tablename.'::IO';
my $packagefile = $package.'.pm'; $packagefile =~ s|\:\:|/|g;

eval { require $packagefile; 1; };
die "failed to load packagefile '$packagefile'. Most likely table '$tablename' is unknown or was wrongly capitalised, e.g. the 'Datum' table is correct : $@"
	if $@;

my $io1 = $package->new({
	'config-file' => $configfile1,
	'debug' => $DEBUG,
}) or die $package."->new() failed (1)";
die "failed to connect to source database using config-file '$configfile1'"
	unless $io1->db_connect();

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
my $objs = $io1->db_select($db_select_params);
die pp($db_select_params)."\n\ncall to db_select() has failed for the above parameters"
	unless defined $objs;
die pp($db_select_params)."\n\nnothing was selected for the above parameters"
	if scalar(@$objs)==0;

die "db_disconnect() failed for source db"
	unless $io1->db_disconnect();
my $io2 = $package->new({
	'config-file' => $configfile2,
	'debug' => $DEBUG,
}) or die $package."->new() failed (2)";

die "failed to connect to destination database using config-file '$configfile2'"
	unless $io2->db_connect();

my $count1 = $io2->db_count();

if( $clear_db_before == 1 ){
	die "call to db_clear() failed" unless $io2->db_clear()>=0;
}

my $ret = $io2->db_insert_bulk($objs);
die "db_insert_bulk() failed" unless defined $ret;

my $count2 = $io2->db_count();

print "$0 : success, destination database updated (table '$tablename'):\n" . pp($ret) . "\n";
print "$0 : rows in '$tablename' before : $count1\n";
print "$0 : rows in '$tablename' after  : $count2\n";

die "db_disconnect() failed for destination db"
	unless $io2->db_disconnect();

#### end

sub usage {
	return "Usage : $0 <options>\n"
	. " --config-file-src C : specify a configuration file for doing IO with the source database.\n"
	. " --config-file-destination C : specify a configuration file for doing IO with the destination database.\n"
	. " --tablename T : specify the tablename for the SELECT, this corresponds to a package- name : Statistics::Covid::<tablename>::IO, so use the exact same capitalisation (e.g. 'Datum' and not 'datum').\n"
	. "[--clear : erase all contents of the destination database, if any and if it does indeed exist.]"
	. "[--conditions C : specify SELECT conditions as a string representing a Perl hashref adhering to the search-conditions expected by SQL::Abstract. For example, \"{'name' => {'like'=>'%ABC'}}\" See https://metacpan.org/pod/SQL::Abstract#WHERE-CLAUSES ]\n"
	. "[--attributes A : specify SELECT attributes as a string representing a Perl hashref adhering to the search-attributes expected by SQL::Abstract. In order to limit the number of rows selected use: '{rows=>10}', see https://metacpan.org/pod/DBIx::Class::ResultSet#ATTRIBUTES]\n"
	. "[--debug Level : specify a debug level, anything >0 is verbose.]\n"
	. "\n\nThis program will open the source database, extract objects from specified table using the optionally specified conditions and/or attributes and write them onto the same table into the destination database.\n"
	. "\nExample usage:\n"
. <<'EXA'
db-search-and-make-new-db.pl --config-file-source config/config.json --config-file-destination config/destination.json --tablename 'Datum' --conditions "{'name'=>'Hackney'}" --attributes "{'rows'=>3}"
EXA
	. "\nProgram by Andreas Hadjiprocopis (andreashad2\@gmail.com / bliako\@cpan.org)\n"
	;
}
