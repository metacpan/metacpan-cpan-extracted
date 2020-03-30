#!perl -T
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use Statistics::Covid::Utils;
use Test::More;
use File::Basename;
use File::Spec;

my $dirname = dirname(__FILE__);

my $num_tests = 0;

my $config_json_file = File::Spec->catfile($dirname, 'config-for-t.json');
my $confighash = Statistics::Covid::Utils::configfile2perl($config_json_file);
ok(defined($confighash), "config json file parsed."); $num_tests++;

my $config_json_string = <<EOJ;
# comments are allowed, otherwise it is json
# this file does not get eval'ed, it is parsed
# only double quotes! and no excess commas
{
	# fileparams options
	"fileparams" : {
		# dir to store datafiles, each DataProvider class
		# then has its own path to append
		"datafiles-dir" : "datazz/files"
	},
	# database IO options
	"dbparams" : {
		# which DB to use: SQLite, MySQL (case sensitive)
		"dbtype" : "SQLite",
		# the name of DB
		# in the case of SQLite, this is a filepath
		# all non-existing dirs will be created (by module, not by DBI)
		"dbdir" : "datazz/db",
		"dbname" : "covid.sqlite",
		# how to handle duplicates in DB? (duplicate=have same PrimaryKey)
		# only-better : replace records in DB if outdated (meaning number of markers is less, e.g. terminal or confirmed)
		# replace     : force replace irrespective of markers
		# ignore      : if there is a duplicate in DB DONT REPLACE/DONT INSERT
		# (see also Statistics::Covid::Datum for up-to-date info)
		"replace-existing-db-record" : "only-better",
		# options to pass to DBI::connect
		# see https://metacpan.org/pod/DBI for all options
		"dbi-connect-params" : {
			"RaiseError" : 1, # die on error
			"PrintError" : 0  # do not print errors or warnings
		}
	}
}
EOJ

$confighash = Statistics::Covid::Utils::configstring2perl($config_json_string);
ok(defined($confighash), "config json string parsed."); $num_tests++;

done_testing($num_tests);
