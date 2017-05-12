package Persistence::ORM;

use strict;
use warnings;

use Abstract::Meta::Class ':all';

use Persistence::Attribute::AMCAdapter;
use Persistence::Relationship ':all';
use Persistence::LOB;
use Persistence::Relationship::ToOne ':all';
use Persistence::Relationship::OneToMany ':all';
use Persistence::Relationship::ManyToMany ':all';


use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use Carp 'confess';
use base 'Exporter';

$VERSION = 0.04;

@EXPORT_OK = qw(entity column trigger to_one one_to_many many_to_many lob LAZY EAGER NONE ALL ON_INSERT ON_UPDATE ON_DELETE);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Persistence::ORM - Object-relational mapping.

=cut  

=head1 SYNOPSIS

    package Employee;

    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';

    entity 'emp';
    column empno => has('$.no') ;
    column ename => has('$.name');


=head1 DESCRIPTION

Object-relational mapping module.

=head1 EXPORT

entity column trigger to_one one_to_many many_to_many 
LAZY EAGER NONE ALL ON_INSERT ON_UPDATE ON_DELETE  by 'all' tag

=head2 ATTRIBUTES

=over

=item class

class name

=cut

has '$.class' => (
    required  => 1,
    on_change => sub {
        my ($self, $attribute, $scope, $value_ref) = @_;
        mapping_meta($$value_ref, $self);
    }
);


=item entity_name

entity name.

=cut

has '$.entity_name' => (required => 1);


=item columns

A map between database column and object attribute

=cut

has '%.columns' => (
    item_accessor    => '_column',
    associated_class => 'Persistence::Attribute',
    index_by         => 'column_name',
    on_validate      => sub {
        my ($self, $attribute, $scope, $value_ref) = @_;
        my $values = $$value_ref;
        if (ref($values) eq 'HASH') {
            my $class = $self->class;
            foreach my $k (keys %$values) {
                my $value =  $values->{$k};
                $values->{$k} = $self->_create_meta_attribute($value, $class, $k)
                    if(ref($value) eq 'HASH')
            }
        }
    }
);


=item lobs

Assocation to LOB objects definition.

=cut

has '%.lobs' => (item_accessor => '_lob', associated_class => 'Persistence::LOB', the_other_end => 'orm');


=item relationships

Assocation to objects relationship definition.

=cut

has '%.relationships' => (item_accessor => '_relationship', associated_class => 'Persistence::Relationship', index_by => 'attribute_name', the_other_end => 'orm');


=item trigger

Defines tigger that will execute on one of the following event
before_insert after_insert before_update after_update before_delete after_delete, on_fetch
Takes event name as first parameter, and callback as secound parameter.

    $entity_manager->trigger(before_insert => sub {
        my ($self) = @_;
        #do stuff
    });

=cut

{

    has '%.triggers' => (
        item_accessor => '_trigger',
        on_change => sub {
            my ($self, $attribute, $scope, $value, $key) = @_;
            if($scope eq 'mutator') {
                my $hash = $$value;
                foreach my $k (keys %$hash) {
                    $self->validate_trigger($k. $hash->{$k});
                }
            } else {
                $self->validate_trigger($key, $$value);
            }
            $self;
        },
    );
}


=item entity_manager

=cut

has '$.entity_manager' => (transistent => 1);


=item mop_attribute_adapter

Name of the class that is an adapter to meta object protocols.
That class have to implements Persistence::Attribute interface.

=cut

has '$.mop_attribute_adapter' => (
    default => 'Persistence::Attribute::AMCAdapter',
);


=item object_creation_method

Returns object creation method.
Allowed values: bless or new

=cut

has '$.object_creation_method' => (
    default => 'bless',
    on_change => sub {
        my ($self, $attribute, $scope, $value) = @_;
        confess "invalid value for " . __PACKAGE__ . "::object_creation_method - allowed values(bless | new)"
            if ($$value ne 'bless' && $$value ne 'new');
        $self;
    }
);


=item _attributes_to_columns

Cache for  the attributes_to_columns method result

=cut

has '$._attributes_to_columns';


=item _columns_to_attributes

Cache for the columns_to_attributes method result

=cut

has '$._columns_to_attributes';


=item _columns_to_storage_attributes

Cache for the columns_to_storage_attributes method result

=cut

has '$._columns_to_storage_attributes';


=back

=head2 METHODS

=over

=item entity

Creates a meta entity class.

=cut

sub entity {
    my ($name, $package) = @_;
    $package ||= caller();
    __PACKAGE__->new(entity_name => $name, class => $package);
}


{
    my %meta;

=item mapping_meta

Returns meta enity class.
Takes optionally package name as parameter.

=cut

    sub mapping_meta {
        my ($package, $value) = @_;
        $package ||= caller();
        $meta{$package} = $value if defined $value;
        $meta{$package};
    }
}

=item column

Adds mapping between column name and related attribute.
Takes column name and attribute object as parameter.

    column ('column1' => has '$.attr1');

=cut

sub column {
    my ($name, $attribute) = @_;
    my $attr_class = 'Persistence::Attribute';
    my $package = caller();
    my $self = mapping_meta($package) or confess "no entity defined for class $package";
    my $attribute_class = $self->mop_attribute_adapter;
    $attribute  =  $attribute_class->new(attribute => $attribute, column_name => $name)
        unless $attribute->isa('Persistence::Attribute');
    $self->add_columns($attribute);
}


=item lob

Adds mapping between lob column name and related attribute.

    lob 'lob_column' => (
        attribute    => has('$.photo'),
        fetch_method => LAZY,
    );


=cut

sub lob {
    my ($name, %args) = @_;
    my $attribute = $args{attribute};
    my $attr_class = 'Persistence::Attribute';
    my $package = caller();
    my $self = mapping_meta($package) or confess "no entity defined for class $package";
    my $attribute_class = $self->mop_attribute_adapter;
    $args{attribute} =  $attribute_class->new(attribute => $attribute, column_name => $name)
      unless $attribute->isa('Persistence::Attribute');
    $self->add_lobs(Persistence::LOB->new(%args));
}


=item covert_to_attributes

Converts passed in data structure to attributes

=cut

sub covert_to_attributes {
    my ($self, $columns) = @_;
    my $class = $self->class;
    my $attribute_class = $self->mop_attribute_adapter;
    my $result = {};
    for my $column(keys %$columns) {
        my $meta_attribute = $columns->{$column};
        my $attribute = $attribute_class->find_attribute($class, $meta_attribute->{name});
        unless ($attribute) {
            $attribute = $self->_create_meta_attribute($meta_attribute, $class, $column);
        } else {
            $attribute = $attribute_class->new(attribute => $attribute, column_name => $column);
        }
        $result->{$column} = $attribute;
    }
    $result;
}


=item covert_to_lob_attributes

Converts passed in data structure to lob attributes

=cut

sub covert_to_lob_attributes {
    my ($self, $lobs) = @_;
    my $class = $self->class;
    my $attribute_class = $self->mop_attribute_adapter;
    my $result = {};
    for my $lob (@$lobs) {
        my $column = $lob->{name};
        my $fetch_method = $lob->{fetch_method};
        my $attribute_name = $lob->{attribute};
        
        my $attribute = $attribute_class->find_attribute($class, $attribute_name);
        unless ($attribute) {
            $attribute = $self->_create_meta_attribute({name => $attribute_name}, $class, $column);
        } else {
            $attribute = $attribute_class->new(attribute => $attribute, column_name => $column);
        }
        $result->{$column} =  Persistence::LOB->new(
            attribute => $attribute,
            ($fetch_method ? (fetch_method => Persistence::LOB->$fetch_method) :())
        );
    }
    $result;
}


=item _create_meta_attribute

Creates a meta attribute

=cut

sub _create_meta_attribute {
    my ($clazz, $meta_attribute, $class, $column_name) = @_;
    my $self = mapping_meta($class) or confess "no entity defined for class $class";
    my $attribute_class = $self->mop_attribute_adapter;
    $attribute_class->create_meta_attribute($meta_attribute, $class, $column_name);
}


=item add_lob_column

Adds lob column.
Takes lob column name, attribute name;

=cut

sub add_lob_column {
    my ($self, $column, $attribute_name, $fetch_method) = @_;
    $self->add_lobs(
        Persistence::LOB->new(
            name         => 'column',
            attribute    => $self->attribute($attribute_name),
            ($fetch_method ? (fetch_method => Persistence::LOB->$fetch_method) :()),
        )
    );
}


=item eager_fetch_lobs

=cut

sub eager_fetch_lobs {
    my ($self) = @_;
    my $lobs = $self->lobs;
    Persistence::LOB->eager_fetch_filter($lobs);
}


=item lazy_fetch_lobs

=cut

sub lazy_fetch_lobs {
    my ($self) = @_;
    my $lobs = $self->lobs;
    Persistence::LOB->lazy_fetch_filter($lobs);
}


=item attribute

=cut

sub attribute {
    my ($self, $attribute_name) = @_;
    my $meta = Abstract::Meta::Class::meta_class($self->class)
        or confess "cant find meta class defintion (Abstract::Meta::Class) for " . $self->class;
    my $attribute = $meta->attribute($attribute_name)
        or confess "cant find attribute ${attribute_name} for class " . $self->class;
    $attribute;
}


=item deserialise

Deserialises resultset to object.

=cut

sub deserialise {
    my ($self, $args, $entity_manager) = @_;
    my $object_creation_method = $self->object_creation_method;
    my $columns_to_attributes = $self->columns_to_attributes;
    my $result = $object_creation_method eq 'bless'
        ? bless ({
        $self->storage_attribute_values($args)
    }, $self->class)
        : $self->class->new(map { $args->{$_} } keys %$columns_to_attributes);

    $entity_manager->initialise_operation($self->entity_name, $result);
    $self->deserialise_eager_relation_attributes($result, $entity_manager);
    $self->deserialise_eager_lob_attributes($result, $entity_manager);
    $entity_manager->complete_operation($self->entity_name);
    $self->run_event('on_fetch', $result);
    $result;
}


=item deserialise_eager_relation_attributes

=cut

sub deserialise_eager_relation_attributes {
    my ($self, $object, $entity_manager) = @_;
    my @relations = Persistence::Relationship->eager_fetch_relations(ref($object));
    foreach my $relation (@relations) {
        $relation->deserialise_attribute($object, $entity_manager, $self);
    }
}


=item deserialise_eager_lob_attributes

=cut

sub deserialise_eager_lob_attributes {
    my ($self, $object, $entity_manager) = @_;
    my @lobs = $self->eager_fetch_lobs;
    foreach my $lob (@lobs) {
        $lob->deserialise_attribute($object, $entity_manager, $self);
    }
}


=item deserialise_lazy_relation_attributes

=cut

sub deserialise_lazy_relation_attributes {
    my ($self, $object, $entity_manager) = @_;
    my @relations = Persistence::Relationship->lazy_fetch_relations(ref($object));
    foreach my $relation (@relations) {
        my $name = $relation->attribute->name;
        $object->$name;
    }
}


=item update_object

=cut

sub update_object {
    my ($self, $object, $column_values, $columns_to_update) = @_;
    my $columns = $self->columns;
    $columns_to_update ||= [keys %$column_values];
    for my $column_name (@$columns_to_update) {
        my $attribute = $columns->{$column_name} or next;
        $attribute->set_value($object, $column_values->{$column_name});
    }
}


=item join_columns_values

Returns join columns values for passed in relation

=cut

sub join_columns_values {
    my ($self, $entity, $relation_name, $object) = @_;
    my $relation = $entity->to_many_relationship($relation_name);
    my $pk_values = $self->column_values($object, $entity->primary_key);
    unless ($entity->has_primary_key_values($pk_values)) {
        my $values = $self->unique_values($object, $entity);
        $pk_values = $self->retrive_primary_key_values($values);
    }
    $entity->_join_columns_values($relation, $pk_values);
}


=item unique_values

Return unique columns values

=cut

sub unique_values {
    my ($self, $object, $entity) = @_;
    my @unique_columns = map { $_->name }  $entity->unique_columns;;
    $self->column_values($object, $entity->primary_key, @unique_columns);
}


=item primary_key_values

Return primary key values

=cut

sub primary_key_values {
    my ($self, $object, $entity) = @_;
    $self->column_values($object, $entity->primary_key);
}


=item trigger

=cut

sub trigger {
    my ($event_name, $code_ref) = @_;
    my $attr_class = 'Abstract::Meta::Attribute';
    my $package = caller();
    my $mapping_meta = mapping_meta($package) or confess "no entity defined for class $package";
    $mapping_meta->_trigger($event_name, $code_ref);
}


=item validate_trigger

Validates triggers types

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


=item run_event

=cut

sub run_event {
    my ($self, $name, @args) = @_;
    my $event = $self->_trigger($name);
    $event->($self, @args) if $event;
}


=item attributes_to_columns

=cut

sub attributes_to_columns {
    my ($self) = @_;
    my $attributes_to_columns = $self->_attributes_to_columns;
    return $attributes_to_columns if $attributes_to_columns;
    my $columns = $self->columns;
    my $result = {};
    foreach my $k (keys %$columns) {
        $result->{$columns->{$k}->name} = $k;
    }
    $self->_attributes_to_columns($result);
    return $result;
}


=item columns_to_attributes

=cut

sub columns_to_attributes {
    my ($self) = @_;
    my $columns_to_attributes = $self->_columns_to_attributes;
    return $columns_to_attributes if $columns_to_attributes;
    my $columns = $self->columns;
    my $result = {};
    foreach my $k (keys %$columns) {
        $result->{$k} = $columns->{$k}->name;
    }
    my $lobs = $self->lobs;
    foreach my $k (keys %$lobs) {
        my $attribute = $lobs->{$k}->attribute;
        $result->{$attribute->column_name} = $attribute->name;
    }

    $self->_columns_to_attributes($result);
    return $result;
}



=item columns_to_storage_attributes

=cut

sub columns_to_storage_attributes {
    my ($self) = @_;
    my $columns_to_storage_attributes = $self->_columns_to_storage_attributes;
    return $columns_to_storage_attributes if $columns_to_storage_attributes;
    my $columns = $self->columns;
    my $result = {};
    foreach my $k (keys %$columns) {
        $result->{$k} = $columns->{$k}->storage_key;
    }
    $self->_columns_to_storage_attributes($result);
    return $result;
}


=item attribute_to_column

Returns column name.
Takes attribute name.

=cut

sub attribute_to_column {
    my ($self, $attribute_name) = @_;
    my $attributes_to_columns = $self->attributes_to_columns;
    $attributes_to_columns->{$attribute_name};
}


=item storage_attribute_values

Transforms column values to the hash that can be blessed as an object.
Takes hash ref of column_values

=cut

sub storage_attribute_values {
    my ($self, $column_values) = @_;
    my $columns = $self->columns;
    my $columns_to_storage_attributes = $self->columns_to_storage_attributes;
    my %result = map {
        ($columns_to_storage_attributes->{$_},  $column_values->{$_})} keys %$columns;
    wantarray ? (%result) : \%result;
}


=item attribute_values

Transforms column values to the object attribute value hash.
Takes hash ref of column_values

=cut

sub attribute_values {
    my ($self,  $column_values) = @_;
    my $columns = $self->columns;
    my $columns_to_attributes = $self->columns_to_attributes;
    my %result = map {
        ($columns_to_attributes->{$_}, $column_values->{$_} )} keys %$columns;
    wantarray ? (%result) : \%result;
}


=item column_values

Transforms objects attributes to column values
Takes object, optionally required columns. (by default all colunms)

=cut

sub column_values {
    my ($self, $obj, @columns) = @_;
    my $columns_to_attributes = $self->columns_to_attributes;
    my $lobs = $self->lobs;
    @columns = (keys %$columns_to_attributes)
        unless @columns;
    my %result = map {
        my $accessor = $columns_to_attributes->{$_};
        ($_, $obj->$accessor)} @columns;
    wantarray ? (%result) : \%result;
}


=item attribute_values_to_column_values

Returns column values.
Takes attribute values hash.

=cut

sub attribute_values_to_column_values {
    my ($self, %args) = @_;
    my $attributes_to_columns = $self->attributes_to_columns;
    my %result;
    for my $k(keys %args) {
        my $column = $attributes_to_columns->{$k} || $k;
        $result{$column} = $args{$k};
    }
    (%result);
}



1;

__END__

=back

=head1 SEE ALSO

L<Abstract::Meta::Class>
L<Persistence::Entity::Manager>
L<SQL::Entity>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity::ORM module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
