use Test::More tests=>76;
use RDF::TrineX::RuleEngine::Jena;
use Data::Dumper;
use RDF::Trine qw(statement iri);

# my $input = \ q{<urn:test/resA> <urn:test/propA> <urn:test/resB> .};
my $serializer = RDF::Trine::Serializer->new('ntriples');
my $r = RDF::TrineX::RuleEngine::Jena->new;

sub empty_model_predefined_ruleset {
    my $input = \ q{};
    my %expect = (
        'daml-micro'             => { additions => 0, schemas_purged => 0, size => 48,  },
        'owl-fb'                 => { additions => 0, schemas_purged => 0, size => 644, },
        'owl-fb-micro'           => { additions => 0, schemas_purged => 0, size => 368, },
        'owl-fb-mini'            => { additions => 0, schemas_purged => 0, size => 644, },
        'owl-fb-old'             => { additions => 0, schemas_purged => 0, size => 121, },
        'rdfs'                   => { additions => 0, schemas_purged => 0, size => 119, },
        'rdfs-b'                 => { additions => 0, schemas_purged => 0, size => 119, },
        'rdfs-b-tuned'           => { additions => 0, schemas_purged => 0, size => 119, },
        'rdfs-fb'                => { additions => 0, schemas_purged => 0, size => 98,  },
        'rdfs-fb-lp-expt'        => { additions => 0, schemas_purged => 0, size => 98,  },
        'rdfs-noresource'        => { additions => 0, schemas_purged => 0, size => 119, },
        'rdfs-fb-tgc'            => { additions => 0, schemas_purged => 0, size => 204, },
        'rdfs-fb-tgc-noresource' => { additions => 0, schemas_purged => 0, size => 96,  },
    );
    my @rulesets = $r->available_rulesets;
    my $mod;
    for my $ruleset (@rulesets) {
        diag $ruleset;
        ok ($mod = $r->apply_rules( 
                input => $input, 
                rules => $ruleset,
            ), "Empty input to $ruleset, asserted and inferred."
        );
        is ($mod->size, $expect{$ruleset}->{size}, sprintf "%s statements.", $mod->size );
        ok ($mod = $r->apply_rules( 
                input => $input, 
                rules => $ruleset,
                purge_schemas => ':all',
            ), "Empty input to $ruleset, asserted and inferred, schemas purged."
        );
        is ($mod->size, $expect{$ruleset}->{schemas_purged}, sprintf "%s statements without schema clutter.", $mod->size );
        ok ($mod = $r->apply_rules( 
                input => $input, 
                rules => $ruleset,
                purge_schemas => ':all',
                additions_only => 1,
            ), "Empty input to $ruleset, additions only, schema purged" );
        is ($mod->size, $expect{$ruleset}->{additions}, sprintf "Thereof %s inferred statement.", $mod->size );
    }
}

sub from_rules_file {
    my $rules_file = 't/data/dummy.rules';
    my $model = RDF::Trine::Model->temporary_model;
    $model->add_statement( statement
        iri('http://test/SomethingToBeDummtLabeled'),
        iri('http://test/someProp'),
        iri('http://test/someRes'),
    );
    my $model_inferred;
    ok( $model_inferred = $r->apply_rules(
        input => $model,
        rules => $rules_file,
        additions_only => 1,
        purge_schemas => ':all',
    ), 'apply dummy.rules');
    is ($model_inferred->size, 1, '1 statement deducted');
    ok( $model_inferred = $r->apply_rules(
        input => $model,
        rules => $rules_file,
        output => $model,
        purge_schemas => ':all',
    ), 'apply dummy.rules');
    is ($model_inferred->size, 2, '2 statements total');
    # warn Dumper $serializer->serialize_model_to_string($model_inferred);
}

sub synopsis {
    use RDF::Trine::Namespace qw(rdf rdfs);

    my $one_triple = "<test/classA> <${rdfs}domain> <test/ClassB> .";

    my $reasoner = RDF::TrineX::RuleEngine::Jena->new;
    my $model_inferred = $reasoner->apply_rules(
        input => \ $one_triple,
        rules => 'rdfs-fb',
        purge_schemas => ':all',
    );

    print $model_inferred->size;    
    # 7

    my $serializer = RDF::Trine::Serializer->new('turtle' , namespaces => { rdf => $rdf, rdfs => $rdfs });
    print $serializer->serialize_model_to_string( $model_inferred );
    # <test/ClassB> rdfs:subClassOf rdfs:Resource, <test/ClassB> ;
    #     a rdfs:Class .
    # <test/classA> rdfs:domain <test/ClassB> ;
    #     a rdf:Property, rdfs:Resource .
}

&empty_model_predefined_ruleset;
&from_rules_file;
&synopsis;
