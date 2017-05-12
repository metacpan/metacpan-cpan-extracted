package Persistence::Relationship::ManyToMany;

use strict;
use warnings;

use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use base qw (Exporter Persistence::Relationship);
use Carp 'confess';

$VERSION = 0.01;

@EXPORT_OK = qw(many_to_many);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Persistence::Relationship::ManyToMany - Many to many relationship

=head1 CLASS HIERARCHY

 Persistence::Relationship
    |
    +----Persistence::Relationship::ManyToMany


=head1 SYNOPSIS

    use Persistence::Relationship::ManyToMany ':all';

#.... entities definition

    my $entity_manager = Persistence::Entity::Manager->new(name => 'my_manager', connection_name => 'test');

    my $emp_project_entity = Persistence::Entity->new(
        name    => 'emp_project',
        alias   => 'ep',
        primary_key => ['projno', 'empno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'empno'),
            sql_column(name => 'leader'),
        ],
    );

    my $emp_entity = Persistence::Entity->new(
        name    => 'emp',
        alias   => 'ep',
        primary_key => ['empno'],
        columns => [
            sql_column(name => 'empno'),
            sql_column(name => 'ename', unique => 1),
            sql_column(name => 'job'),
            sql_column(name => 'deptno'),
        ],
        value_generators => {empno => 'emp_gen'}, 
        to_many_relationships => [
            sql_relationship(target_entity => $emp_project_entity,
            join_columns => ['empno'], order_by => 'empno, projno')
        ]
    );

    my $project_entity = Persistence::Entity->new(
        name    => 'project',
        alias   => 'pr',
        primary_key => ['projno'],
        columns => [
            sql_column(name => 'projno'),
            sql_column(name => 'name', unique => 1),
        ],
        value_generators => {projno => 'project_gen'},
        to_many_relationships => [
            sql_relationship(target_entity => $emp_project_entity,
            join_columns => ['projno'], order_by => 'projno, empno')
        ]
    );

    $entity_manager->add_entities($emp_project_entity, $emp_entity, $project_entity);

    # object mapping

    package Project;

    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'project';
    column projno => has('$.id');
    column name => has('$.name');

    package Employee;

    use Abstract::Meta::Class ':all';
    use Persistence::Entity ':all';
    use Persistence::ORM ':all';

    entity 'emp';
    column empno=> has('$.id');
    column ename => has('$.name');
    column job => has '$.job';

    many_to_many 'project' => (
        attribute        => has('%.projects' => (associated_class => 'Project'), index_by => 'name'),
        join_entity_name => 'emp_project',
        fetch_method     => LAZY,
        cascade          => ALL,
    );

=head1 DESCRIPTION

Represents many to many relationship.
Supports eager, lazy fetch, cascading operation (inert/update/delete).

=head1 EXPORT

many_to_many by ':all' tag.

=head2 ATTRIBUTES

=over

=item join_entity_name

Join entity name.

=cut

has '$.join_entity_name' => (required => 1);

=back

=head2 METHODS

=over

=item many_to_many

=cut


sub many_to_many {
    my $package = caller();
    __PACKAGE__->add_relationship($package, @_);
}


=item deserialise_attribute

Deserialises relation attribute

=cut

sub deserialise_attribute {
    my ($self, $object, $entity_manager, $orm) = @_;
    my $entity = $entity_manager->entity($orm->entity_name);
    my $target_entity = $entity_manager->entity($self->name)
        or confess "cant find entity" . $self->name;
    my $join_entity = $entity_manager->entity($self->join_entity_name);
    my $relation = $entity->to_many_relationship($self->join_entity_name);
    my %fields_values = $orm->column_values($object);
    my %join_values = $entity->_join_columns_values($relation, \%fields_values);
    return unless(map {$join_values{$_} ? ($_) : () }  keys %join_values);
    my $condition = SQL::Entity::Condition->struct_to_condition(map {$join_entity->column($_), $join_values{$_}} keys %join_values);
    my $attribute = $self->attribute;
    my @rows =  $target_entity->find($attribute->associated_class,  $condition);
    if (@rows) {
        my $mutator = $attribute->mutator;
        $object->$mutator(\@rows);
    }
}


=item insert

Inserts relationship data.

=cut

sub insert {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    $self->_associate_relationship_data($orm, $entity, $unique_values, $object, 'insert');
}


=item merge

Merges relationship data.

=cut

sub merge {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    $self->_associate_relationship_data($orm, $entity, $unique_values, $object, 'merge');
}


=item delete

Deletes many to many association.

=cut

sub delete {
    my ($self, $orm, $entity, $unique_values, $object) = @_;
    my $join_entity_name = $self->join_entity_name;
    my $attribute = $self->attribute;
    my $values = $self->values($object);
    my $entity_manager = $entity->entity_manager;
    my $target_entity = $entity_manager->entity($self->name);
    my $reflective_orm =  $entity_manager->find_entity_mappings($attribute->associated_class);
    my $join_values = $orm->join_columns_values($entity, $join_entity_name, $object);
    my $join_entity = $entity_manager->entity($join_entity_name);
    foreach my $association_object (@$values) {
        $join_entity->delete(
            %$join_values,
            $reflective_orm->join_columns_values($target_entity, $join_entity_name, $association_object)
        );
    }
}


=item _associate_relationship_data

=cut

sub _associate_relationship_data {
    my ($self, $orm, $entity, $unique_values, $object, $operation) = @_;
    my $join_entity_name = $self->join_entity_name;
    my $attribute = $self->attribute;
    my $values = $self->values($object);
    my $entity_manager = $entity->entity_manager;
    my $target_entity = $entity_manager->entity($self->name);
    my $reflective_orm =  $entity_manager->find_entity_mappings($attribute->associated_class);
    my $join_values = $orm->join_columns_values($entity, $join_entity_name, $object);
    
    my $reflective_relation = $target_entity->to_many_relationship($join_entity_name);
    my $join_entity = $entity_manager->entity($join_entity_name);
    
    foreach my $association_object (@$values) {
        $entity_manager->merge($association_object);
        $join_entity->$operation(
            %$join_values,
            $reflective_orm->join_columns_values($target_entity, $join_entity_name, $association_object)
        );
    }
}


1;    

__END__

=back

=head1 SEE ALSO

L<Persistence::Relationship>
L<Persistence::Entity>
L<Persistence::Entity::Manager>
L<Persistence::ORM>

=head1 COPYRIGHT AND LICENSE

The Persistence::ManyToManyRelationship module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
