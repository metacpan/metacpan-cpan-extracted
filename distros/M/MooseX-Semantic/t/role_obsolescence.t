use Test::More tests => 5;
use Data::Dumper;

{
    package TestPerson;
    use Moose;
    extends 'MooseX::Semantic::Test::BackendPerson';
    # __PACKAGE__->rdf_type('http://xmlns.com/foaf/0.1/Person');
    # with (
    #     'MooseX::Semantic::Role::RdfObsolescence',
    # );
    no Moose;
    1;
}

my $mod = RDF::Trine::Model->temporary_model;
my $p = MooseX::Semantic::Test::BackendPerson->new(name => 'bla');
is( $mod->size, 0, 'Base model is empty');
is( $p->obsolescence_model->size, 0, 'Obsolescence model is empty');
$p->export_to_model($mod);
is( $p->obsolescence_model->size, 2, 'Obsolescence model size is 2');
is( $mod->size, 2, 'Base model has 2 stmts');
$p->name('foo');
$p->export_to_model($mod);
is( $p->obsolescence_model->size, 3, 'Obsolescence model size is 3');
# warn Dumper $p->export_to_string(format => 'sparqlu');

# warn Dumper $p->export_to_string(model => $mod, format => 'nquads', context => 'http://bla');
