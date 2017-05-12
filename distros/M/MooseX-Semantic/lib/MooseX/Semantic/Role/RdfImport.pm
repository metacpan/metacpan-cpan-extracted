package MooseX::Semantic::Role::RdfImport;
use Moose::Role;
use RDF::Trine qw(statement);
use Data::Dumper;
use MooseX::Semantic::Types qw(TrineResource TrineModel);
use Set::Object;
use namespace::autoclean;
use Log::Log4perl;
my $logger = Log::Log4perl->get_logger(__PACKAGE__);

with(
    'MooseX::Semantic::Role::Resource',
    'MooseX::Semantic::Util::TypeConstraintWalker',
    'MooseX::Semantic::Util::ValueHeuristics',
);

=head1 NAME

MooseX::Semantic::Role::RdfImport - Role for classes instantiable from RDF

=head1 SYNOPSIS

    package My::Model::Person;
    use Moose;
    with qw(MooseX::Semantic::Role::RdfImport);
    has name => (
        traits => ['Semantic'],
        is => 'rw',
        isa => 'Str',
        uri => 'http://xmlns.com/foaf/0.1/name',
        uri_reader => ['http://myont.org/onto#name'],
    );

    package main;
    my $base_uri = 'http://myont.org/data/';
    my $rdf_in_turtle = '
        <http://myont.org/data/Lenny> <http://xmlns.com/foaf/0.1/name> "Lenny" .
        <http://myont.org/data/Carl> <http://myont.org/onto#name> "Carl" .
    ';
    my $model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser::Turtle->parse_into_model($base_uri, $rdf_in_turtle, $model);
    my $lenny = My::Model::Person->new_from_model($model, 'http://myont.org/data/Lenny');
    my $carl = My::Model::Person->new_from_model($model, 'http://myont.org/data/Carl');
    print $lenny->name;     # 'Lenny'
    print $carl->name;      # 'Carl'

=cut 

=head1 METHODS

=cut


=head2 new_from_model( $model, $uri )

Creates a new object from resource C<$uri> in C<$model>. 

This loops through all  attributes with trait
L<MooseX::Semantic::Meta::Attribute::Trait> and searches C<$model> for all
statements about C<$uri> with the attribute's C<uri> or any of the
C<uri_reader> attributes as property. For every match, the appropriate key in
the instantiation hash is set to the value found. 

When the object of a statement represents a resource ... TODO

When all attributes have been walked, the class is instantiated with the
instantiation hash and the newly-created object is returned.

=cut
sub new_from_model {
    my ( $cls, $model, $uri, $unfinished_resources ) = @_;

    # make sure this is a TrineResource
    my $resource = TrineResource->coerce( $uri );

    # mark this instance as unfinished to avoid endless recursion
    $unfinished_resources = Set::Object->new unless $unfinished_resources;
    $unfinished_resources->insert( $resource );
    # warn Dumper [$unfinished_resources->elements];

    my $inst_hash        = $cls->_build_instance_hash($resource, $model, $unfinished_resources);
    $inst_hash->{rdf_about} = $resource;

    my $resource_obj = $cls->new(%$inst_hash);

    # mark this instance as finished
    $unfinished_resources->remove( $resource );
    return $resource_obj;
}

sub new_from_string {
    my ($cls, $model_string, $uri, %opts) = @_;
    $opts{format} //= 'nquads';
    $opts{base_uri} //= 'urn:none:';
    my $model = RDF::Trine::Model->temporary_model;
    my $parser = RDF::Trine::Parser->new($opts{format});
    $parser->parse_into_model($opts{base_uri}, $model_string, $model);
    return $cls->new_from_model($model, $uri);
}

=head2 get_instance_hash

Creates a hash of attribute/value pairs that can be passed to $cls->new

=cut

sub get_instance_hash {
    my ( $cls, $model, $uri, $unfinished_resources ) = @_;

    my $resource = TrineResource->coerce( $uri );
    $unfinished_resources = Set::Object->new unless $unfinished_resources;
    $unfinished_resources->insert( $resource );
    my $inst_hash        = $cls->_build_instance_hash($resource, $model, $unfinished_resources);
    $inst_hash->{rdf_about} = $resource;

    return $inst_hash;
}

sub _build_instance_hash {
    my $cls = shift;
    my ($resource, $model, $unfinished_resources) = @_;
    $resource = TrineResource->coerce( $resource );

    # callback for the type hierarchy walking to find
    # the first thing that's a class and a Resource
    # TODO probably better off in Util::TypeCOnstraintWalker
    # TODO better way to check if a string represents a package/class
    my $does_resource = sub {
        my $c = shift;
        $c->can('does') && $c->does('MooseX::Semantic::Role::Resource');
    };

    my $inst_hash = {};
    $cls->_walk_attributes({
        before => sub {
            my ($attr, $stash) = @_;

            # add import uris
            push (@{$stash->{uris}}, @{$attr->uri_reader}) if $attr->has_uri_reader;

            # skip attribute we can't import to (lack of uri)
            return 1 unless scalar $stash->{uris};


            # warn Dumper $stash->{uris};
            if ($stash->{uris}->[0] && $stash->{uris}->[0]->as_string eq '<http://moosex-semantic.org/onto#rdf_graph>') {
                $stash->{statement_iterator} = $model->get_statements(undef,undef,undef,$resource);
            }
            else {
                # retrieve nodes from model
                my @nodes = $model->objects_for_predicate_list($resource, @{ $stash->{uris} });

                # skip attribute if no values are to be set
                return 1 unless scalar @nodes;

                # stash nodes away for other callbacks
                $stash->{nodes} = \@nodes;
                $stash->{literal_nodes} = [ map {$_->literal_value} grep { $_->is_literal } @nodes ];
            }

            # *Don't* skip this attribute
            return undef;
        },
        literal => sub {
            my ($attr, $stash) = @_;
            return unless $stash->{literal_nodes}->[0];
            $inst_hash->{$attr->name} = $stash->{literal_nodes}->[0];
        },
        literal_in_array => sub {
            my ($attr, $stash) = @_;
            return unless $stash->{literal_nodes}->[0];
            $inst_hash->{$attr->name} = $stash->{literal_nodes};
        },
        model => sub {
            my ($attr, $stash) = @_;

            # support for MooseX::Semantic::Role::Graph
            # push (@{$stash->{rdf_graph} = $) if $attr->name eq 'rdf_graph';
            # warn Dumper $resource;
            # warn Dumper "I LIVE";
            my $graph_model = TrineModel->coerce;
            # while (my $stmt = $model->get_statements(undef,undef,undef)) {
            # warn Dumper $stash;
            while (my $stmt = $stash->{statement_iterator}->next){
                # warn Dumper $stmt;
                $graph_model->add_statement(statement( $stmt->[0], $stmt->[1], $stmt->[2] ));
            }
            # warn Dumper $inst_hash;
            $inst_hash->{$attr->name} = $graph_model;
        },
        resource => sub {
            my ($attr, $stash) = @_;
            my $attr_type_cls = $cls->_find_parent_type( $attr, $does_resource );
            my $recursive_inst_hash = $cls->_instantiate_one_object(
                $model, $stash->{nodes}->[0], $attr_type_cls, $unfinished_resources
            );
            if ($recursive_inst_hash) {
                $inst_hash->{$attr->name} = $recursive_inst_hash;
            }
        },
        resource_in_array => sub {
            my ($attr, $stash) = @_;
            my $subtype_cls = $cls->_find_parent_type( $attr, $does_resource, look_vertically => 1 );
            $inst_hash->{$attr->name} = [
                grep { defined $_ }
                map { $cls->_instantiate_one_object(
                    $model, $_, $subtype_cls, $unfinished_resources 
                ) } @{ $stash->{nodes} }
            ];
        }

    });
    return $inst_hash;
}

=head2 C<new_from_web( $uri )>

Retrieves the remote graph C<$uri> using
L<RDF::Trine::Parser's|RDF::Trine::Parser> C<parse_url_into_model> method and
tries to create a new instance from the statements found. 

=cut

sub new_from_web {
    my $cls = shift;
    my ($uri) = @_;

    my $model = RDF::Trine::Model->temporary_model;
    RDF::Trine::Parser->parse_url_into_model( $uri, $model );
    return $cls->new_from_model( $model, $uri );
}

# XXX
# TODO clever way to keep track of unfinished instances to finish them later...
sub _instantiate_one_object {
    my ($cls, $model, $resource, $instance_class, $unfinished_resources) = @_;
    # warn Dumper [$unfinished_resources->elements];
    # warn Dumper $resource;
    unless ($instance_class) {
        die "Can't instantiate $resource / $cls. Did you forget to load the type for this attribute TODO?";
        # warn Dumper $model;
        # warn Dumper $cls;
        # warn Dumper $resource;
        # die "DEATH";
    }
    if (! $instance_class->does('MooseX::Semantic::Role::Resource')) {
        warn "Resource $resource can't be instantiated as $instance_class ($instance_class doesn't MooseX::Semantic::Role::Resource)";
        return;
    }
    if ($unfinished_resources->contains( $resource )) {
        # TODO clever way to keep track of unfinished instances to finish them later...
        # warn "Resource $resource is not yet finished. Skipped to avoid deep recursion.";
        return;
    }
    if ($instance_class->does('MooseX::Semantic::Role::RdfImport')) {
        # TODO use MooseX::Unique
        return $instance_class->new_from_model( $model, $resource, $unfinished_resources );
    }
    else {
        # TODO use MooseX::Unique
        return $instance_class->new( rdf_about => $resource );
    }
}

1;
=head1 AUTHOR

Konstantin Baierer (<kba@cpan.org>)

=head1 SEE ALSO

=over 4

=item L<MooseX::Semantic|MooseX::Semantic>

=back

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

