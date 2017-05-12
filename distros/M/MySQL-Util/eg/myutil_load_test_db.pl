#!/usr/bin/perl

use Modern::Perl;

use lib qw(. .. ../t);

require 'testlib.pl';

########################

my ($host, $dbname) = load_db();
print "loaded $dbname on $host\n";

##################################
