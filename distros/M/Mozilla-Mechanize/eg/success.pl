#!/usr/bin/perl
use strict;
use warnings;

use Cwd 'getcwd';

use lib '../lib';
use Mozilla::Mechanize;

$|++;

my $moz = Mozilla::Mechanize->new(visible => 0);

# a successful get
my $cwd = getcwd();
print "getting index.html\n";
$moz->get("file://$cwd/index.html");
print "got uri=", $moz->uri, $/;

# an unsuccessful get
print "getting dne.html\n";
$moz->get("file//$cwd/dne.html");
print "got uri=", $moz->uri, $/;
