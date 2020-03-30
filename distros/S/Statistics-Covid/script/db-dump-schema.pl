#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.23';

use Statistics::Covid;

use Getopt::Long;
use Data::Dump qw/pp/;

my $configfile = undef;
my $outdir = undef;
my $outfile = undef;
my $DEBUG = 0;
my %DBs = (
	'SQLite'=>1,
	'MySQL'=>1,
);

my %params;
if( ! Getopt::Long::GetOptions(
	'config-file=s' => \$configfile,
	'outdir=s' => sub { $params{'outdir'} = $_[1] },
	'outfile=s' => sub { $params{'outfile'} = $_[1] },
	'db=s' => sub {
		# TODO: add a check for removing providers
		$DBs{$_[1]} = 1;
	},
	'debug=i' => \$DEBUG,
) ){ die usage() . "\n\nerror in command line."; }

die usage() . "\n\nA configuration file (--config-file) is required." unless defined $configfile;
my $ts = time;

$params{'dbtypes'} = [sort keys %DBs];

my $atablename = 'Datum'; # this has no effect to the output, it's to just connect to db
my $package = 'Statistics::Covid::'.$atablename.'::IO';
my $packagefile = $package.'.pm'; $packagefile =~ s|\:\:|/|g;

eval { require $packagefile; 1; };
die "failed to load packagefile '$packagefile'. Most likely table '$atablename' is unknown or was wrongly capitalised, e.g. the 'Datum' table is correct : $@"
	if $@;

my $io = $package->new({
	'config-file' => $configfile,
	'debug' => $DEBUG,
}) or die $package."->new() failed for table '$atablename'.";
die "failed to connect to source database using config-file '$configfile', for table '$atablename'."
	unless $io->db_connect();

my $ret = $io->db_get_schema(\%params);
die "call to db_get_schema() has failed."
	unless defined $ret;

print "$0 : success, done in ".(time-$ts)." seconds.\n";

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

