#!/usr/bin/perl

use strict;
use RDF::vCard;
use Data::Dumper;

my $vc = <<VCARD;
begin:vcard
fn:Test vCard
note;lang=en-gb:This is just a test.
end:vcard
VCARD

my $i = RDF::vCard::Importer->new;
my @cards = $i->import_string($vc, lang=>'en');

print Dumper(@cards);
