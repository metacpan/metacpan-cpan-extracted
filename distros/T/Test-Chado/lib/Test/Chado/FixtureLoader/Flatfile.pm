package Test::Chado::FixtureLoader::Flatfile;
{
  $Test::Chado::FixtureLoader::Flatfile::VERSION = 'v4.1.1';
}

use Moo;
use MooX::late;
use Types::Standard qw/Str/;
use YAML qw/LoadFile/;
use Test::Chado::Types qw/Twig Graph GraphT FixtureManager/;
use Test::Chado::FixtureManager::Flatfile;
use Carp;
use Graph;
use XML::Twig;
use XML::Twig::XPath;
use Graph::Traversal::BFS;

has 'namespace' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => 'test-chado'
);

has 'fixture_manager' => (
    is      => 'rw',
    isa     => FixtureManager,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Test::Chado::FixtureManager::Flatfile->new;
    }
);

has 'obo_xml' => (
    is  => 'rw',
    isa => Str
);

has 'obo_xml_loader' => (
    is      => 'rw',
    isa     => Twig,
    lazy    => 1,
    builder => 1,
    clearer => 1
);

sub _build_obo_xml_loader {
    my ($self) = @_;
    XML::Twig->new(
        twig_handlers => {
            term    => sub { $self->load_term(@_) },
            typedef => sub { $self->load_typedef(@_) }
        }
    );
}

has 'graph' => (
    is      => 'rw',
    isa     => Graph,
    default => sub { Graph->new( directed => 1 ) },
    lazy    => 1,
    clearer => 1
);

has 'traverse_graph' => (
    is      => 'rw',
    isa     => GraphT,
    lazy    => 1,
    builder => 1,
    clearer => 1,
    handles => { store_relationship => 'bfs' }
);

sub _build_traverse_graph {
    my ($self) = @_;
    Graph::Traversal::BFS->new(
        $self->graph,
        pre_edge => sub {
            $self->handle_relationship(@_);
        },
        back_edge => sub {
            $self->handle_relationship(@_);
        },
        down_edge => sub {
            $self->handle_relationship(@_);
        },
        non_tree_edge => sub {
            $self->handle_relationship(@_);
        },
    );
}

has 'ontology_namespace' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    builder => 1,
    clearer => 1
);

sub _build_ontology_namespace {
    my $self = shift;

    #which namespace to use incase it is not present for a particular node
    my $twig      = XML::Twig::XPath->new->parsefile( $self->obo_xml );
    my ($node)    = $twig->findnodes('/obo/header/default-namespace');
    my $namespace = $node->getValue;
    $twig->purge;
    croak "no default namespace being set for this ontology" if !$namespace;
    return $namespace;
}

sub reset_all {
    my ($self) = @_;
    $self->clear_graph;
    $self->clear_traverse_graph;
    $self->clear_dbrow;
    $self->clear_cvrow;
    $self->clear_ontology_namespace;
}

sub load_organism {
    my $self     = shift;
    my $organism = LoadFile( $self->fixture_manager->organism_fixture );
    unshift @$organism, [qw/abbreviation genus species common_name/];

    my $schema = $self->schema;
    $schema->txn_do(
        sub {
            $schema->populate( 'Organism::Organism', $organism );
        }
    );
}

sub load_rel {
    my ($self) = @_;
    $self->clear_ontology_namespace;
    $self->obo_xml( $self->fixture_manager->rel_fixture );
    $self->load_ontology;
}

sub load_so {
    my ($self) = @_;
    $self->clear_ontology_namespace;
    $self->obo_xml( $self->fixture_manager->so_fixture );
    $self->load_ontology;

}

sub load_ontology {
    my ($self) = @_;
    $self->reset_all;
    my $loader = $self->obo_xml_loader;
    $loader->parsefile( $self->obo_xml );
    $loader->purge;
    $self->store_relationship;
}

sub load_fixtures {
    my $self = shift;
    $self->load_organism;
    $self->load_rel;
    $self->load_so;
}

sub handle_relationship {
    my ( $self, $parent, $child, $traverse ) = @_;
    my ( $relation_id, $parent_id, $child_id );

    # -- relation/edge
    if ( $self->graph->has_edge_attribute( $parent, $child, 'id' ) ) {
        $relation_id
            = $self->graph->get_edge_attribute( $parent, $child, 'id' );
    }
    else {

        # -- get the id from the storage
        $relation_id = $self->name2id(
            $self->graph->get_edge_attribute(
                $parent, $child, 'relationship'
            ),
        );
        $self->graph->set_edge_attribute( $parent, $child, 'id',
            $relation_id );
    }

    # -- parent
    if ( $self->graph->has_vertex_attribute( $parent, 'id' ) ) {
        $parent_id = $self->graph->get_vertex_attribute( $parent, 'id' );
    }
    else {
        $parent_id = $self->name2id($parent);
        $self->graph->set_vertex_attribute( $parent, 'id', $parent_id );
    }

    # -- child
    if ( $self->graph->has_vertex_attribute( $child, 'id' ) ) {
        $child_id = $self->graph->get_vertex_attribute( $child, 'id' );
    }
    else {
        $child_id = $self->name2id($child);
        $self->graph->set_vertex_attribute( $child, 'id', $child_id );
    }

    my $schema = $self->schema;
    $schema->txn_do(
        sub {
            $schema->resultset('Cv::CvtermRelationship')->create(
                {   object_id  => $parent_id,
                    subject_id => $child_id,
                    type_id    => $relation_id
                }
            );
        }
    );
}

sub name2id {
    my ( $self, $name ) = @_;
    my $row = $self->schema->resultset('Cv::Cvterm')
        ->search( { 'name' => $name, }, { rows => 1 } )->single;

    if ( !$row ) {    #try again in dbxref
        $row
            = $self->schema->resultset('General::Dbxref')
            ->search( { accession => { -like => '%' . $name } },
            { rows => 1 } )->single;
        if ( !$row ) {
            my $namespace = $self->ontology_namespace;
            $row = $self->schema->txn_do(
                sub {
                    return $self->schema->resultset('Cv::Cvterm')->create(
                        {   cv_id => $self->find_or_create_cv_id($namespace),
                            name  => $name,
                            dbxref => {
                                db_id =>
                                    $self->find_or_create_db_id($namespace),
                                accession => $name,
                            }
                        }
                    );
                }
            );
            return $row->cvterm_id;
        }
        return $row->cvterm->cvterm_id;
    }
    $row->cvterm_id;
}

sub build_relationship {
    my ( $self, $node, $cvterm_row ) = @_;
    my $child = $cvterm_row->name;
    for my $elem ( $node->children('is_a') ) {
        my $parent = $self->normalize_name( $elem->text );
        $self->graph->set_edge_attribute( $parent, $child, 'relationship',
            'is_a' );
    }

    for my $elem ( $node->children('relationship') ) {
        my $parent = $self->normalize_name( $elem->first_child_text('to') );
        $self->graph->add_edge( $parent, $child );
        $self->graph->set_edge_attribute( $parent, $child, 'relationship',
            $self->normalize_name( $elem->first_child_text('type') ) );
    }
}

sub load_typedef {
    my ( $self, $twig, $node ) = @_;

    my $name        = $node->first_child_text('name');
    my $id          = $node->first_child_text('id');
    my $is_obsolete = $node->first_child_text('is_obsolete');

    my $namespace
        = $node->has_child('namespace')
        ? $node->first_child_text('namespace')
        : $self->ontology_namespace;

    my $def_elem = $node->first_child('def');
    my $definition;
    $definition = $def_elem->first_child_text('defstr') if $def_elem;

    my $schema     = $self->schema;
    my $cvterm_row = $schema->txn_do(
        sub {
            return $schema->resultset('Cv::Cvterm')->create(
                {   cv_id => $self->find_or_create_cv_id($namespace),
                    is_relationshiptype => 1,
                    name                => $self->normalize_name($name),
                    definition          => $definition || '',
                    is_obsolete         => $is_obsolete || 0,
                    dbxref              => {
                        db_id     => $self->find_or_create_db_id($namespace),
                        accession => $id,
                    }
                }
            );
        }
    );

    #hold on to the relationships between nodes
    $self->build_relationship( $node, $cvterm_row );

    #no additional dbxref
    return if !$def_elem;

    $self->create_more_dbxref( $def_elem, $cvterm_row, $namespace );
}

sub load_term {
    my ( $self, $twig, $node ) = @_;

    my $name        = $node->first_child_text('name');
    my $id          = $node->first_child_text('id');
    my $is_obsolete = $node->first_child_text('is_obsolete');

    my $namespace
        = $node->has_child('namespace')
        ? $node->first_child_text('namespace')
        : $self->ontology_namespace;

    my $def_elem = $node->first_child('def');
    my $definition;
    $definition = $def_elem->first_child_text('defstr') if $def_elem;

    my $schema     = $self->schema;
    my $cvterm_row = $schema->txn_do(
        sub {
            return $schema->resultset('Cv::Cvterm')->create(
                {   cv_id       => $self->find_or_create_cv_id($namespace),
                    name        => $self->normalize_name($name),
                    definition  => $definition || '',
                    is_obsolete => $is_obsolete || 0,
                    dbxref      => {
                        db_id     => $self->find_or_create_db_id($namespace),
                        accession => $id,
                    }
                }
            );
        }
    );

    #hold on to the relationships between nodes
    $self->build_relationship( $node, $cvterm_row );

    #no additional dbxref
    return if !$def_elem;

    $self->create_more_dbxref( $def_elem, $cvterm_row, $namespace );
}

sub normalize_name {
    my ( $self, $name ) = @_;
    return $name if $name !~ /:/;
    my $value = ( ( split /:/, $name ) )[1];
    return $value;
}

sub create_more_dbxref {
    my ( $self, $def_elem, $cvterm_row, $namespace ) = @_;
    my $schema = $self->schema;

    # - first one goes with alternate id
    my $alt_id = $def_elem->first_child_text('alt_id');
    if ($alt_id) {
        $schema->txn_do(
            sub {
                $cvterm_row->create_related(
                    'cvterm_dbxrefs',
                    {   dbxref => {
                            accession => $alt_id,
                            db_id => $self->find_or_create_db_id($namespace)
                        }
                    }
                );
            }
        );
    }

    #no more additional dbxrefs
    my $def_dbx = $def_elem->first_child('dbxref');
    return if !$def_dbx;

    my $dbname = $def_dbx->first_child_text('dbname');
    $schema->txn_do(
        sub {
            $cvterm_row->create_related(
                'cvterm_dbxrefs',
                {   dbxref => {
                        accession => $def_dbx->first_child_text('acc'),
                        db_id     => $self->find_or_create_db_id($dbname)
                    }
                }
            );
        }
    );
}

with 'Test::Chado::Role::Helper::WithBcs';

1;

__END__

=pod

=head1 NAME

Test::Chado::FixtureLoader::Flatfile

=head1 VERSION

version v4.1.1

=head1 SYNOPSIS

use Test::Chado::FixtureLoader::Flatfile;
use Test::Chado::Factory::FixtureLoader;

my $sqlite = Test::Chado::Factory::FixtureLoader->get_instance('sqlite');
my  $loader = Test::Chado::FixtureLoader::Flatfile->new(dbmanager => $sqlite);
$sqlite->load_fixtures;

=head1 DESCRIPTION

This class primarilly provides a method B<load_fixtures> to load all the default fixtures that comes bundled with distribution.

=head2 Default fixtures

=head3 Organisms entries

It's a B<YAML> version of organism entries found in the B<initialize.sql> file of official chado distribution.

=head3 Sequence ontology feature annotation (SOFA)

The lite L<version|http://www.sequenceontology.org/resources/intro.html> of sequence ontology. 

=head3 Relation ontology

Obtained from L<here|http://code.google.com/p/obo-relations/>

=head1 NAME

Class to manage loading of test fixture from flatfile

=head1 API

=head2 Attributes

These are public attributes defined exclusively in this class. For rest of the consumed attributes look at L<Test::Chado::Role::Helper::WithBcs>

=over

=item obo_xml

Name of obo xml file

=item obo_xml_loader

Instance of <XML::Twig> with two handlers, one to load the term and other for relations

=item graph

Instance of L<Graph>

=item traverse_graph

Instance of L<Graph::Traversal>

=item ontology_namespace

=back

=head2 Methods

Other than the exclusive methods below, look at the role L<Test::Chado::Role::Helper::WithBcs>

=over

=item load_fixtures

Loads all default fixtures from flatfiles.

=item load_organism

Loads organism fixtures from B<organism.yaml> file

=load_rel

Loads relationship ontology from relationship.obo_xml

=load_so

Loads sequence ontology(SO) from sofa.obo_xml file

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
