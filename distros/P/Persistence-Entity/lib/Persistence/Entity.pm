package Persistence::Entity;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use base qw(Exporter SQL::Entity);
use Carp 'confess';

use SQL::Entity ':all';

@EXPORT_OK = qw(
    sql_relationship
    sql_column
    sql_lob
    sql_index
    sql_cond
    sql_and
    sql_or
);


%EXPORT_TAGS = (all => \@EXPORT_OK);

$VERSION = 0.07;

=head1 NAME

Persistence::Entity - Persistence API for perl classes.

=cut

=head1 CLASS HIERARCHY

 SQL::Entity::Table
    |
    +----SQL::Entity
            |
            +----Persistence::Entity


=head1 SYNOPSIS

    use Persistence::Entity ':all';

    my $membership_entity = Persistence::Entity->new(
        name    => 'wsus_user_service',
        alias   => 'us',
        primary_key => ['user_id', 'service_id'],
        columns => [
            sql_column(name => 'user_id'),
            sql_column(name => 'service_id'),
            sql_column(name => 'agreement_flag')
        ],
    );

    my $user_entity = Persistence::Entity->new(
        name    => 'wsus_user',
        alias   => 'ur',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'username'),
            sql_column(name => 'password'),
            sql_column(name => 'email'),
        ],
        to_many_relationships => [sql_relationship(target_entity => $membership_entity, join_columns => ['user_id'])]
    );

   $entity_manager->add_entities($membership_entity, $user_entity);

LOB's support

    my $photo_entity = Persistence::Entity->new(
        name    => 'photo',
        alias   => 'ph',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'name', unique => 1),
        ],
        lobs => [
            sql_lob(name => 'blob_content', size_column => 'doc_size'),
        ]
    );


=head1 DESCRIPTION

This class represents database entity.

=head2 EXPORT

  sql_relationship
  sql_column
  sql_lob
  sql_index
  sql_cond
  sql_and
  sql_or by ':all' tag

=head2 ATTRIBUTES

=over

=item trigger

Defines tigger that will execute on one of the following event
before_insert after_insert before_update after_update before_delete after_delete, on_fetch
Takes event name as first parameter, and callback as secound parameter.


    $entity->trigger(before_insert => sub {
        my ($self) = @_;
        #do stuff
    });


=cut

{

    has '%.triggers' => (
        transistent   => 1,
        item_accessor => 'trigger',
        on_change => sub {
            my ($self, $attribute, $scope, $value, $key) = @_;
            if($scope eq 'mutator') {
                my $hash = $$value;
                foreach my $k (keys %$hash) {
                    $self->validate_trigger($k, $hash->{$k});
                }
            } else {
                $self->validate_trigger($key. $$value);
            }
            $self;
        },
    );
}


=item entity_manager

=cut

has '$.entity_manager' => (
    transistent      => 1,
    associated_class => 'Persistence::Entity::Manager',
    the_other_end    => 'entities',
);


=item value_generators

Hash that contains pair of column and its value generator.

=cut

has '%.value_generators' => (
    item_accessor => 'value_generator'
);



=item filter_condition_values

Hash ref that contains filter values, that values will be used as condition values

=cut

has '%.filter_condition_values';


=item dml_filter_values

Hash ref that contains columns values that will be added to all dml operations.

=cut

has '%.dml_filter_values';


=back

=head2 METHODS

=over

=item find

Returns list of objects or resultsets.
Takes class name to which resultset will be casted, (if class name is undef then hash ref will be return instead),
list of names parameters that will be used as condition or condition object.
Condition object always should use entity column.


    my $entity = $entity_manager->entity('emp');
    my ($emp) = $entity->find('Employee', ename => 'adrian');
    or
    my @emp = $entity->find('Employee', sql_cond('ename', 'LIKE', 'a%'));
    #array of Employee objects.


=cut

sub find {
    my ($self, $class_name, @args) = (@_);
    my $entity_manager = $self->entity_manager;
    my $condition = $entity_manager->condition_converter($class_name, @args, $self->filter_condition_values);
    my ($sql, $bind_variables) = $self->query(undef, $condition);
    $self->_execute_query($sql, $bind_variables, $class_name);
}


=item search

Returns list of objects or resultsets.
Takes array ref of requested column to projection, class name to which resultset will be casted,
(if class name is undef then hash ref will be return instead),
list of names parameters that will be used as condition or condition object.
Condition object always should use entity column.


    my $entity = $entity_manager->entity('emp');
    my ($emp) = $entity->find('Employee', ename => 'adrian');
    or
    my @emp = $entity->find('Employee', sql_cond('ename', 'LIKE', 'a%'));
    #array of Employee objects.


=cut

sub search {
    my ($self, $requested_columns, $class_name,  @args) = @_;
    my $entity_manager = $self->entity_manager;
    my $condition = $entity_manager->condition_converter($class_name, @args, $self->filter_condition_values);
    my ($sql, $bind_variables) = $self->query($requested_columns, $condition);
    $self->_execute_query($sql, $bind_variables, $class_name);
}


=item lock

Returns and locks list and of objects or resultsets.
Takes entity name, class name to which resultset will be casted, (if class name is undef then hash ref will be return instead),
list of names parameters that will be used as condition or condition object.
Condition object always should use entity column.
Locking is forced by SELECT ... FOR UPDATE clause


    my $entity = $entity_manager->entity('emp');
    my ($emp) = $entity->lock('Employee', ename => 'adrian');
    or
    my @emp = $entity->lock('Employee', sql_cond('ename', 'LIKE', 'a%'));
    #array of Employee objects.
    or 
    my @emp = $entity->lock(undef, sql_cond('ename', 'LIKE', 'a%'));
    #array of resultset (hash ref)


=cut

sub lock {
    my ($self, $class_name, @args) = (@_);
    my $entity_manager = $self->entity_manager;
    my $condition = $entity_manager->condition_converter($class_name, @args, $self->filter_condition_values);
    my ($sql, $bind_variables) = $self->SUPER::lock(undef, $condition);
    $self->_execute_query($sql, $bind_variables, $class_name);
}


=item relationship_query

Return rows for relationship.
Takes relationship_name, class_name, target_class_name, condition arguments as parameters.


     $user_entity->add_to_many_relationships(sql_relationship(target_entity => $membership_entity, join_columns => ['user_id']));
    my $entity_manager = Persistence::Entity::Manager->new(connection_name => 'my_connection');
    $entity_manager->add_entities($membership_entity, $user_entity);
    my @membership = $user_entity->relationship_query('wsus_user_service', undef => undef, username => 'test');
    # returns array of hash refs.
    or 
    my @membership = $user_entity->relationship_query('wsus_user_service', 'User' => 'ServiceMembership', username => 'test');
    # returns array of ServiceMembership objects


=cut

sub relationship_query {
    my ($self, $relation_name, $class_name, $target_class_name, @args) = @_;
    my $relationship = $self->relationship($relation_name);
    my $target_entity = $relationship->target_entity;
    my $condition = $self->entity_manager->condition_converter($class_name, @args);
    my ($sql, $bind_variables) = $self->SUPER::relationship_query($relation_name, $condition);
    $self->_execute_query($sql, $bind_variables, $target_class_name);
}


=item insert

Inserts the entity row
Takes list of field values.

    $entity->insert(col1 => 'val1', col2 => 'val2');


=cut

sub insert {
    my ($self, %fields_values) = @_;
    $self->_autogenerated_values(\%fields_values);
    my ($sql, $bind_variables) = $self->SUPER::insert(%fields_values, $self->dml_filter_values);
    $self->_execute_statement($sql, $bind_variables, "insert", \%fields_values);
    $self->_update_lobs(\%fields_values);
    \%fields_values;
}


=item relationship_insert

Inserts the relation rows.
Takes relation name, dataset that represents  the entity row, array ref where item
can be either object or hash ref that represents row to be asssociated .

    $user_entity->relationship_insert('wsus_user_service', {username => 'test'} , {service_id => 1}, {service_id => 9});
    #or
    my $user = User->new(...);
    my $membership1 = Membership->new(...);
    my $membership2 = Membership->new(...);
    $user_entity->relationship_insert('wsus_user_service', $user, $membership1, $membership2);

=cut

sub relationship_insert {
    my ($self, $relation_name, $dataset, @to_insert) = @_;
    my $operation = $self->to_one_relationship($relation_name)
      ? '_to_one_relationship_merge'
      : '_to_many_relationship_insert';
    $self->$operation($relation_name, $dataset, @to_insert);
}


=item update

Updates the entity row.
Takes field values as hash ref, condition values as hash reference.


    $entity->update({col1 => 'val1', col2 => 'val2'}, {the_rowid => 'xx'});

    my $lob = _load_file('t/bin/data1.bin');
   $photo_entity->insert(id => "1", name => "photo1", blob_content => $lob);


=cut

sub update {
    my ($self, $fields_values, $condition_values) = @_;
    my ($sql, $bind_variables) = $self->SUPER::update({%$fields_values, $self->dml_filter_values}, $condition_values);
    $self->_execute_statement($sql, $bind_variables, "update", $fields_values) if $sql;
    $self->_update_lobs($fields_values, $condition_values);
}


=item merge

Merges the entity row.
Takes field values to merge as named parameteres,


    $entity->merge(col1 => 'val1', col2 => 'val2', the_rowid => '0xAAFF');


=cut

sub merge {
    my ($self, %fields_values) = @_;
    my %condition_values = $self->unique_condition_values(\%fields_values, 1);
    my (@result) = $self->find(undef, %condition_values);
    unless(@result) {
        $self->insert(%fields_values);
    } else {
        my %condition_values = $self->unique_condition_values(\%fields_values, 1);
        $self->update(\%fields_values, \%condition_values);
    }
}


=item relationship_merge

Merges the relation rows.
Takes relation name, dataset that represents  the entity row, list of
either object or hash ref that represent asssociated row to merge.


    $user_entity->relationship_merge('wsus_user_service',
        {username => 'test'} ,
        {service_id => 1, agreement_flag => 1}, {service_id => 5, agreement_flag => 1}
    );


=cut

sub relationship_merge {
    my ($self, $relation_name, $dataset, @to_merge) = @_;
    my $operation = $self->to_one_relationship($relation_name)
      ? '_to_one_relationship_merge'
      : '_to_many_relationship_merge';
    $self->$operation($relation_name, $dataset, @to_merge);
}


=item delete

Delete entity row.
Takes list of condition values.


    $entity->delete(the_rowid => 'xx');


=cut

sub delete {
    my ($self, %condition_values) = @_;
    my ($sql, $bind_variables) = $self->SUPER::delete(%condition_values, $self->dml_filter_values);
    $self->_execute_statement($sql, $bind_variables, "delete", \%condition_values);
}


=item relationship_delete

Deletes associated rows.
Takes relation name, dataset that represents  the entity row, list of 
either associated object or hash ref that represent asssociated row.


    $user_entity->relationship_insert('wsus_user_service', {username => 'test'} , {service_id => 1}, {service_id => 9});
    $user_entity->relationship_insert('wsus_user_service', $user, $membership1, $membership1);


=cut

sub relationship_delete {
    my ($self, $relation_name, $dataset, @to_delete) = @_;
    my $operation = $self->to_one_relationship($relation_name)
      ? '_to_one_relationship_delete'
      : '_to_many_relationship_delete';
    $self->$operation($relation_name, $dataset, @to_delete);
}


=item primary_key_values

Returns primary key values.
Takes field values that will be used as condition to retrive primary key values
in case they are not contain primary key values.

=cut

sub primary_key_values {
    my ($self, $dataset, $validate) = @_;
    my $result;
    my @primary_key = $self->primary_key;
    if(! $self->has_primary_key_values($dataset)) {
        #only if has pk or unique values
        my $unique_values = $self->unique_condition_values($dataset);
        $result = $self->retrive_primary_key_values($unique_values) if (%$unique_values);
        if ($result) {
            $result = {map { $_ => $result->{$_}} @primary_key};
        }

    } else {
        $result = {map { $_ => $dataset->{$_}} @primary_key};
    }
    confess "cant retrive " .$self->name . "'s primary key values ["
    . join(",", map { $_ => ($dataset->{$_} || '') } keys %$dataset) . "]"
         if ! $result && $validate;
    $result;
}


=item has_primary_key_values

Returns true if passed in dataset contains primary key values.

=cut

sub has_primary_key_values {
    my ($self, $dataset) = @_;
    $dataset ||= {};
    my @primary_key = $self->primary_key;
    for (@primary_key) {
        return if (! exists($dataset->{$_}) || ! defined $dataset->{$_});
    }
    $self;
}


=item fetch_lob

Fetchs LOBs value.
Takes lob column name, condition values.

    my $blob = $photo_entity->fetch_lob('blob_content', {id => 10});

=cut

sub fetch_lob {
    my ($self, $column,  $condition_values) = @_;
    my $entity_manager = $self->entity_manager;
    if(ref($condition_values) ne 'HASH') {
        my $orm = $entity_manager->find_entity_mappings($condition_values);
    }
    my $pk_values = $self->primary_key_values($condition_values, 1);
    my $lob = $self->lob($column);
    my $connection = $self->entity_manager->connection;
    $connection->fetch_lob($self->name, $lob->name, $pk_values, $lob->size_column);

}

=back

=head2 PRIVATE METHODS

=over

=item is_refresh_required

Returns true if refreshis required

=cut

sub is_refresh_required {
    my ($self, $fields_values) = @_;
    my $has_primary_key_flag  = $self->has_primary_key_values($fields_values, 1);
    ! $has_primary_key_flag ;
}


=item run_event

Executes passed in even.
Takes event name, event parameters.

=cut

sub run_event {
    my ($self, $name, @args) = @_;
    my $event = $self->trigger($name);
    $event->(@args) if $event;
}


=item validate_trigger

Validates triggers types.
The following trigger types are supported: before_insert, after_insert, before_update, after_update, before_delete, after_delete, on_fetch.

=cut

{
    my @triggers = qw(before_insert after_insert before_update after_update before_delete after_delete on_fetch);
    sub validate_trigger {
        my ($self, $name, $value) = @_;
        confess "invalid trigger name: $name , must be one of " . join(",", @triggers)
            unless (grep {$name eq $_} @triggers);
        confess "secound parameter must be a callback"
            unless ref($value) eq 'CODE';
    }
}


=item _update_lobs

Updates LOB value.

    $entity->_update_lobs({name => "photo1", blob_content => $bin_data}, {id => 1,});

=cut

sub _update_lobs {
    my ($self, $fields_values, $condition_values) = @_;
    $condition_values ||= $fields_values;
    my $lobs = $self->_extract_lob_values($fields_values);
    return if (! $lobs || ! %$lobs);
    my $connection = $self->entity_manager->connection;
    my $primary_key_values = $self->primary_key_values($condition_values, 1);
    for my $k (keys %$lobs) {
        my $lob = $self->lob($k);
        $connection->update_lob($self->name, $lob->name, $lobs->{$k}, $primary_key_values, $lob->size_column);
    }
}


=item _extract_lob_values

=cut

sub _extract_lob_values {
    my ($self, $fields_values) = @_;
    my $lobs = $self->lobs;
    my $result = {map {($_ => $fields_values->{$_})} keys %$lobs};
    wantarray ? @$result : $result;
}


=item _autogenerated_values

Adds autogenerated values. Takes hash ref to field values

=cut

sub _autogenerated_values {
    my ($self, $field_values) = @_;
    my $value_generators = $self->value_generators;
    for my $k(keys %$value_generators) {
        next if defined $field_values->{$k};
        my $generator = Persistence::ValueGenerator->generator($value_generators->{$k});
        $field_values->{$k} = $generator->nextval();
    }
}


=item _to_many_relationship_insert

Insert data to many relationship.
Takes relationship name, hashref of the fileds values for the entity,
list of hash ref that contians fileds values of the entities to associate.

=cut

sub _to_many_relationship_insert {
    my ($self, $relation_name, $dataset, @to_insert) = @_;
    my $entity_manager = $self->entity_manager;
    my $relation = $self->relationship($relation_name);
    my %join_values = $self->_join_columns_values($relation, $dataset);
    my $target_entity = $relation->target_entity;
    for my $item (@to_insert) {
        my $orm = $entity_manager->find_entity_mappings($item);
        if ($orm) {
            $orm->update_object($item, \%join_values);
            $entity_manager->insert($item, \%join_values);
            
        } else {
            $target_entity->insert(%$item, %join_values);
        }
    }
}


=item _to_one_relationship_merge

Merges data to one relationship.
Takes relationship name, hashref of the fileds values for the entity,
list of hash ref that contians values fileds of the entities to associate.

=cut

sub _to_one_relationship_merge {
    my ($self, $relation_name, $dataset, $to_merge) = @_;
    my $entity_manager = $self->entity_manager;
    my $relation = $self->relationship($relation_name);
    my $target_entity = $relation->target_entity;
    my $column_values = {};
    if($to_merge) {
        my $orm = $entity_manager->find_entity_mappings($to_merge);
        if ($orm) {
            $entity_manager->merge($to_merge);
        } else {
            $target_entity->merge(%$to_merge);
        }
        $column_values = $orm->unique_values($to_merge, $target_entity);
    }
    my $join_values = $self->_join_columns_values($relation, $column_values);
    $self->_merge_datasets($join_values, $dataset);
}



=item _merge_datasets

Mergers tow passed in dataset.
Takes source hash_ref, target hash_ref.

=cut

sub _merge_datasets {
    my ($self, $source_dataset, $target_dataset) = @_;
    $target_dataset->{$_} = defined $source_dataset->{$_} ? $source_dataset->{$_} : $target_dataset->{$_}
        for keys %$source_dataset;
}


=item _join_columns_values

Returns join columns values for passed in relation

=cut

sub _join_columns_values {
    my ($self, $relation, $dataset, $validation) = @_;
    my $entity = $self->to_one_relationship($relation->name) ? $relation->target_entity : $self;
    my @join_columns = $relation->join_columns;
    my @primary_key = $entity->primary_key;
    my $primary_key_values = $entity->primary_key_values($dataset, $validation);
    my %result;
    for my $i (0 .. $#primary_key) {
        $result{$join_columns[$i]} = $primary_key_values->{$primary_key[$i]};
    }
    wantarray ? (%result) : \%result;
}


=item _to_many_relationship_merge

Marges to many relationship rows (insert/update).
Takes relationship name, hashref of the fileds values for the entity,
list of hash ref that contians values fileds of the entities to merge.

=cut

sub _to_many_relationship_merge {
    my ($self, $relation_name, $dataset, @to_merge) = @_;
    my $entity_manager = $self->entity_manager;
    my $relation = $self->relationship($relation_name);
    my %join_values = $self->_join_columns_values($relation, $dataset, 1);
    my @existing_dataset = $self->relationship_query($relation_name, undef => undef, %join_values);
    my $target_entity = $relation->target_entity;
    my %rows_pk;
    my $column_values;
    for my $item (@to_merge) {
        my $orm = $entity_manager->find_entity_mappings($item);
        if ($orm) {
            $orm->update_object($item, \%join_values);
            $entity_manager->merge($item, \%join_values);
            $column_values = $orm->unique_values($item, $target_entity);
        } else {
            $column_values = {%$item, %join_values};
            $target_entity->merge(%$item, %join_values);
        }
        
        my $pk_values = $target_entity->primary_key_values($column_values, 1);
        $rows_pk{join("-", %$pk_values)} = 1;
    }
    
    #deletes all rows that are not part of the assocaition.
    for my $record (@existing_dataset) {
        my $pk_values = $target_entity->primary_key_values($record, 1);
        next if $rows_pk{join("-", %$pk_values)};
        $target_entity->delete(%$pk_values);
    }
}


=item _to_many_relationship_delete

Deletes to many relationship association.
Takes relationship name, hashref of the fileds values for the entity,
list of hash ref that contians values fileds of the entities to delete.

=cut

sub _to_many_relationship_delete {
    my ($self, $relation_name, $dataset, @to_delete) = @_;
    my $entity_manager = $self->entity_manager;
    my $relation = $self->relationship($relation_name);
    my %join_values = $self->_join_columns_values($relation, $dataset, 1);
    my $target_entity = $relation->target_entity;
    for my $item (@to_delete) {
        my $orm = $entity_manager->find_entity_mappings($item);
        if($orm) {
            $orm->update_object($item, \%join_values);
            $entity_manager->delete($item);
        } else {
            $target_entity->delete($target_entity->unique_condition_values({%$item, %join_values}, 1));
        }
    }
}


=item _to_one_relationship_delete

Deletes to one relationship association.
Takes relationship name, hashref of the fileds values for the entity,
list of hash ref that contians values fileds of the entities to delete.

=cut

sub _to_one_relationship_delete {
    my ($self, $relation_name, $dataset, $to_delete) = @_;
    my $entity_manager = $self->entity_manager;
    my $relation = $self->relationship($relation_name);
    my $target_entity = $relation->target_entity;
    my $column_values = {};
    if($to_delete) {
        my $orm = $entity_manager->find_entity_mappings($to_delete);
        if ($orm) {
            $entity_manager->delete($to_delete);
        } else {
            $target_entity->delete(%$to_delete);
        }
    }
}


=item retrive_primary_key_values

Retrieves primary key values.
Takes hash ref of the entity field values.

=cut

sub retrive_primary_key_values {
    my ($self, $dataset) = @_;
    my $primary_key = $self->primary_key or confess "primary key must be defined for entity " . $self->id;
    my @result = $self->find($primary_key, %$dataset);
    $result[0];
}


=item _execute_statement

Executes passed in sql statements with all callback defined by decorators (triggers)
Takes sql, array ref of the bind varaibles,r event name, event parameters.

=cut

sub _execute_statement {
    my ($self, $sql, $bind_variables, $event_name, @event_parameters) = @_;
    my $connection = $self->entity_manager->connection;
    $self->run_event("before_${event_name}", @event_parameters);
    $connection->execute_statement($sql, @$bind_variables);
    $self->run_event("after_${event_name}", @event_parameters);
}


=item _execute_query

Executes query.
Takes sql, array ref of the bind varaibles, optionally class name.

=cut

sub _execute_query {
    my ($self, $sql, $bind_variables, $class_name) = @_;
    my $entity_manager = $self->entity_manager;
    my $connection = $entity_manager->connection;
    my @result;
    my $cursor = $connection->query_cursor(sql => $sql);
    my %result_set;
    $cursor->execute($bind_variables, \%result_set);
    while ($cursor->fetch()) {
        my $result = ($class_name ? $entity_manager->_deseralize_object($class_name, \%result_set) : {%result_set});
        $self->run_event('on_fetch', $result);
        push @result, $result;
    }
    @result;
}


1;

__END__

=back

=head1 SEE ALSO

L<SQL::Entity>

=head1 COPYRIGHT AND LICENSE

The Persistence::Entity module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
