#!/usr/bin/perl -w

use strict;
use lib('../blib/lib');

use Net::ParseWhois;

my $dom = $ARGV[0] || die "usage:\n$0 [dom]\n"; 
my $w = Net::ParseWhois::Domain->new($dom, { debug => 0 });
unless (defined $w) { die "Can't connect to Whois server - $w\n";}

unless ($w->ok) {
	die "No match for $dom\n";
}

if ($w->unknown_registrar) {
	die "domain found, registrar unknown. raw data follows\n" . $w->raw_whois_text . "\n";
}

print "REGISTRARY	== ", $w->registrar, "\n\n";
print "DOMAIN		== ", $w->domain, "\n\n";
print "NAME		== ", $w->name, "\n\n";
print "TAG		== ", $w->tag, "\n\n";
print "ADDRESS		==v\n", map { "    $_\n" } $w->address;
print "\nCOUNTRY		== ", $w->country, "\n\n";
print "NAME SERVERS	==v\n", map { "    $$_[0] ($$_[1])\n" }
  @{$w->servers};
print "\n";
my ($c, $t);
if ($c = $w->contacts) {
  print "CONTACTS	==v\n";
  for $t (sort keys %$c) {
    print "    $t ==\n";
    print map { "\t$_\n" } @{$$c{$t}};
  }
  print "\n";
}

print "RECORD CREATED	== ", $w->record_created,"\n\n";
print "RECORD UPDATED	== ", $w->record_updated,"\n\n";
