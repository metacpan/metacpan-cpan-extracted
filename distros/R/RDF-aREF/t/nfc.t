use strict;
use warnings;
use Test::More;
use RDF::aREF;

my $rdf = "t/nfc.ttl";
my $aref = encode_aref $rdf, NFC => 1; 
is $aref->{foaf_given}, $aref->{foaf_surname}, "Unicode Normalization NFC";

$aref = encode_aref $rdf; 
isnt $aref->{foaf_given}, $aref->{foaf_surname}, "Unicode Normalization NFC";

done_testing;
