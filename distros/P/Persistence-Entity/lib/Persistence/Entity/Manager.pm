package Persistence::Entity::Manager;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.03;

use Abstract::Meta::Class ':all';
use Persistence::ORM;
use DBIx::Connection;
use Carp 'confess';
use Persistence::Entity ':all';

use constant TRANSACTION_MANAGEMENT => 'transaction';

=head1 NAME

Persistence::Entity::Manager - Persistence entity manager.

=head1 SYNOPSIS

use Persistence::Entity::Manager;
use SQL::Entity;
use SQL::Entity::Column ':all';
use SQL::Entity::Condition ':all';

    my $entity_manager = Persistence::Entity::Manager->new(
        name            => 'my_manager'
        connection_name => 'my_connection'
    );

    $entity_manager->add_entities(SQL::Entity->new(
        name                  => 'emp',
        primary_key          => ['empno'],
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        triggers => {
        on_fetch => sub { ... },
        before_insert => sub { ... ]
    ));

    {
        package Employee;
        use Abstract::Meta::Class ':all';
        use Persistence::ORM ':all';

        entity 'emp';
        column empno => has('$.no') ;
        column ename => has('$.name');
    }

    {
        my ($emp) = $entity_manager->find(emp => 'Employee', name => 'foo');
        #object attribute name as part of the condition

        my (@emp) = $entity_manager->find(emp => 'Employee', sql_cond('ename', 'LIKE' 'a%');
    }

    {
        $entity_manager->begin_work;
        eval {
            my $emp = Employee->new(name => 'foo');
            $entity_manager->insert($user);

            $emp->set_deptno(10);
            $entity_manager->update($emp);

            $entity_manager->delete($emp)

            my ($emp) = $entity_manager->find(emp => 'Employee', name => 'foo');

            $entity_manager->commit;
         };

         $entity_manager->rollback if($@);
    }


=cut

=head1 DESCRIPTION

Represets entity manager.

=head1 EXPORT

None.

=head2 ATTRIBUTES

=over

=item name

=cut

has '$.name' => (required => 1);


=item entities

=cut

has '%.entities' => (
    associated_class => 'Persistence::Entity', 
    index_by         => 'id',
    item_accessor    => 'entity',
    the_other_end    => 'entity_manager',
);


=item entities

=cut

has '%.queries' => (
    associated_class => 'SQL::Query', 
    index_by         => 'name',
    item_accessor    => '_query',
);


=item connection_name

=cut

has '$.connection_name' => (
    on_change => sub {
        my $self = shift;
        my $connection = $self->_connection or return $self;
        $connection->close();
        $self->set__connection(undef);
    }
);


=item _connection

=cut

has '$._connection' => (transistent => 1);


=item persitence_mangement

If this option is set, then state of the all fetched, merged or created object by entity manager will be tracked 
(it's database state is stored in local cache),
unless they become detached by calling $entity_manager->detach($obj) or $entity_manager->detach_all
or for persitence_mangement = transaction

    $entity_manager->commit;
    $entity_manager->rollback;

Note:
Using this option you must ensure that there are not obsolete objects in the local cache by detching all objects
that are no longer in use, it may be resource consuming (memory).

If the persitence_mangement option is not set then extra sql will be issued to get object state from database for update, delete.

=cut

has '$.persitence_mangement' => (default => TRANSACTION_MANAGEMENT());


=item _persistence_cache

Stores datebase state of the object. The key is the object reference, the values database row.

=cut

has '%._persistence_cache' => (item_accessor => '_cached_state');


=item _lazy_fetch_flag

Hash that stores information about lazy retrieve for objects attribute

=cut

has '%._lazy_fetch_flags' => (item_accessor => '_lazy_fetch_flag');

=back

=head2 METHODS

=over

=cut


{   my %managers;

=item initialise

=cut

    sub initialise {
        my ($self) = @_;
        $managers{$self->name} = $self;
    }


=item manager

Return entity manger object, takes entity manager name as parameter.

    Persistence::Entity::Manager->new(name => 'manager_name', connection_name => 'connection_nane');
    #
    my $entity_manager = Persistence::Entity::Manager->manager('manager_name');


=cut

    sub manager {
        my ($class, $name) = @_;
        $managers{$name}
            or confess "unknown entity manager $name";
    }

}


=item find

Returns list of objects or resultsets.
Takes entity name, class name to which resultset will be casted,
(if class name is undef then hash ref will be return instead),
list of names parameters that will be used as condition or condition object.
For non empty class name resulset state is cached - persitence_mangement option.

Note: If class name has the ORM mapping, then name parameters
must be objects' attributs . Condition object always should use entity column.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    or

    my @emp = $entity_manager->find(emp => 'Employee', sql_cond('ename', 'LIKE', 'a%'));
    #array of Employee objects.

    or 
    my @emp = $entity_manager->find(emp => undef, sql_cond('ename', 'LIKE', 'a%'));
    #array of resultset (hash ref)


=cut

sub find {
    my ($self, $entity_name, $class_name, @args) = (@_);
    my $entity = $self->entity($entity_name) or confess "cant find entity ${entity_name}";
    $entity->find($class_name, @args);
}


=item lock

Returns and locks list and of objects or resultsets.
Takes entity name, class name to which resultset will be casted,
(if class name is undef then hash ref will be return instead),
list of names parameters that will be used as condition or condition object.
For non empty class name resulset state is cached - persitence_mangement option.

Note: If class name has the ORM mapping, then name parameters
must be objects' attributs . Condition object always should use entity column.


    my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
    or

    my @emp = $entity_manager->find(emp => 'Employee', sql_cond('ename', 'LIKE', 'a%'));
    #array of Employee objects.

    or 
    my @emp = $entity_manager->find(emp => undef, sql_cond('ename', 'LIKE', 'a%'));
    #array of resultset (hash ref)


=cut

sub lock {
    my ($self, $entity_name, $class_name, @args) = (@_);
    my $entity = $self->entity($entity_name) or confess "cant find entity ${entity_name}";
    $entity->lock($class_name, @args);
}


=item condition_converter

Converts list of parameters to condition object.
Takes class name, list of condition parameters.
Note: If class name has the ORM mapping, then name parameters
must be objects' attributs . Condition object always should use entity column.


    my $sql_condition = $entity_manager->condition_converter('Employee', name => 'adrian');
    #creates ename = 'adrian'  sql condition (given that there is mapping between ename column to name attribute).


See also L<SQL::Entity::Condition>

=cut

sub condition_converter {
    my ($self, $class_name, @args) = @_;
    my $orm = $self->find_entity_mappings($class_name);
    (@args > 1)
        ? SQL::Entity::Condition->struct_to_condition(
            ($orm ? $orm->attribute_values_to_column_values(@args) : @args))
        : $args[0];
}


=item query

Returns new query object.
Takes entity name, optionally class name to which resultset will be casted,
(if class name is undef then hash ref will be return instead),
For non empty class name resulset state is cached - persitence_mangement option.

    my $query = $entity_manager->query(emp => undef);
    $query->set_offset(20);
    $query->set_limit(5);
    my @emp = $query->execute(['empno', 'ename']);

    $query->set_offset(120);
    $query->set_limit(5);
    my @emp = $query->execute(undef, deptnp => 10);


See also L<Persistence::Entity::Query>

=cut

sub query {
    my ($self, $entity_name, $class_name) = (@_);
    my $orm = $self->find_entity_mappings($class_name);
    my $entity = $self->entity($entity_name) or confess "cant find entity ${entity_name}";
    my $connection = $self->connection;
    my $dbms_name = $connection->dbms_name;
    my $key = $entity->name ."_${dbms_name}_" . ($class_name ||'');
    my $query = $self->_query($key);
    unless($query) {
        $query = Persistence::Entity::Query->new(
            name            => $key,
            entity          => $entity,
            dialect         => $connection->dbms_name,
            cursor_callback => sub {
                my ($this, $sql, $bind_variables) = @_;
                $this->query_setup($connection);
                $entity->_execute_query($sql, $bind_variables, $class_name);
            },
            condition_converter_callback => sub {
                my (@args) = @_;
                $self->condition_converter($class_name, @args);
            }
        );
        $self->add_queries($query);
    }
    $query;
}


=item refersh

Refresh object's state.
Takes object as parameter.


    my $emp = Emp->new(id => 10);
    $entity_manager->refresh($emp);

Refresh operation caches object - persitence_mangement option.

=cut

sub refersh {
    my ($self, $object) = @_;
    my $orm = $self->find_entity_mappings($object, 1);
    $self->_reset_lazy_relation_attributes($object);
    $self->detach($object);
    my $entity = $self->entity($orm->entity_name);
    my %fields_values = $orm->column_values($object);
    my %condition_values = $entity->unique_condition_values(\%fields_values, 1);
    my ($resultset) = $entity->find(undef, %condition_values);
    $orm->update_object($object, $resultset);
    $self->_manage_object($object, $resultset);
    $orm->deserialise_eager_relation_attributes($object, $self);
    $object;
}


=item insert

Inserts object that is mapped to the entity, takes the object as parameter


    my $emp = Emp->new(id => 10, name => 'scott');
    $entity_manager->insert($emp);


=cut

sub insert {
    my ($self, $object, $values) = @_;
    $values ||= {};
    my $orm = $self->find_entity_mappings($object, 1);
    my %fields_values = ($orm->column_values($object), %$values);
    my $entity = $self->entity($orm->entity_name);
    $self->_insert_to_one_relationship($entity, $object, \%fields_values, $orm);
    $orm->run_event('before_insert', \%fields_values);
    my $fields_values = $entity->insert(%fields_values);
    $self->_update_generated_values($orm, $entity, $object, $fields_values);
    my $refresh_required_flag = $entity->is_refresh_required($fields_values);
    $self->refersh($object)  if $refresh_required_flag;
    my %unique_values = $entity->unique_condition_values($fields_values);
    $self->_insert_to_many_relationship($entity, $object, {$entity->unique_condition_values($fields_values)}, $orm);
    $orm->run_event('after_insert', $fields_values);
    $self->_manage_object($object, $fields_values);
}


=item update

Updates object that is mapped to the entity, takes the object as parameter

    my $emp = Emp->new(id => 10, name => 'scott');
    $entity_manager->update($emp);


=cut

sub update {
    my ($self, $object, $values) = @_;
    $values ||= {};
    my $orm = $self->find_entity_mappings($object, 1);
    my $entity = $self->entity($orm->entity_name);
    $orm->deserialise_lazy_relation_attributes($object, $self);
    $self->initialise_operation($orm->entity_name, $object);
    my %fields_values = ($orm->column_values($object), %$values);
    $self->_update_to_one_relationship($entity, $object, \%fields_values, $orm);
    my $changed_column_values = $self->changed_column_values($entity, $object, \%fields_values);
    my %unique_values = $entity->unique_condition_values(\%fields_values);

    if ($changed_column_values) {
        $orm->run_event('before_update', \%fields_values);
        $entity->update($changed_column_values, \%unique_values);
    }
    $self->_update_to_many_relationship($entity, $object, \%unique_values, $orm);
    $self->complete_operation($orm->entity_name, $object);
    if ($changed_column_values) {
        $orm->run_event('after_update', \%fields_values);
        $self->_manage_object($object, \%fields_values);
    }
    
}


=item merge

Merges object that is mapped to the entity, takes the object as parameter
Is robject exists in database the updates, otherwise inserts.


    my $emp = Emp->new(id => 10, name => 'scott');
    $entity_manager->merge($emp);



=cut

sub merge {
    my ($self, $object, $values) = @_;
    my $orm = $self->find_entity_mappings($object, 1);
    return if $self->has_pending_operation($orm->entity_name);
    my $entity = $self->entity($orm->entity_name);
    my %fields_values = $orm->unique_values($object, $entity);
    my ($result) = $entity->find(undef, $entity->unique_condition_values(\%fields_values));
    unless ($result) {
        $self->insert($object, $values);
    } else {
        $self->_update_pk_values($orm, $entity, $object, $result)
          unless $entity->has_primary_key_values(\%fields_values);
        $self->update($object, $values);
    }
}



=item delete

Delets object that is mapped to the entity, takes object as parameter


    my $emp = Emp->new(id => 10, name => 'scott');
    $entity_manager->delete($emp);


=cut

sub delete {
    my ($self, $object) = @_;
    my $orm = $self->find_entity_mappings($object, 1);
    return if $self->has_pending_operation($orm->entity_name);
    $orm->deserialise_lazy_relation_attributes($object, $self);
    $self->initialise_operation($orm->entity_name, $object);
    my $entity = $self->entity($orm->entity_name);
    my %fields_values = ($orm->column_values($object));
    my %condition_values = $entity->unique_condition_values(\%fields_values);
    $orm->run_event('before_delete', \%condition_values);
    $self->_delete_to_many_relationship($entity, $object, \%condition_values, $orm);
    $entity->delete(%condition_values);
    $self->_delete_to_one_relationship($entity, $object, \%condition_values, $orm);
    $self->complete_operation($orm->entity_name);
    $orm->run_event('after_delete', \%condition_values);
    $self->detach($object);
}


=item begin_work

Begins a new transaction.

   $entity_manager->begin_work;
    eval {
        my $emp = Employee->new(name => 'foo');
        $entity_manager->insert($user);
        $entity_manager->commit;
    }
    $entity_manager->rollback if $@;

=cut

sub begin_work {
    my ($self) = @_;
    $self->connection->begin_work;
}


=item commit

Commits current transaction.

    $entity_manager->commit;

=cut

sub commit {
    my ($self) = @_;
    $self->connection->commit;
    my $persitence_mangement = $self->persitence_mangement;
    $self->detach_all
        if ($persitence_mangement && $persitence_mangement eq TRANSACTION_MANAGEMENT());
}


=item rollback

Rollbacks current transaction.

    $entity_manager->reollback;

=cut

sub rollback {
    my ($self) = @_;
    $self->connection->rollback;
    my $persitence_mangement = $self->persitence_mangement;
    $self->detach_all
        if ($persitence_mangement  && $persitence_mangement eq TRANSACTION_MANAGEMENT());
}



=item detach

Removes database object state from cache.

....$entity_manager->search()
    $entity_manager->detach

=cut

sub detach {
    my ($self, $object) = @_;
    my $persistence_cache = $self->_persistence_cache;
    my $lazy_fetch_flags = $self->_lazy_fetch_flags;
    delete $persistence_cache->{$object};
    delete $lazy_fetch_flags->{$object};
}


=item detach_all

Clears entity cache.

=cut

sub detach_all {
    my $self = shift;
    $self->set__persistence_cache({});
    $self->set__lazy_fetch_flags({});
}


=item connection

Returns connection object.

=cut

sub connection {
    my ($self) = @_;
    my $connection = $self->_connection;
    unless($connection) {
        $connection = $self->_connection(DBIx::Connection->connection($self->connection_name));
    }
    $connection;
}


=back

=head2 PRIVATE METHODS

=over

=item initialise_operation

=cut

{

    my %pending_op;
    sub initialise_operation {
        my ($class, $resource, $value) = @_;
        $value ||= 1;
        $pending_op{$resource} = $value;
    }


=item has_pending_operation

=cut

    sub has_pending_operation {
        my ($class, $resource) = @_;
        $pending_op{$resource};
    }


=item complete_operation

=cut

    sub complete_operation {
        my ($class, $resource) = @_;
        delete $pending_op{$resource};
    }
}

=item find_entity_mappings

Returns entity mapping object
Takes object or class name, and optionally
must_exists_validation flag that will raise an error if mapping object does not exist.

=cut

sub find_entity_mappings {
    my ($self, $object, $must_exists_validation) = @_;
    my $class_name = ref($object) || $object;
    my $result = Persistence::ORM::mapping_meta($class_name);
    confess "cant find entity mapping for ${class_name}"
        if ($must_exists_validation && ! $result);
    $result->entity_manager($self) if $result;
    $result;
}


=item _update_generated_values

Updates object by generated values.

=cut

sub _update_generated_values {
    my ($self, $orm, $entity, $object, $fields_values) = @_;
    my %value_generators =  $entity->value_generators;
    $orm->update_object($object, $fields_values, (%value_generators ? [keys %value_generators] : ()));
}


=item _to_many_insert_relationship

=cut

sub _insert_to_many_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->insertable_to_many_relations(ref $object);
    for my $relation (@relations) {
        $relation->insert($orm, $entity, $unique_values, $object);
    }
    $orm->deserialise_eager_relation_attributes($object, $self) if @relations;
}


=item _insert_to_one_relationship

=cut

sub _insert_to_one_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->insertable_to_one_relations(ref $object);
    for my $relation (@relations) {
        $relation->insert($orm, $entity, $unique_values, $object);
    }
}


=item _update_pk_values

=cut

sub _update_pk_values {
    my ($self, $orm, $entity, $object, $fields_values) = @_;
    my $pk = $entity->primary_key or return;
    $orm->update_object($object, $fields_values, $pk);
}


=item _update_to_many_relationship

=cut

sub _update_to_many_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->updatable_to_many_relations(ref $object);
    for my $relation (@relations) {
        $relation->merge($orm, $entity, $unique_values, $object);
    }
}


=item _update_to_one_relationship

=cut

sub _update_to_one_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->updatable_to_one_relations(ref $object);
    for my $relation (@relations) {
        $relation->merge($orm, $entity, $unique_values, $object);
    }
}


=item _delete_to_many_relationship

=cut

sub _delete_to_many_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->deleteable_to_many_relations(ref $object);
    for my $relation (@relations) {
        $relation->delete($orm, $entity, $unique_values, $object);
    }
}


=item _delete_to_one_relationship

=cut

sub _delete_to_one_relationship {
    my ($self, $entity, $object, $unique_values, $orm) = @_;
    my @relations = Persistence::Relationship->deleteable_to_one_relations(ref $object);
    for my $relation (@relations) {
        $relation->delete($orm, $entity, $unique_values, $object);
    }
}


=item _deserialise_object

Casts result set to passed in class name, optionally uses Object-relational mapping.

=cut

sub _deseralize_object {
    my ($self, $class_name, $resultset, $entity) = @_;
    my $result;
    my $orm = $self->find_entity_mappings($class_name);
    if($orm) {
       $result = $orm->deserialise($resultset, $self);
    } else {
        my $meta = eval { $class_name->can('meta') ?  $class_name->meta : undef };
        if ($meta) {
            my $attributes = $meta->all_attributes;
            $result = {map {($_->name, $resultset->{$_->name} )} @$attributes};
        } else {
            $result = {%$resultset};
        }
    }
    if ($class_name) {
        $self->_manage_object($result, $resultset) ;
        $self->_reset_lazy_relation_attributes($result);
    }
    $result;
}


=item changed_column_values

Returns hash ref of fields_values that have been changed.

=cut

sub changed_column_values {
    my ($self, $entity, $object, $fields) = @_;
    my $result;
    if ($self->persitence_mangement) {
        my $persistence_cache = $self->_persistence_cache;
        my $record = $persistence_cache->{$object};
        if ($record) {
            my $lobs  = $entity->lobs;
            my @columns = ($entity->updatable_columns,($lobs  ? values %$lobs : ()));
            for my $column (@columns) {
                my $column_name = $column->name;
                next unless exists $fields->{$column_name};
                if(($fields->{$column_name} || '') ne ($record->{$column_name} || '')) {
                    $result->{$column_name} = $fields->{$column_name};
                    $fields->{$column_name} = $record->{$column_name};
                }
            }
            return $result;
        }
    }
    $fields;
}


=item _manage_object

Creates database state of the object in the persistence cache.
Takes object, resultset as parameters.

=cut

sub _manage_object {
    my ($self, $object, $resultset) = @_;
    my $persistence_cache = $self->_persistence_cache;
    if ($self->persitence_mangement) {
        $persistence_cache->{$object} = {%$resultset};
    }
}



=item add_lazy_fetch_flag

Adds lazy flag.
Takes object and attirubte for lazy retrieval.

=cut

sub add_lazy_fetch_flag {
    my ($self, $object, $attribute) = @_;
    my $fetch_flags = $self->_lazy_fetch_flags;
    my $attributes = $fetch_flags->{$object} ||= {};
    $attributes->{$attribute} = 1;
}


=item has_lazy_fetch_flag

Returns true if passed in object has lazy flag for passed in attribute.

=cut

sub has_lazy_fetch_flag {
    my ($self, $object, $attribute) = @_;
    my $fetch_flags = $self->_lazy_fetch_flag($object);
    $fetch_flags ||= {};
    $fetch_flags->{$attribute};
}


=item _reset_lazy_relation_attributes

=cut

sub _reset_lazy_relation_attributes {
    my ($self, $object)  = @_;
    my $fetch_flags = $self->_lazy_fetch_flags;
    my $attributes = $fetch_flags->{$object} ||= {};
    for my $attribute (keys %$attributes) {
        my $call = "reset_$attribute";
        $object->$call;
    }
    $fetch_flags->{$object} = {};
}


1;

__END__

=back

=head1 SEE ALSO

L<Abstract::Meta::Class>
L<Persistence::ORM>
L<SQL::Entity>
L<SQL::Entity::Condition>

=head1 COPYRIGHT

The SQL::EntityManager module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

See also B<Abstract::Meta::Class>.

=cut
