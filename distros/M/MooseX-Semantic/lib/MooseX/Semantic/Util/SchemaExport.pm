package MooseX::Semantic::Util::SchemaExport;
use Moose;
use RDF::Trine qw(iri statement);
use RDF::NS;
use Data::Dumper;
use RDF::NS '20111124';

my $ns = RDF::NS->new('20111124');

our %moose_type_to_rdf_range = (
    Str => iri $ns->xsd('string'),
    'ArrayRef[Str]' => iri $ns->xsd('string'),
);

sub extract_ontology {
    my $cls = shift;
    my ($obj) = @_;
    return unless $obj->does('MooseX::Semantic::Role::WithRdfType');
    return unless $obj->does('MooseX::Semantic::Role::Resource');
    # warn Dumper "I LIVE";
    my $obj_type = $obj->rdf_type->[0];
    my $ont_model = RDF::Trine::Model->temporary_model;
    $obj->_walk_attributes({
        literal => sub {
            my ($attr, $val, $attr_name, $rels) = @_;
            # my $range = $obj->_find_parent_type( $attr, sub { $moose_type_to_rdf_range{ shift() } });
            # my $range = $obj->_find_parent_type( $attr, 'Str');
             # warn Dumper $range;
        },
        schema => sub {
            my ($attr) = @_;
            warn Dumper $attr->name ;
            # my $range = $obj->_find_parent_type( $attr, sub { $moose_type_to_rdf_range{ shift() } });
            # my $range = $obj->_find_parent_type( $attr, 'Str');
            my $moose_type =  $attr->type_constraint->name;
            my $rdf_type = $moose_type_to_rdf_range{ $moose_type };
            # warn Dumper keys %{$attr };
            # return unless $rdf_type;
            # warn Dumper $attr->uri;
            # warn Dumper $rdf_type;
            # warn Dumper $ns->rdf('type');
            if ($rdf_type) {
                $ont_model->add_statement( statement(
                        $attr->uri,
                        iri($ns->rdf('range')),
                        $rdf_type
                    )
                );
            }
            if ($attr->{required}) {
                $ont_model->add_statement( statement(
                        $attr->uri,
                        iri($ns->owl('minCardinality')),
                        $rdf_type
                    )
                );
            }
        }
    });

    # $ont_model->add_statement( RDF::Trine::Statement->new(
    #     $_,
    #     $ns->rdf('type'),

    return $ont_model;
}


__PACKAGE__->meta->make_immutable;
1;
