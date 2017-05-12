#!/usr/bin/perl

use strict;

BEGIN { unshift @INC, "../blib/lib", "../blib/arch" }

use RDF::Notation3::SAX;
use MyHandler;
use MyErrorHandler;

(@ARGV == 1 ) || die ("Usage: sax.pl <n3_file>\n\n");

my $path = shift;

my $handler = new MyHandler;
my $ehandler = new MyErrorHandler;
my $rdf = new RDF::Notation3::SAX(Handler => $handler, 
				  ErrorHandler => $ehandler);
my $rc  = $rdf->parse_file($path);

#--------------------------------------------------
print "-" x 30;
print "\n";
print "RC: $rc\n";
print "Triples: $rdf->{count}\n";

exit 0;
