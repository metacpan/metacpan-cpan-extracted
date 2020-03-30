#!perl -T
use 5.006;

use strict;
use warnings;

our $VERSION = '0.21';

use Statistics::Covid::Datum::IO;
use DBI;
use File::Temp;
use File::Spec;
use File::Basename;

my $dirname = dirname(__FILE__);

use Test::More;

my $num_tests = 0;

# this is not a test file but a script to check
# installed DBD drivers on the CPAN testers
my %db_types_to_test_against = (
	'SQLite' => 1,
	'MySQL' => 1,
	# DBD:: accepts both of these for PostgreSQL
	'PostgreSQL' => 1, # SQL::Translator wants 'PostgreSQL' and not 'Pg'
	'Pg' => 1, # DBD::Pg is the name of the module
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
ok(exists $db_types_to_test_against{'SQLite'}, "support for SQLite"); $num_tests++;

done_testing($num_tests);
