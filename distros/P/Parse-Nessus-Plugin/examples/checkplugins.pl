#
# Parse::Nessus::Plugin example
#
# Author: Roberto Alamos Moreno <ralamosm@cpan.org>
#
# Copyright (c) 2005 Roberto Alamos Moreno. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# May 2005. Antofagasta, Chile.
#
use strict;
use warnings;
use Parse::Nessus::Plugin;

# Check for arguments
if(!@ARGV) {
  print "You didn't write an argument.\nUsage: perl $0 [plugins directory]\n\n";
  exit -1;
}

my $DIR = $ARGV[0];

# Create parser
my $plugin = Parse::Nessus::Plugin->new || undef;
if(!$plugin) {
  print "There were an error. Reason: ".$plugin->error."\n";
  exit -1;
}

# Open directory
if(!opendir(DIR,$DIR)) {
  print "There were an error. Reason: We couldn't open $DIR directory.\n";
  exit -1;
}
# Process all files
while(defined(my $file = readdir(DIR))) {
  if($file eq '.' || $file eq '..') {
    next;
  }
  if(!$plugin->parse_file($DIR."/".$file)) {
    print "There were an error. Reason: $file isn't a .nasl plugin\n";
    next;
  }
  print $plugin->filename,"\n";
  print " ID: ".$plugin->id."\n" if $plugin->id;
  print " NAME: ".$plugin->name."\n" if $plugin->name;
  print " VERSION: ".$plugin->version."\n" if $plugin->version;
  print " FAMILY: ".$plugin->family."\n" if $plugin->family;
  print " CATEGORY: ".$plugin->category."\n" if $plugin->category;
  print " RISK: ".$plugin->risk."\n" if $plugin->risk;
  print " SUMMARY: ".$plugin->summary."\n" if $plugin->summary;
  print " DESCRIPTION: ".$plugin->description."\n" if $plugin->description;
  print " SOLUTION: ".$plugin->solution."\n" if $plugin->solution;
  my $cve = $plugin->cve;
  if($cve) {
    print " CVE:\n";
    foreach my $cve (@{$cve}) {
      print "  $cve\n";
    }
  }
  my $bugtraq = $plugin->bugtraq;
  if($bugtraq) {
    print " BUGTRAQ:\n";
    foreach my $bugtraq (@{$bugtraq}) {
      print "  $bugtraq\n";
    }
  }
  print "\n\n";
}
closedir(DIR);

# Bye
exit 0;
