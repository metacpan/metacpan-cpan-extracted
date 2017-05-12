use strict;
use warnings;

use Test::More tests => 1;

use RDF::NLP::SPARQLQuery;

my $NLQuestion = RDF::NLP::SPARQLQuery->new();
ok( defined($NLQuestion) && ref $NLQuestion eq 'RDF::NLP::SPARQLQuery',     'new() works' );


