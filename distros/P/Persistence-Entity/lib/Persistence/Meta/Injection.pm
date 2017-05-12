package Persistence::Meta::Injection;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use Carp 'confess';
use Persistence::Entity ':all';
use Persistence::Relationship;
use Persistence::Relationship::ToOne;
use Persistence::Relationship::OneToMany;
use Persistence::Relationship::ManyToMany;
use Persistence::ValueGenerator::TableGenerator;
use Persistence::ValueGenerator::SequenceGenerator;

use Storable qw(store retrieve);

$VERSION = 0.01;

=head1 NAME

Persistence::Meta::Injection - Persisitence meta definition object.

=cut

=head1 SYNOPSIS

    use Persistence::Meta::Injection;

    my $obj = Persistence::Meta::Injection->new;

=head1 DESCRIPTION

Represents persistence meta data that is loaded as a persistence unit.
(Entitties + ORM mapping)

=head1 EXPORT

None

=head2 ATTRIBUTES

=over

=item entities

=cut

has '%.entities' => (item_accessor => 'entity', index_by => 'id');


=item _entities_subquery_columns

=cut

has '%._entities_subquery_columns';


=item _entities_to_many_relationship

=cut

has '%._entities_to_many_relationships';


=item _entities_to_one_relationship

=cut

has '%._entities_to_one_relationships';


=item orm_files

=cut

has '@.orm_files';


=item entities_files

=cut

has '@.entities_files';


=item sequence_generators

=cut

has '@.sequence_generators';


=item table_generators

=cut

has '@.table_generators';


=item _orm_mapping

=cut

has '@._orm_mapping';


=item entity_manager

=cut

has '$.entity_manager';


=item cached_version

=cut

has '$.cached_version';


=item file_stats

=cut


has '%.file_stats' => (item_accessor => 'file_stat');


=back

=head2 METHODS

=over

=item load_persistence_context

=cut

sub load_persistence_context {
    my ($self, $xml, $file) = @_;
    my $entity_manager = $self->entity_manager;
    
    if(! $self->cached_version) {
        my $entity_files = $self->entities_files;
        my $orm_files = $self->orm_files;
        my $entity_xml_hander = $xml->entity_xml_handler;
        my $orm_xml_handler = $xml->orm_xml_handler;
        my $prefix_dir = $xml->persistence_dir;
        for my $entity_ref (@$entity_files) {
            my $file_name = $prefix_dir . $entity_ref->{file};
            $self->add_file_stat($file_name);
            my %overwriten_entity_attributes = (map { $_ ne 'file' ? ($_ => $entity_ref->{$_}) : ()} keys %$entity_ref);
            my $entity = $entity_xml_hander->parse_file($file_name, \%overwriten_entity_attributes);
            $self->entity($entity->id, $entity);
        }
    
        $self->_initialise_subquery_columns();
        $self->_initialise_to_one_relationships();
        $self->_initialise_to_many_relationships();
        $self->_initialise_value_generators();
    
        for my $orm_ref (@$orm_files) {
            my $file_name = $prefix_dir . $orm_ref->{file};
            $self->add_file_stat($file_name);
            $orm_xml_handler->parse_file($file_name);
        }

        if ($xml->use_cache) {
            $self->_store($xml, $file);
        }
    }

    my %entities = $self->entities;
    $entity_manager->add_entities(values %entities);
    $self->crate_orm_mappings();
    $entity_manager;
}


=item _store

=cut

sub _store {
    my ($self, $xml, $file) = @_;
    my $cache_file_name = $xml->cache_file_name($file);
    $self->set_cached_version(1);
    store $self, $cache_file_name;
}


=item load_from_cache

Loads injection object from cache

=cut

sub load_from_cache {
    my ($class, $xml, $file) = @_;
    my $cache_file_name = $xml->cache_file_name($file);
    my $result;
    if(-e $cache_file_name) {
        $result = retrieve($cache_file_name);
    }
    $result
}


=item can_use_cache

Returns true if there are not changes in xml files

=cut

sub can_use_cache {
    my ($self) = @_;
    my $result = 1;
    my $file_stats = $self->file_stats;
    return undef unless (%$file_stats);
    for my $file(keys %$file_stats) {
        my $modification_time = file_modification_time($file);
        return if $file_stats->{$file} ne $modification_time;
    }
    $result;
}


=item _initialise_value_generators

Initialises value generators

=cut

sub _initialise_value_generators {
    my ($self) = @_;
    $self->_initialise_generators('Persistence::ValueGenerator::TableGenerator', 'table_generators');
    $self->_initialise_generators('Persistence::ValueGenerator::SequenceGenerator', 'sequence_generators');
}


=item _initialise_table_value_generators

=cut

sub _initialise_generators {
    my ($self, $class, $accessor) = @_;
    my $entity_manager = $self->entity_manager;
    my $generators = $self->$accessor;
    for my $generator (@$generators) {
        $class->new(%$generator, entity_manager_name => $entity_manager->name);
    }
}


=item _initialise_subquery_columns

Initialise subquery columns

=cut

sub _initialise_subquery_columns {
    my ($self) = @_;
    my $entities = $self->entities;
    my $entities_subquery_columns = $self->_entities_subquery_columns;
    for my $entity_id (keys %$entities_subquery_columns) {
        my $entity = $entities->{$entity_id};
        my @subquery_columns;
        my $subquery_columns = $entities_subquery_columns->{$entity_id};
        for my $column_definition (@$subquery_columns) {
            push @subquery_columns,
                $self->entity_column($column_definition->{entity}, $column_definition->{name});
        }
        $entity->add_subquery_columns(@subquery_columns)
            if @subquery_columns;
    }
}


=item _initialise_to_one_relationship

Initialise to one relationships

=cut

sub _initialise_to_one_relationships {
    my ($self) = @_;
    $self->_initialise_relationships('to_one_relationships');
}


=item _initialise_to_many_relationship

Initialise to manye relationships

=cut

sub _initialise_to_many_relationships {
    my ($self) = @_;
    $self->_initialise_relationships('to_many_relationships');
}


=item _initialise_relationships

Initialises relationshsips
Takes relationship type as parameters.
Allowed value: 'to_one_relationships', 'to_many_relationships'

=cut

sub _initialise_relationships {
    my ($self, $relationship_type) = @_;
    my $entities = $self->entities;
    my $relationship_accessor = "_entities_${relationship_type}";
    my $entities_relationships = $self->$relationship_accessor;
    my $mutator = "add_${relationship_type}";

    for my $entity_id (keys %$entities_relationships) {
        my $entity = $entities->{$entity_id};
        my @relationships;
        my $relationships = $entities_relationships->{$entity_id};
        
        for my $relationship (@$relationships) {
            push @relationships, $self->_relationship($relationship);
        }
        
        if (@relationships) {
            $entity->$mutator(@relationships)
        }
            
    }
}



=item crate_orm_mappings

=cut

sub crate_orm_mappings {
    my ($self) = @_;
    my $orm_mapping = $self->_orm_mapping;
    for (my $i = 0; $i< $#{$orm_mapping}; $i += 2) {
        $self->create_orm_mapping($orm_mapping->[$i], $orm_mapping->[$i + 1]);
    }
}


=item create_orm_mapping

Creates orm mappings.

=cut

sub create_orm_mapping {
    my ($self, $args, $rules) = @_;
    my $columns = $rules->{columns};
    my $lobs  = $rules->{lobs};
    my $to_one_relationships = $rules->{to_one_relationships};
    my $one_to_many_relationships = $rules->{one_to_many_relationships};
    my $many_to_many_relationships = $rules->{many_to_many_relationships};
    $args->{entity_name} = $args->{entity}, delete $args->{entity};
    my $orm = Persistence::ORM->new(%$args);
    my $columns_map = {};
    for my $column (@$columns) {
         $columns_map->{$column->{name}} = {name => $column->{attribute}};
    }

    $orm->set_columns($orm->covert_to_attributes($columns_map));
    my $lob_map = $orm->covert_to_lob_attributes($lobs);
    $orm->set_lobs($lob_map);
    
    for my $relation (@$to_one_relationships) {
        $self->_add_to_one_relationship($relation, $orm);
    }
    for my $relation (@$one_to_many_relationships) {
        $self->_add_one_to_many_relationship($relation, $orm);
    }
    for my $relation (@$many_to_many_relationships) {
        $self->_add_many_to_many_relationship($relation, $orm);
    }
    $orm;
}



=item _add_one_to_many_relationship

=cut

sub _add_one_to_many_relationship {
    my ($self, $relationship, $orm) = @_;
    Persistence::Relationship::OneToMany->add_relationship($self->_add_relationship_parameters($relationship, $orm));
}



=item _add_to_many_to_many_relationship

=cut

sub _add_many_to_many_relationship {
    my ($self, $relationship, $orm) = @_;
    Persistence::Relationship::ManyToMany->add_relationship($self->_add_relationship_parameters($relationship, $orm));
}


=item _add_to_one_relationship

=cut

sub _add_to_one_relationship {
    my ($self, $relationship, $orm) = @_;
    Persistence::Relationship::ToOne->add_relationship($self->_add_relationship_parameters($relationship, $orm));
}


=item _add_relationship_parameters

=cut

sub _add_relationship_parameters {
    my ($self, $relationship, $orm) = @_;
    my $attribute = $orm->attribute($relationship->{attribute});
    
    my @result = ($orm->class, $relationship->{name}, attribute => $attribute);
    if (my $fetch_method = $relationship->{fetch_method}) {
        push @result, 'fetch_method' => Persistence::Relationship->$fetch_method();
    }
    if (my $cascade = $relationship->{cascade}) {
        push @result, 'cascade' => Persistence::Relationship->$cascade();
    }
    
    if (my $join_entity = $relationship->{join_entity}) {
        push @result, 'join_entity_name' => $join_entity;
    }
    @result;
}



=item _relationship

Returns the relationship object.
Takes hash_ref, that will be transformed to the new object parameters.

=cut

sub _relationship {
    my ($self, $relationship) = @_;
    my $target_entity = ref($relationship->{target_entity}) ? $relationship->{target_entity}->id : $relationship->{target_entity};
    
    my $entity = $self->entity($target_entity)
        or confess "unknow entity " . $target_entity;
    $relationship->{target_entity} = $entity;
    my $condition = $relationship->{condition};
    $self->_parse_condition($condition) if $condition;
    sql_relationship(%$relationship);
}


=item _parse_condition

Parses condition object to replacase ant occurence of  <entity>.<column> to column object.

=cut

sub _parse_condition {
    my ($self, $condition) = @_;
    {
        my $operand1 = $condition->operand1;
        my ($entity, $column) = $self->has_column($operand1);
        $condition->set_operand1($self->entity_column($entity, $column)) if($column)
    }
    {
        my $operand2 = $condition->operand2;
        my ($entity, $column) = $self->has_column($operand2);
        $condition->set_operand2($self->entity_column($entity, $column)) if($column)
    }
    my $conditions = $condition->conditions;
    for my $k (@$conditions) {
        $self->_parse_condition($k);
    }

}


=item has_column

=cut

sub has_column {
    my ($self, $text) = @_;
    ($text =~ m /^sql_column:(\w+)\.(\w+)/);
}

=item entity_column

Returns entity column

=cut

sub entity_column {
    my ($self, $entity_id, $column_id) = @_;
    my $entities = $self->entities;
    my $entity = $entities->{$entity_id}
        or confess "unknown entity: ${entity_id}";
    my $column = $entity->column($column_id)
        or confess "unknown column ${column_id} on entity ${entity_id}";
}


=item add_file_stat

Adds file modification time

=cut

sub add_file_stat {
    my ($self, $file) = @_;
    my $modification_time = file_modification_time($file);
    $self->file_stat($file, $modification_time);
}


=item file_modification_time

=cut

sub file_modification_time {
    my $file = shift;
    my $modification_time = (stat $file)[9];
}


1;

__END__

=back

=head1 SEE ALSO

L<Persistence::Meta::XML>

=head1 COPYRIGHT AND LICENSE

The Persistence::Meta::Injection module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, E<lt>adrian@webapp.strefa.pl</gt>

=cut

1;
