#!/usr/bin/perl

# Allow people debugging to walk down into the generation code
BEGIN {
	$DB::single = 1;
}

# Create an ORM model on the CPANTS database.
# Mirror the data and generate the classes.
use ORLite::Mirror {
	url           => 'http://cpants.perl.org/static/cpants_all.db.gz',
	package       => 'CPANTS',
	show_progress => 1,
	env_proxy     => 1,
};

# Run some queries on the data

my $count = CPANTS::Author->count;
print "CPANTS currently tracks $count authors\n";

my $authors = CPANTS::Author->select('where pauseid = ?', 'ADAMK');
print "ADAMK is " . $authors->[0]->name . "\n";
