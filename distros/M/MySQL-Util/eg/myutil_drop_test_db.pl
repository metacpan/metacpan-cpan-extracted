#!/usr/bin/perl

use Modern::Perl;

use lib qw(. .. ../t);

require 'testlib.pl';

########################

my ($host, $dbname) = drop_db();
print "dropped $dbname on $host\n";

##################################
