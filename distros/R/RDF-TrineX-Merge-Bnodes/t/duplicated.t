use strict;
use Test::More;
use RDF::TrineX::Merge::Bnodes;
use RDF::Trine qw(iri statement blank);
use RDF::Trine::Iterator;

sub triple {
    statement( map {
        $_ =~ /^\?(.+)$/ ? blank("b$1") : iri($_)
    } split " ", $_[0] )
}

sub count {
    merge_bnodes( 
        RDF::Trine::Iterator->new( [ map { triple($_) } @_ ], 'graph')
    )->size
}

is count("x:a p:a ?1", "x:a p:a ?2"), 1;
is count("x:a p:a ?1", "x:a p:a ?1"), 1;

done_testing;
