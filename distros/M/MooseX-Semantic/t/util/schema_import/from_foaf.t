use Test::More tests=>4;
use Test::Moose;
use RDF::Trine ();
use RDF::Trine::Namespace qw(rdf);
use Data::Dumper;
use MooseX::Semantic::Test qw(ser ser_dump diff_models);
use MooseX::Semantic::Test::Person;
use MooseX::Semantic::Util::SchemaImport;
use MooseX::Semantic::Test::MetaPerson;

my $x = MooseX::Semantic::Test::MetaPerson->new(
    firstName => 'mister x',
    lastName => 'X',
);
my $p = MooseX::Semantic::Test::MetaPerson->new(
    firstName => 'Jim',
    lastName => 'Powers',
    knows => [ $x ],
);

# warn Dumper $p->knows->[0];
ok($p->meta->get_attribute('firstName'), 'Attribute "firstName" was added from RDF');
is($p->firstName, 'Jim' );
isa_ok($p->knows->[0], 'MooseX::Semantic::Test::MetaPerson', '"knows" is multi-valued object attribute');
is($p->knows->[0]->firstName, 'mister x');
