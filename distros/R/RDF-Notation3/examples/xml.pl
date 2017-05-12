#!/usr/bin/perl

use strict;

BEGIN { unshift @INC, "../blib/lib", "../blib/arch" }

use RDF::Notation3::XML;

(@ARGV == 1 ) || die ("Usage: xml.pl <n3_file>\n\n");

my $file = shift;

my $rdf = new RDF::Notation3::XML;
my $rc  = $rdf->parse_file($file);

my $string = $rdf->get_string;
print $string;

#--------------------------------------------------
print "-" x 30;
print "\n";
print "Triples: $rc\n";

exit 0;
