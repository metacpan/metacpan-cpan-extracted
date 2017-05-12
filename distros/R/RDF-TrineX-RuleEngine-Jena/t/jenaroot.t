use Test::More skip_all => 'old';
use RDF::Trine::Namespace qw(rdf rdfs);
use Data::Dumper;
use MooseX::Semantic::Test qw(ser_dump);

BEGIN {
    require_ok( 'RDF::TrineX::RuleEngine::Jena' );
}

my $rdf_type = $rdf->type;
my $rdfs_subClassOf = $rdfs->subClassOf;
my $rdfs_domain = $rdfs->domain;
my $input_nt = <<"EOF";
<A> $rdfs_domain <B> .
<B> $rdfs_domain <C> .
EOF
warn Dumper $input_nt;

my $in_model = RDF::Trine::Model->temporary_model;
RDF::Trine::Parser->new('ntriples')->parse_into_model('urn:test', $input_nt, $in_model);

my $r = RDF::TrineX::Reasoner::Jena->new( JENAROOT => '/build/Jena-2.6.4/' );
is (scalar $r->available_profiles, 16, 'profiles detected within sources jar');
# warn Dumper $r->exec_jena_rulemap;
# warn Dumper $r->available_profiles;
my $infmodel;
$infmodel = $r->apply_rules(profile => 'owl-fb-micro', input => \$input_nt);
# warn Dumper $infmodel->size;
$infmodel = $r->apply_rules(profile => 'owl-fb-micro', input => \$input_nt, remove_axioms => 1);
warn Dumper $infmodel->size;
warn Dumper ser_dump($infmodel);

diag 'owl-fb-micro: input $in_model, output temp_model, deductions_only.';
# diag 'owl-fb-micro: input $in_model, output temp_model, deductions_only.';
# diag 'owl-fb-micro: input $in_model, output temp_model, deductions_only.';
# diag 'owl-fb-micro: input $in_model, output temp_model, deductions_only.';


# warn Dumper $r->model_axioms;
# warn Dumper $r->model_axioms_owl;
# sleep;
# warn Dumper $r->infer(rules=>\"a");
# warn Dumper $r->available_profiles;
