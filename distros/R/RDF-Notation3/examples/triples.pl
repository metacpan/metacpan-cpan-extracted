#!/usr/bin/perl

use strict;

BEGIN { unshift @INC, "../blib/lib", "../blib/arch" }

use RDF::Notation3::Triples;

(@ARGV == 1 ) || die ("Usage: triples.pl <n3_file>\n\n");

my $file = shift;

my $rdf = new RDF::Notation3::Triples;
my $rc  = $rdf->parse_file($file);

# namespaces
foreach my $c (keys %{$rdf->{ns}}) {
    foreach (keys %{$rdf->{ns}->{$c}}) {
	print "NS: $c: $_ -> $rdf->{ns}->{$c}->{$_}\n";
    }
}

# triples
my $string = $rdf->get_triples_as_string;
print $string;

#--------------------------------------------------
print "-" x 30;
print "\n";
print "Triples: $rc\n";

exit 0;
