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
  print "You didn't write an argument.\nUsage: perl $0 [/path/to/plugin.nasl]\n\n";
  exit -1;
}

my $FILE = $ARGV[0];

# Create parser
my $plugin = Parse::Nessus::Plugin->new || undef;
if(!$plugin) {
  print "There were an error. Reason: ".$plugin->error."\n";
  exit -1;
}

if(!$plugin->parse_file($FILE)) {
  print "There were an error. Reason: $FILE isn't a .nasl plugin\n";
  exit -1;
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
print " SOLUTION: ".protect($plugin->solution)."\n" if $plugin->solution;

my $is_fs = 'No';
if($plugin->register_service) {
  my $protofs = $plugin->register_service_proto;
  $is_fs = 'Yes. Service: '.$protofs."\n";
}
print " IS FS: ".$is_fs."\n";

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

# Bye
exit 0;

sub protect {
  my $msg = shift;
  return undef unless $msg;

  $msg =~ s/\'/\\\'/go if $msg =~ /[^\\]\'/;
  $msg =~ s/\"/\\\"/go if $msg =~ /[^\\]\"/;
  $msg =~ s/\(/\\\(/go if $msg =~ /[^\\]\(/;
  $msg =~ s/\)/\\\)/go if $msg =~ /[^\\]\)/;
  $msg =~ s/\//\\\//go if $msg =~ /[^\\]\//;
  #$msg =~ s/\:/\\\:/go;
  #$msg =~ s/\=/\\\=/go;
  #$msg =~ s/\?/\\\?/go;
  #$msg =~ s/\\/\\\\/go;

  return nltobr(NtoA($msg));
}

sub nltobr {
  my $msg = shift;
  return undef unless $msg;

  $msg =~ s/\n/\<br\>/go;
  return $msg;
}

sub NtoA {
  my $msg = shift;
  return undef unless $msg;

  $msg =~ s/nessus\.org/confianze\.com/go;
  $msg =~ s/example\.com/confianze\.com/go;
  $msg =~ s/nessus/analyze/go;
  $msg =~ s/Nessus/Analyze/go;

  return $msg;
}

