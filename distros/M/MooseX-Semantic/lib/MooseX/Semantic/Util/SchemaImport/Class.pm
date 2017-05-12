package MooseX::Semantic::Util::SchemaImport::Class;
use Moose;
use RDF::Trine;
with(
    'MooseX::Semantic::Role::Resource',
    'MooseX::Semantic::Role::RdfImport',
);

my $MOOSE = 'http://moose.perl.org/onto#';
my $moose = RDF::Trine::Namespace->new($MOOSE);

has has_attribute => (
    traits => ['Semantic', 'Array'],
    is => 'rw',
    isa => 'ArrayRef[MooseX::Semantic::MetaBuilder::Attribute]',
    uri => $moose->has_attribute,
    handles => {
        'list_attributes' => 'elements',
    },
);

has class_name => (
    traits => ['Semantic'],
    is => 'rw',
    isa => 'Str',
    uri => $moose->class_name,
);

sub add_attributes_to_class {
    my ($self, $cls) = @_;
    my $metaclass = $cls->meta;
    for my $attr ($self->list_attributes) {
        $metaclass->add_attribute( $attr->name, 
            is => 'rw',
            isa => $attr->type,
        );
    }
    return 1;
}


1;
