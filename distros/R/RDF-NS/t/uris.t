use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
        require RDF::NS::URIS;
        require URI;
        1;
    } or do {
        plan skip_all => "URI missing - skip tests of RDF::NS::URI";
    }
}

my $NS = RDF::NS::URIS->new('20120829');

my $foaf = 'http://xmlns.com/foaf/0.1/';
my $person = $foaf."Person";

is $NS->foaf,               URI->new($foaf);
is $NS->foaf_Person,        URI->new($person);
is $NS->URI('foaf:Person'), URI->new($person);
is $NS->foaf_Person->as_string, $person;

done_testing;
