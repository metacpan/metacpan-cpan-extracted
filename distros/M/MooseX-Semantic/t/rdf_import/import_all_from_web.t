use Test::More tests => 4;
use common::sense;
use Data::Dumper;
use MooseX::Semantic::Test::StrictPerson;

my $uris = [
    # 'http://tobyinkster.co.uk/#i',        # won't parse...
    'http://kasei.us/about/foaf.xrdf',
    'https://raw.github.com/mhausenblas/schema-org-rdf/master/examples/Thing/Person/Person.rdfa',
];

SKIP: {
    skip "Won't do internet tests unless \$MOOSEX_SEMANTIC_NET is set", 4 unless $ENV{MOOSEX_SEMANTIC_NET}; 
    {
        my @people = MooseX::Semantic::Test::StrictPerson->import_all_from_web( $uris, skip_blank => 0 );
        is (scalar @people, 19, '19 nodes (import_all_from_web)');
    }
    {
        my @people = MooseX::Semantic::Test::StrictPerson->import_all_from_web( $uris, skip_blank => 1 );
        is (scalar @people, 2, '2 non-blank nodes (import_all_from_web)');
    }
    {
        my @people = MooseX::Semantic::Test::StrictPerson->import_all( uris => $uris, skip_blank => 1 );
        is (scalar @people, 2, '2 non-blank nodes (import_all uris)');
    }
    {
        my @people = MooseX::Semantic::Test::StrictPerson->import_all( uri => $uris, skip_blank => 1 );
        is (scalar @people, 2, '2 non-blank nodes (import_all uri)');
    }
}
